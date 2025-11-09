-- Test GUI Drag-and-Drop Integration
-- This file tests the seamless GitHub web interface workflow
-- Simply drag this file into GitHub web UI → automatic sync to all child repos

CREATE TABLE test_gui_integration (
    id SERIAL PRIMARY KEY,
    test_name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    description TEXT
);

-- Insert test data
INSERT INTO test_gui_integration (test_name, description) VALUES 
('drag_drop_test', 'Testing GitHub web interface drag-and-drop functionality'),
('auto_sync_test', 'Verifying automatic sync to all child repositories');

-- Test comment: This should appear in all child repos automatically!