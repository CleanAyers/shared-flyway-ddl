-- V3__add_users_table.sql
-- Second test migration to verify repeat sync functionality
-- Created: November 8, 2025

CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE
);

-- Create indexes for performance
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_active ON users(is_active);

-- Insert sample data
INSERT INTO users (username, email, first_name, last_name) VALUES 
    ('admin', 'admin@company.com', 'System', 'Administrator'),
    ('john_doe', 'john.doe@company.com', 'John', 'Doe'),
    ('jane_smith', 'jane.smith@company.com', 'Jane', 'Smith');

COMMENT ON TABLE users IS 'Main users table for application authentication';
COMMENT ON COLUMN users.user_id IS 'Primary key for users table';
COMMENT ON COLUMN users.username IS 'Unique username for login';