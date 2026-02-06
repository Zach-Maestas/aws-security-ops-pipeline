#!/bin/sh
set -eu

# Expect these to be provided by ECS env vars and secrets:
# PGHOST, PGDATABASE, PGPORT, PGUSER, PGPASSWORD (master credentials)
# APP_DB_USERNAME, APP_DB_PASSWORD (app user credentials to create)
: "${PGHOST:?missing PGHOST}"
: "${PGDATABASE:?missing PGDATABASE}"
: "${PGPORT:?missing PGPORT}"
: "${PGUSER:?missing PGUSER}"
: "${PGPASSWORD:?missing PGPASSWORD}"
: "${APP_DB_USERNAME:?missing APP_DB_USERNAME}"
: "${APP_DB_PASSWORD:?missing APP_DB_PASSWORD}"

psql -v ON_ERROR_STOP=1 -f /db-init/schema.sql
psql -v ON_ERROR_STOP=1 -v app_username="$APP_DB_USERNAME" -v app_password="$APP_DB_PASSWORD" -f /db-init/bootstrap.sql
psql -v ON_ERROR_STOP=1 -f /db-init/seed.sql
