-- Flyway Callback: Before Clean
-- This runs before Flyway clean operation (database wipe)
-- Use for: Safety checks, backups, warnings

-- CRITICAL SAFETY CHECK - Prevent accidental production clean
DO $$
DECLARE
    current_db_name TEXT;
    is_production BOOLEAN := FALSE;
BEGIN
    SELECT current_database() INTO current_db_name;
    
    -- Check if this looks like a production database
    IF current_db_name ILIKE '%prod%' OR 
       current_db_name ILIKE '%production%' OR
       current_db_name ILIKE '%live%' THEN
        is_production := TRUE;
    END IF;
    
    -- Log the clean operation
    RAISE NOTICE 'CLEAN OPERATION STARTING on database: %', current_db_name;
    
    -- Extra warning for production-like databases
    IF is_production THEN
        RAISE WARNING 'DANGER: Clean operation on production-like database: %', current_db_name;
        RAISE WARNING 'This will DELETE ALL DATA. Ensure you have backups!';
    END IF;
    
    -- Create a safety log entry if audit table exists
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'migration_audit') THEN
        INSERT INTO migration_audit (migration_date, operation_type, status, notes)
        VALUES (NOW(), 'CLEAN_START', 'WARNING', 'Clean operation initiated on: ' || current_db_name);
    END IF;
END $$;