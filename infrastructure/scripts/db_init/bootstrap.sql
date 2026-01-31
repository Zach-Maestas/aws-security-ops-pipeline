-- Bootstrap SQL script to set up roles and privileges
BEGIN;

-- Lock down default PUBLIC privileges
REVOKE ALL ON SCHEMA public FROM PUBLIC;

-- Create the app role if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'app_items_rw') THEN
    CREATE ROLE app_items_rw LOGIN;
  END IF;
END
$$;

-- Set password using psql variable (passed via psql -v app_password="...")
-- This always updates the password, which is good for secret rotation
ALTER ROLE app_items_rw WITH PASSWORD :'app_password';

-- Grant least privilege to the app role
GRANT USAGE ON SCHEMA public TO app_items_rw;

-- Table privileges
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.items TO app_items_rw;

-- Sequence privileges
GRANT USAGE, SELECT ON SEQUENCE public.items_id_seq TO app_items_rw;

COMMIT;