-- afterBaseline.sql
DO $$
BEGIN
  EXECUTE 'CREATE SCHEMA IF NOT EXISTS sports';
  RAISE NOTICE '✅ afterBaseline: Schema ready.';
END $$;
