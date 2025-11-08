-- afterMigrate.sql
DO $$
DECLARE
  applied_count int;
BEGIN
  SELECT COUNT(*) INTO applied_count FROM flyway_schema_history WHERE success = true;
  PERFORM pg_advisory_unlock(987654321);
  RAISE NOTICE '✅ afterMigrate: % applied.', applied_count;
END $$;
