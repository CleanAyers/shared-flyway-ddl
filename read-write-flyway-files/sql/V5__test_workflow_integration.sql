-- V5__test_workflow_integration.sql
-- Test migration to verify GitHub Actions workflow is working properly
-- Created: November 8, 2025
-- Purpose: Validate end-to-end sync from parent to all 4 child repositories

-- Create a simple test table to verify workflow integration
CREATE TABLE IF NOT EXISTS workflow_test (
    id SERIAL PRIMARY KEY,
    test_name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    workflow_run_id VARCHAR(50),
    sync_status VARCHAR(20) DEFAULT 'pending'
);

-- Insert a test record to verify the migration worked
INSERT INTO workflow_test (test_name, workflow_run_id, sync_status) 
VALUES ('GitHub Actions Integration Test', 'manual-validation', 'completed');

-- Add a comment to document this test
COMMENT ON TABLE workflow_test IS 'Test table to verify GitHub Actions sync workflow from shared-flyway-ddl to all child repositories';