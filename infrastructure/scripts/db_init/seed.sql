-- Seed data for items table
BEGIN;

INSERT INTO public.items (name)
VALUES
  ('iPhone 15 Pro'),
  ('MacBook Air M2'),
  ('AirPods Pro 2'),
  ('Samsung Galaxy S23'),
  ('Google Pixel 7'),
  ('Dell XPS 13'),
  ('Sony WH-1000XM5'),
  ('iPad Pro'),
  ('Amazon Echo Dot')
ON CONFLICT (name) DO NOTHING;

COMMIT;
