-- Runs before any migration begins.
-- Useful for environment checks, dependency validation, or safety guards.

DO $$
DECLARE
    dbname TEXT := current_database();
    schema_count INT;
BEGIN
    SELECT COUNT(*) INTO schema_count FROM information_schema.schemata WHERE schema_name = 'sports';

    IF schema_count = 0 THEN
        RAISE NOTICE 'Schema "sports" not found. Creating...';
        EXECUTE 'CREATE SCHEMA IF NOT EXISTS sports';
    ELSE
        RAISE NOTICE 'Schema "sports" already exists in database "%".', dbname;
    END IF;

    RAISE NOTICE '✅ Pre-migration checks passed for % at %', dbname, now();
END $$;
