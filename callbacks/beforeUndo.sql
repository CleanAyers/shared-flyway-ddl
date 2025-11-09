-- beforeUndo.sql
DO $$
BEGIN
  IF current_setting('app.env', true) = 'prod' THEN
    RAISE EXCEPTION 'Undo not allowed in production!';
  END IF;
  RAISE NOTICE 'beforeUndo: Allowed for env=%', current_setting('app.env', true);
END $$;
