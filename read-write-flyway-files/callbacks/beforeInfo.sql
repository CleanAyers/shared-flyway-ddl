-- beforeInfo.sql
DO $$
BEGIN
  CREATE TABLE IF NOT EXISTS flyway_info_snapshots (
    id bigserial PRIMARY KEY,
    collected_at timestamptz DEFAULT now(),
    user_name text DEFAULT current_user
  );
  INSERT INTO flyway_info_snapshots DEFAULT VALUES;
  RAISE NOTICE 'beforeInfo: Snapshot captured.';
END $$;
