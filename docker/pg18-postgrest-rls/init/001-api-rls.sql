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


-- Realtime MVP: Postgres-first event outbox + LISTEN/NOTIFY bridge.
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
  topic text NOT NULL,
  payload jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE private.event_outbox ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.event_outbox FORCE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS event_outbox_by_jwt_user ON private.event_outbox;
CREATE POLICY event_outbox_by_jwt_user
ON private.event_outbox
FOR SELECT
TO authenticated
USING (
  app_user_id = COALESCE(
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
);

GRANT SELECT, INSERT ON private.event_outbox TO authenticated;
GRANT USAGE, SELECT ON SEQUENCE private.event_outbox_id_seq TO authenticated;
GRANT USAGE ON SCHEMA private TO realtime_bridge;
GRANT SELECT ON private.event_outbox TO realtime_bridge;
GRANT USAGE, SELECT ON SEQUENCE private.event_outbox_id_seq TO realtime_bridge;

CREATE OR REPLACE FUNCTION private.notify_event_outbox()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  PERFORM pg_notify(
    'app_events',
    jsonb_build_object(
      'id', NEW.id,
      'app_user_id', NEW.app_user_id,
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

  INSERT INTO private.event_outbox (app_user_id, topic, payload)
  VALUES (
    v_app_user_id,
    p_topic,
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
    'topic', v_event.topic,
    'payload', v_event.payload,
    'created_at', v_event.created_at
  );
END;
$$;

GRANT EXECUTE ON FUNCTION api.publish_realtime_proof(text) TO authenticated;
REVOKE ALL ON FUNCTION api.publish_realtime_proof(text) FROM web_anon;
