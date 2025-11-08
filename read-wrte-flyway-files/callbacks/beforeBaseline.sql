-- Flyway Callback: Before Baseline
-- This runs before Flyway baseline operation
-- Use for: Baseline preparation, validation

-- Log baseline operation start
SELECT 'Starting baseline operation at ' || NOW() AS baseline_log;

DO $$
DECLARE
    current_db_name TEXT;
    table_count INTEGER;
BEGIN
    SELECT current_database() INTO current_db_name;
    SELECT count(*) INTO table_count FROM information_schema.tables WHERE table_schema = 'public';
    
    RAISE NOTICE 'Baseline operation starting on database: %', current_db_name;
    RAISE NOTICE 'Current table count: %', table_count;
    
    -- Warn if database is not empty
    IF table_count > 0 THEN
        RAISE NOTICE 'Warning: Database contains % existing tables', table_count;
        RAISE NOTICE 'Baseline will mark current state as migration starting point';
    END IF;
END $$;