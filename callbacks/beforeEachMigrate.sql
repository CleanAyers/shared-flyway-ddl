-- beforeEachMigrate.sql
DO $$
BEGIN
  RAISE NOTICE 'Preparing for next migration...';
END $$;
