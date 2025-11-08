-- afterInfo.sql
DO $$
DECLARE
  total int; failed int;
BEGIN
  SELECT COUNT(*) FILTER (WHERE success), COUNT(*) FILTER (WHERE NOT success)
    INTO total, failed FROM flyway_schema_history;
  RAISE NOTICE 'afterInfo: % success, % failed.', total, failed;
END $$;
