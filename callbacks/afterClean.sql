-- afterClean.sql
DO $$
BEGIN
  EXECUTE 'CREATE SCHEMA IF NOT EXISTS sports';
  RAISE NOTICE '✅ afterClean: Schema reset complete.';
END $$;
