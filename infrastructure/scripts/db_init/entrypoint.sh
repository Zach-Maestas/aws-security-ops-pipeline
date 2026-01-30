#!/bin/sh
set -eu

# Expect these to be provided by ECS env vars and secrets:
# PGHOST, PGDATABASE, PGPORT, PGUSER, PGPASSWORD
: "${PGHOST:?missing PGHOST}"
: "${PGDATABASE:?missing PGDATABASE}"
: "${PGPORT:?missing PGPORT}"
: "${PGUSER:?missing PGUSER}"
: "${PGPASSWORD:?missing PGPASSWORD}"

psql -v ON_ERROR_STOP=1 -f /db-init/schema.sql
psql -v ON_ERROR_STOP=1 -f /db-init/bootstrap.sql
psql -v ON_ERROR_STOP=1 -f /db-init/seed.sql
