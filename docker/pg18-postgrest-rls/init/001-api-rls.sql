DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'web_anon') THEN
    CREATE ROLE web_anon NOLOGIN;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticated') THEN
    CREATE ROLE authenticated NOLOGIN;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticator') THEN
    CREATE ROLE authenticator LOGIN PASSWORD 'local_pg18_rls_authenticator_only';
  ELSE
    ALTER ROLE authenticator LOGIN PASSWORD 'local_pg18_rls_authenticator_only';
  END IF;
END
$$;

GRANT web_anon TO authenticator;
GRANT authenticated TO authenticator;

CREATE SCHEMA IF NOT EXISTS api;
CREATE SCHEMA IF NOT EXISTS private;

GRANT USAGE ON SCHEMA api TO web_anon, authenticated;
GRANT USAGE ON SCHEMA private TO authenticated;

CREATE TABLE IF NOT EXISTS private.account_profiles (
  app_user_id text PRIMARY KEY,
  display_name text NOT NULL,
  plan text NOT NULL,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb
);

INSERT INTO private.account_profiles (app_user_id, display_name, plan, metadata)
VALUES
  ('user_karval_demo', 'Karval Demo', 'rc1', jsonb_build_object('source', 'pg18-rls-proof')),
  ('user_other_demo', 'Other Demo', 'blocked', jsonb_build_object('source', 'pg18-rls-proof'))
ON CONFLICT (app_user_id) DO UPDATE
SET display_name = EXCLUDED.display_name,
    plan = EXCLUDED.plan,
    metadata = EXCLUDED.metadata;

ALTER TABLE private.account_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.account_profiles FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS account_profiles_by_jwt_user ON private.account_profiles;
CREATE POLICY account_profiles_by_jwt_user
ON private.account_profiles
FOR SELECT
TO authenticated
USING (
  app_user_id = COALESCE(
    nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'app_user_id',
    ''
  )
);

GRANT SELECT ON private.account_profiles TO authenticated;

CREATE OR REPLACE FUNCTION api.current_profile()
RETURNS jsonb
LANGUAGE sql
STABLE
SECURITY INVOKER
AS $$
  SELECT jsonb_build_object(
    'app_user_id', app_user_id,
    'display_name', display_name,
    'plan', plan,
    'metadata', metadata,
    'postgres_version', current_setting('server_version'),
    'jwt_app_user_id', nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'app_user_id',
    'role', current_user
  )
  FROM private.account_profiles
  LIMIT 1;
$$;

GRANT EXECUTE ON FUNCTION api.current_profile() TO authenticated;
REVOKE ALL ON FUNCTION api.current_profile() FROM web_anon;

CREATE OR REPLACE FUNCTION api.hello()
RETURNS jsonb
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT jsonb_build_object(
    'message', 'hello from durable pg18 postgrest rls stack',
    'gateway', 'postgrest',
    'client', 'web',
    'postgres_version', current_setting('server_version')
  );
$$;
GRANT EXECUTE ON FUNCTION api.hello() TO web_anon, authenticated;


-- Realtime v2: Postgres-first event outbox + LISTEN/NOTIFY bridge.
-- PostgreSQL remains the durable source of truth for replay/cursor, scope/topic
-- authorization, and ACK state. The Node bridge is intentionally transport-only.
-- Fanout note: private.event_outbox is shaped so a future worker can consume rows
-- and publish to Redis/NATS/Kafka without changing producers or replay semantics.
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'realtime_bridge') THEN
    CREATE ROLE realtime_bridge LOGIN PASSWORD 'local_pg18_realtime_bridge_only';
  ELSE
    ALTER ROLE realtime_bridge LOGIN PASSWORD 'local_pg18_realtime_bridge_only';
  END IF;
END
$$;

