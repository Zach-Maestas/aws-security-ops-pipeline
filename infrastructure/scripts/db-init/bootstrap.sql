-- Bootstrap SQL script to set up roles and privileges
BEGIN;

-- Lock down default PUBLIC privileges
REVOKE ALL ON SCHEMA public FROM PUBLIC;

-- Create the app role if it doesn't exist (uses psql meta-commands since
-- psql variable substitution doesn't work inside DO $$ PL/pgSQL blocks)
SELECT count(*) = 0 AS needs_create FROM pg_roles WHERE rolname = :'app_username' \gset
\if :needs_create
CREATE ROLE :"app_username" LOGIN;
\endif

-- Set password using psql variable (passed via psql -v app_password="...")
-- This always updates the password, which is good for secret rotation
ALTER ROLE :"app_username" WITH PASSWORD :'app_password';

-- Grant least privilege to the app role
GRANT USAGE ON SCHEMA public TO :"app_username";

-- Table privileges
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.items TO :"app_username";

-- Sequence privileges
GRANT USAGE, SELECT ON SEQUENCE public.items_id_seq TO :"app_username";

COMMIT;
