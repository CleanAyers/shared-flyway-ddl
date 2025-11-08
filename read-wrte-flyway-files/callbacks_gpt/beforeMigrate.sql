-- beforeMigrate.sql
DO $$
DECLARE
  got_lock boolean;
BEGIN
  SELECT pg_try_advisory_lock(987654321) INTO got_lock;
  IF NOT got_lock THEN
    RAISE EXCEPTION 'Another migration session is running!';
  END IF;

  CREATE SCHEMA IF NOT EXISTS sports;
  CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
  RAISE NOTICE '✅ beforeMigrate: Environment initialized.';
END $$;
