-- Schema initialization script
BEGIN;

CREATE TABLE IF NOT EXISTS public.items (
  id         BIGSERIAL PRIMARY KEY,
  name       TEXT NOT NULL CHECK (
    length(trim(name)) > 0
    AND length(name) <= 120
  ),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS items_created_at_idx ON public.items (created_at);
CREATE UNIQUE INDEX IF NOT EXISTS items_name_uniq_idx ON public.items (name);

COMMIT;