CREATE TABLE IF NOT EXISTS private.event_outbox (
  id bigserial PRIMARY KEY,
  app_user_id text NOT NULL,
  scope_type text NOT NULL DEFAULT 'user',
  scope_id text,
  topic text NOT NULL,
  payload jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE private.event_outbox
  ADD COLUMN IF NOT EXISTS scope_type text NOT NULL DEFAULT 'user',
  ADD COLUMN IF NOT EXISTS scope_id text;

UPDATE private.event_outbox
SET scope_id = app_user_id
WHERE scope_id IS NULL;

ALTER TABLE private.event_outbox
  ALTER COLUMN scope_id SET NOT NULL;

COMMENT ON TABLE private.event_outbox IS 'Durable realtime v2 event log. PostgreSQL is source of truth; Redis/NATS fanout can be added as an async consumer later.';
COMMENT ON COLUMN private.event_outbox.scope_type IS 'Authorization/fanout namespace type, e.g. user, org, project.';
COMMENT ON COLUMN private.event_outbox.scope_id IS 'Authorization/fanout namespace id. Default proof uses app_user_id for user scope.';
COMMENT ON COLUMN private.event_outbox.topic IS 'Application topic within a scope. Bridge may subscribe to exact topic or NULL wildcard.';

CREATE INDEX IF NOT EXISTS event_outbox_scope_replay_idx
ON private.event_outbox (scope_type, scope_id, topic, id);

CREATE INDEX IF NOT EXISTS event_outbox_user_replay_idx
ON private.event_outbox (app_user_id, id);

CREATE TABLE IF NOT EXISTS private.realtime_event_acks (
  app_user_id text NOT NULL,
  event_id bigint NOT NULL REFERENCES private.event_outbox(id) ON DELETE CASCADE,
  acked_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (app_user_id, event_id)
);

COMMENT ON TABLE private.realtime_event_acks IS 'Durable client ACK state for replay/retry bookkeeping. One row per app_user_id/event_id.';

CREATE INDEX IF NOT EXISTS realtime_event_acks_event_idx
ON private.realtime_event_acks (event_id);

ALTER TABLE private.event_outbox ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.event_outbox FORCE ROW LEVEL SECURITY;
ALTER TABLE private.realtime_event_acks ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.realtime_event_acks FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS event_outbox_by_jwt_user ON private.event_outbox;
CREATE POLICY event_outbox_by_jwt_user
ON private.event_outbox
FOR SELECT
TO authenticated
USING (
  scope_type = 'user'
  AND scope_id = COALESCE(
    nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'app_user_id',
    ''
  )
);

DROP POLICY IF EXISTS event_outbox_insert_by_jwt_user ON private.event_outbox;
CREATE POLICY event_outbox_insert_by_jwt_user
ON private.event_outbox
FOR INSERT
TO authenticated
WITH CHECK (
  app_user_id = COALESCE(
    nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'app_user_id',
    ''
  )
  AND scope_type = 'user'
  AND scope_id = app_user_id
);

DROP POLICY IF EXISTS realtime_event_acks_by_jwt_user ON private.realtime_event_acks;
CREATE POLICY realtime_event_acks_by_jwt_user
ON private.realtime_event_acks
FOR SELECT
TO authenticated
USING (
  app_user_id = COALESCE(
    nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'app_user_id',
    ''
  )
);

GRANT SELECT, INSERT ON private.event_outbox TO authenticated;
GRANT SELECT ON private.realtime_event_acks TO authenticated;
GRANT USAGE, SELECT ON SEQUENCE private.event_outbox_id_seq TO authenticated;
GRANT USAGE ON SCHEMA private TO realtime_bridge;
GRANT SELECT ON private.event_outbox TO realtime_bridge;
GRANT SELECT, INSERT, UPDATE ON private.realtime_event_acks TO realtime_bridge;
GRANT USAGE, SELECT ON SEQUENCE private.event_outbox_id_seq TO realtime_bridge;

CREATE OR REPLACE FUNCTION private.can_subscribe_for_user(
  p_app_user_id text,
  p_scope_type text DEFAULT 'user',
  p_scope_id text DEFAULT NULL,
  p_topic text DEFAULT NULL
)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = private, pg_temp
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM private.account_profiles ap
    WHERE ap.app_user_id = p_app_user_id
      AND COALESCE(p_scope_type, 'user') = 'user'
      AND COALESCE(p_scope_id, p_app_user_id) = p_app_user_id
      AND (p_topic IS NULL OR length(p_topic) BETWEEN 1 AND 200)
  );
