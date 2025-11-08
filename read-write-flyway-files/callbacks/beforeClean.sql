-- beforeClean.sql
DO $$
BEGIN
  IF COALESCE(current_setting('app.flyway_allow_clean', true), 'off') <> 'on' THEN
    RAISE EXCEPTION 'Clean not allowed unless app.flyway_allow_clean = on';
  END IF;
  RAISE NOTICE '✅ beforeClean: Authorized clean operation.';
END $$;
