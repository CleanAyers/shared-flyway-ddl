-- Flyway Callback: After Clean
-- This runs after Flyway clean operation completes
-- Use for: Post-clean logging, environment reset

-- Log clean completion
SELECT 'Database clean operation completed at ' || NOW() AS clean_log;

DO $$
DECLARE
    current_db_name TEXT;
BEGIN
    SELECT current_database() INTO current_db_name;
    
    RAISE NOTICE 'Clean operation completed successfully on database: %', current_db_name;
    RAISE NOTICE 'Database is now empty and ready for fresh migrations';
    
    -- Note: Cannot log to audit table since it was cleaned!
    -- This callback runs on empty database
END $$;