$$;

COMMENT ON FUNCTION private.can_subscribe_for_user(text, text, text, text) IS 'DB-owned realtime subscription authorization boundary. MVP permits a verified app_user_id to subscribe to its own user/<app_user_id> scope; future scope types can extend this function.';

CREATE OR REPLACE FUNCTION api.can_subscribe(
  p_scope_type text DEFAULT 'user',
  p_scope_id text DEFAULT NULL,
  p_topic text DEFAULT NULL
)
RETURNS boolean
LANGUAGE plpgsql
STABLE
SECURITY INVOKER
AS $$
DECLARE
  v_app_user_id text;
BEGIN
  v_app_user_id := COALESCE(
    nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'app_user_id',
    ''
  );
  IF v_app_user_id = '' THEN
    RETURN false;
  END IF;
  RETURN private.can_subscribe_for_user(v_app_user_id, p_scope_type, p_scope_id, p_topic);
END;
$$;

CREATE OR REPLACE FUNCTION private.bridge_can_subscribe(
  p_app_user_id text,
  p_scope_type text DEFAULT 'user',
  p_scope_id text DEFAULT NULL,
  p_topic text DEFAULT NULL
)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = private, pg_temp
AS $$
  SELECT private.can_subscribe_for_user(p_app_user_id, p_scope_type, p_scope_id, p_topic);
$$;

CREATE OR REPLACE FUNCTION private.bridge_replay_events(
  p_app_user_id text,
  p_scope_type text DEFAULT 'user',
  p_scope_id text DEFAULT NULL,
  p_topic text DEFAULT NULL,
  p_last_event_id bigint DEFAULT 0,
  p_limit integer DEFAULT 100
)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = private, pg_temp
AS $$
DECLARE
  v_scope_type text := COALESCE(p_scope_type, 'user');
  v_scope_id text := COALESCE(p_scope_id, p_app_user_id);
  v_limit integer := LEAST(GREATEST(COALESCE(p_limit, 100), 1), 500);
  v_events jsonb;
BEGIN
  IF NOT private.can_subscribe_for_user(p_app_user_id, v_scope_type, v_scope_id, p_topic) THEN
    RAISE EXCEPTION 'subscription denied'
      USING ERRCODE = '42501';
  END IF;

  SELECT COALESCE(jsonb_agg(jsonb_build_object(
    'id', e.id,
    'app_user_id', e.app_user_id,
    'scope_type', e.scope_type,
    'scope_id', e.scope_id,
    'topic', e.topic,
    'payload', e.payload,
    'created_at', e.created_at,
    'acked_at', a.acked_at
  ) ORDER BY e.id), '[]'::jsonb)
  INTO v_events
  FROM (
    SELECT *
    FROM private.event_outbox
    WHERE id > COALESCE(p_last_event_id, 0)
      AND scope_type = v_scope_type
      AND scope_id = v_scope_id
      AND (p_topic IS NULL OR topic = p_topic)
    ORDER BY id
    LIMIT v_limit
  ) e
  LEFT JOIN private.realtime_event_acks a
    ON a.event_id = e.id AND a.app_user_id = p_app_user_id;

  RETURN jsonb_build_object(
    'scope_type', v_scope_type,
    'scope_id', v_scope_id,
    'topic', p_topic,
    'last_event_id', COALESCE(p_last_event_id, 0),
    'events', v_events
  );
END;
$$;

