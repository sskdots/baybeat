-- ============================================================
-- BayBeat Supabase Schema
-- Paste this into your Supabase SQL Editor and click Run.
-- Creates the tables, RPC, and row-level-security policies
-- needed to power shared encores and shouts.
-- ============================================================

-- Encore counts per event
CREATE TABLE IF NOT EXISTS encores (
  event_id INTEGER PRIMARY KEY,
  count INTEGER NOT NULL DEFAULT 0,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Shouts (anonymous comments) per event
CREATE TABLE IF NOT EXISTS shouts (
  id BIGSERIAL PRIMARY KEY,
  event_id INTEGER NOT NULL,
  name TEXT NOT NULL DEFAULT 'Anonymous',
  text TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS shouts_event_idx
  ON shouts(event_id, created_at DESC);

-- ------------------------------------------------------------
-- Atomic increment function
-- (the only path through which encore counts can change,
--  caps delta to ±1 to prevent abuse from anonymous clients)
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION increment_encore(eid INTEGER, delta INTEGER)
RETURNS INTEGER LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  new_count INTEGER;
BEGIN
  IF delta > 1 THEN delta := 1; END IF;
  IF delta < -1 THEN delta := -1; END IF;

  INSERT INTO encores (event_id, count, updated_at)
  VALUES (eid, GREATEST(0, delta), NOW())
  ON CONFLICT (event_id)
  DO UPDATE SET
    count = GREATEST(0, encores.count + delta),
    updated_at = NOW()
  RETURNING count INTO new_count;

  RETURN new_count;
END;
$$;

-- Allow anonymous calls
GRANT EXECUTE ON FUNCTION increment_encore(INTEGER, INTEGER) TO anon, authenticated;

-- ------------------------------------------------------------
-- Row Level Security
-- ------------------------------------------------------------
ALTER TABLE encores ENABLE ROW LEVEL SECURITY;
ALTER TABLE shouts  ENABLE ROW LEVEL SECURITY;

-- Anyone can read encore counts and shouts
DROP POLICY IF EXISTS "encores_read" ON encores;
DROP POLICY IF EXISTS "shouts_read"  ON shouts;
CREATE POLICY "encores_read" ON encores FOR SELECT USING (true);
CREATE POLICY "shouts_read"  ON shouts  FOR SELECT USING (true);

-- Anyone can insert shouts, with size constraints baked into the policy
-- (so the database itself rejects oversize / empty / spammy submissions).
DROP POLICY IF EXISTS "shouts_insert_anon" ON shouts;
CREATE POLICY "shouts_insert_anon" ON shouts FOR INSERT WITH CHECK (
  length(text) BETWEEN 1 AND 200 AND
  length(coalesce(name, 'Anonymous')) BETWEEN 1 AND 32
);

-- Encore counts can ONLY be updated through the increment_encore() RPC.
-- (No INSERT/UPDATE policy on the encores table = denied by default.)

-- ------------------------------------------------------------
-- Done. Open your project's Settings → API and copy:
--   - Project URL  →  paste into SUPABASE_URL  in baybeat.html
--   - anon/public  →  paste into SUPABASE_ANON_KEY in baybeat.html
-- ------------------------------------------------------------
