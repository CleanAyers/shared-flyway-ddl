-- beforeBaseline.sql
DO $$
DECLARE
  existing_ok int;
BEGIN
  SELECT COUNT(*) INTO existing_ok FROM flyway_schema_history WHERE success = true;
  IF existing_ok > 0 THEN
    RAISE EXCEPTION 'Refusing to baseline: already % successful migrations.', existing_ok;
  END IF;
  RAISE NOTICE '✅ beforeBaseline: Safe to baseline.';
END $$;
