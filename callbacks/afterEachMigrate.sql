-- afterEachMigrate.sql
DO $$
DECLARE
  v text; d text;
BEGIN
  SELECT version, description INTO v, d
  FROM flyway_schema_history WHERE success = true ORDER BY installed_rank DESC LIMIT 1;
  RAISE NOTICE '✅ afterEachMigrate: recorded version % (%).', v, d;
END $$;
