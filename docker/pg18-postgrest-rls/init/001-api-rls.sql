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
