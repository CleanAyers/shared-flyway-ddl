-- Flyway Callback: Before Each Migrate
-- This runs before EACH individual migration file
-- Use for: Per-migration logging, validation checks

-- Log which migration is about to run
SELECT 'About to execute migration: ' || '${flyway:filename}' || ' at ' || NOW() AS migration_log;

-- Validate database state before this migration
DO $$
BEGIN
    -- Check database connection count (warn if too many connections)
    IF (SELECT count(*) FROM pg_stat_activity WHERE state = 'active') > 50 THEN
        RAISE NOTICE 'Warning: High number of active connections (%) detected', 
            (SELECT count(*) FROM pg_stat_activity WHERE state = 'active');
    END IF;
    
    RAISE NOTICE 'Pre-migration validation passed for: ${flyway:filename}';
END $$;