-- Flyway Callback: After Migrate
-- This runs after all migrations have completed successfully
-- Use for: Post-migration cleanup, notifications, statistics

-- Log migration completion
SELECT 'Migration process completed successfully at ' || NOW() AS migration_log;

-- Update migration statistics (if audit table exists)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'migration_audit') THEN
        INSERT INTO migration_audit (migration_date, operation_type, status)
        VALUES (NOW(), 'MIGRATE', 'SUCCESS');
    ELSE
        RAISE NOTICE 'Migration audit table not found - skipping audit log';
    END IF;
END $$;

-- Refresh materialized views if any exist
DO $$
DECLARE
    mv_record RECORD;
BEGIN
    FOR mv_record IN 
        SELECT schemaname, matviewname 
        FROM pg_matviews 
        WHERE schemaname NOT IN ('information_schema', 'pg_catalog')
    LOOP
        EXECUTE format('REFRESH MATERIALIZED VIEW %I.%I', mv_record.schemaname, mv_record.matviewname);
        RAISE NOTICE 'Refreshed materialized view: %.%', mv_record.schemaname, mv_record.matviewname;
    END LOOP;
END $$;