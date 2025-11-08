-- Flyway Callback: Before Migrate
-- This runs before any migration operation starts
-- Use for: Environment setup, pre-migration validation

-- Log the migration start
SELECT 'Starting migration process at ' || NOW() AS migration_log;

-- Validate environment readiness
DO $$
BEGIN
    -- Check if required extensions exist
    IF NOT EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'uuid-ossp') THEN
        RAISE NOTICE 'UUID extension not found - consider installing uuid-ossp';
    END IF;
    
    RAISE NOTICE 'Environment validation complete - ready for migrations';
END $$;