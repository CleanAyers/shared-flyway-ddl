-- V2__test_migration.sql
-- Test migration file to verify sync system works
-- Created: November 8, 2025
-- pipeline trigger

CREATE TABLE test_sync_table (
    id SERIAL PRIMARY KEY,
    test_name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    sync_test BOOLEAN DEFAULT TRUE
);

-- Insert test data
INSERT INTO test_sync_table (test_name) VALUES 
    ('Sync Test 1'),
    ('Sync Test 2'),
    ('Distribution Test');

-- Add index for performance
CREATE INDEX idx_test_sync_created_at ON test_sync_table(created_at);

COMMENT ON TABLE test_sync_table IS 'Test table to verify distributed Flyway sync system';