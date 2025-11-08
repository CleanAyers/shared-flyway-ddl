-- Flyway Callback: After Each Migrate
-- This runs after EACH individual migration file
-- Use for: Per-migration cleanup, logging success

-- Log migration completion
SELECT 'Successfully completed migration: ' || '${flyway:filename}' || ' at ' || NOW() AS migration_log;

-- Update per-migration audit if table exists
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'migration_audit_detail') THEN
        INSERT INTO migration_audit_detail (migration_file, execution_time, status)
        VALUES ('${flyway:filename}', NOW(), 'SUCCESS');
    END IF;
    
    RAISE NOTICE 'Post-migration cleanup completed for: ${flyway:filename}';
END $$;