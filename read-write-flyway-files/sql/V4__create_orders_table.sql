-- V4__create_orders_table.sql
-- Test migration for PR workflow validation
-- Author: GitHub Copilot
-- Date: 2025-11-08

CREATE TABLE orders (
    id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    customer_id BIGINT NOT NULL,
    order_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(50) NOT NULL DEFAULT 'pending',
    total_amount DECIMAL(12,2) NOT NULL,
    
    -- Indexes for performance
    CONSTRAINT orders_status_check CHECK (status IN ('pending', 'processing', 'shipped', 'delivered', 'cancelled')),
    CONSTRAINT orders_total_positive CHECK (total_amount > 0)
);

-- Add indexes
CREATE INDEX idx_orders_customer_id ON orders(customer_id);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_date ON orders(order_date);

-- Sample data for testing
INSERT INTO orders (customer_id, status, total_amount) VALUES
(1, 'pending', 99.99),
(2, 'processing', 249.50),
(3, 'shipped', 75.25);

COMMENT ON TABLE orders IS 'Customer order tracking table';
COMMENT ON COLUMN orders.status IS 'Order status: pending, processing, shipped, delivered, cancelled';