CREATE OR REPLACE FUNCTION private.bridge_ack_event(
  p_app_user_id text,
  p_event_id bigint
)
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = private, pg_temp
AS $$
DECLARE
  v_event private.event_outbox%ROWTYPE;
  v_acked_at timestamptz;
BEGIN
  SELECT * INTO v_event
  FROM private.event_outbox
  WHERE id = p_event_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'event not found'
      USING ERRCODE = '02000';
  END IF;

  IF NOT private.can_subscribe_for_user(p_app_user_id, v_event.scope_type, v_event.scope_id, v_event.topic) THEN
    RAISE EXCEPTION 'ack denied'
      USING ERRCODE = '42501';
  END IF;

  INSERT INTO private.realtime_event_acks (app_user_id, event_id, acked_at)
  VALUES (p_app_user_id, p_event_id, now())
  ON CONFLICT (app_user_id, event_id)
  DO UPDATE SET acked_at = EXCLUDED.acked_at
  RETURNING acked_at INTO v_acked_at;

  RETURN jsonb_build_object(
    'app_user_id', p_app_user_id,
    'event_id', p_event_id,
    'acked_at', v_acked_at
  );
END;
$$;

GRANT EXECUTE ON FUNCTION api.can_subscribe(text, text, text) TO authenticated;
GRANT EXECUTE ON FUNCTION private.bridge_can_subscribe(text, text, text, text) TO realtime_bridge;
GRANT EXECUTE ON FUNCTION private.bridge_replay_events(text, text, text, text, bigint, integer) TO realtime_bridge;
GRANT EXECUTE ON FUNCTION private.bridge_ack_event(text, bigint) TO realtime_bridge;
REVOKE ALL ON FUNCTION api.can_subscribe(text, text, text) FROM web_anon;

CREATE OR REPLACE FUNCTION private.notify_event_outbox()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = private, pg_temp
AS $$
BEGIN
  PERFORM pg_notify(
    'app_events',
    jsonb_build_object(
      'id', NEW.id,
      'app_user_id', NEW.app_user_id,
      'scope_type', NEW.scope_type,
      'scope_id', NEW.scope_id,
      'topic', NEW.topic,
      'payload', NEW.payload,
      'created_at', NEW.created_at
    )::text
  );
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_notify_event_outbox ON private.event_outbox;
CREATE TRIGGER trg_notify_event_outbox
AFTER INSERT ON private.event_outbox
FOR EACH ROW
EXECUTE FUNCTION private.notify_event_outbox();

CREATE OR REPLACE FUNCTION api.publish_realtime_proof(p_topic text DEFAULT 'proof.realtime')
RETURNS jsonb
LANGUAGE plpgsql
VOLATILE
SECURITY INVOKER
AS $$
DECLARE
  v_app_user_id text;
  v_event private.event_outbox%ROWTYPE;
BEGIN
  v_app_user_id := COALESCE(
    nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'app_user_id',
    ''
  );

  IF v_app_user_id = '' THEN
    RAISE EXCEPTION 'missing app_user_id claim';
  END IF;

  INSERT INTO private.event_outbox (app_user_id, scope_type, scope_id, topic, payload)
  VALUES (
    v_app_user_id,
    'user',
    v_app_user_id,
    COALESCE(NULLIF(p_topic, ''), 'proof.realtime'),
    jsonb_build_object(
      'message', 'hello from pg18 realtime bridge',
      'source', 'api.publish_realtime_proof',
      'postgres_version', current_setting('server_version')
    )
  )
  RETURNING * INTO v_event;

  RETURN jsonb_build_object(
    'id', v_event.id,
    'app_user_id', v_event.app_user_id,
    'scope_type', v_event.scope_type,
    'scope_id', v_event.scope_id,
    'topic', v_event.topic,
    'payload', v_event.payload,
    'created_at', v_event.created_at
  );
END;
$$;

GRANT EXECUTE ON FUNCTION api.publish_realtime_proof(text) TO authenticated;
REVOKE ALL ON FUNCTION api.publish_realtime_proof(text) FROM web_anon;
