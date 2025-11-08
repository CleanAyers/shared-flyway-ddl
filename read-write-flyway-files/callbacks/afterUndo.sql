-- afterUndo.sql
DO $$
BEGIN
  CREATE TABLE IF NOT EXISTS flyway_undo_audit(
    id bigserial PRIMARY KEY,
    undone_at timestamptz DEFAULT now(),
    user_name text DEFAULT current_user
  );
  INSERT INTO flyway_undo_audit DEFAULT VALUES;
  RAISE NOTICE 'afterUndo: Undo audited.';
END $$;
