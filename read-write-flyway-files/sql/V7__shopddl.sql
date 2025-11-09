-- Sample Shop Database Schema (~18 tables + triggers)
-- Designed for exploration, DDL extraction, and trigger testing

-- Drop existing objects
DROP SCHEMA IF EXISTS shop CASCADE;
CREATE SCHEMA shop;
SET search_path TO shop;

-- USERS & ROLES
CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    username TEXT UNIQUE NOT NULL,
    email TEXT UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT now()
);

CREATE TABLE roles (
    role_id SERIAL PRIMARY KEY,
    role_name TEXT UNIQUE NOT NULL
);

CREATE TABLE user_roles (
    user_id INT REFERENCES users(user_id) ON DELETE CASCADE,
    role_id INT REFERENCES roles(role_id) ON DELETE CASCADE,
    PRIMARY KEY (user_id, role_id)
);

-- PRODUCTS & INVENTORY
CREATE TABLE categories (
    category_id SERIAL PRIMARY KEY,
    name TEXT UNIQUE NOT NULL,
    description TEXT
);

CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    category_id INT REFERENCES categories(category_id),
    name TEXT NOT NULL,
    price NUMERIC(10,2) NOT NULL CHECK (price >= 0),
    stock INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now()
);

CREATE TABLE suppliers (
    supplier_id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    contact_email TEXT,
    phone TEXT
);

CREATE TABLE product_suppliers (
    product_id INT REFERENCES products(product_id) ON DELETE CASCADE,
    supplier_id INT REFERENCES suppliers(supplier_id) ON DELETE CASCADE,
    PRIMARY KEY (product_id, supplier_id)
);

-- CUSTOMERS & ORDERS
CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT UNIQUE,
    phone TEXT,
    created_at TIMESTAMP DEFAULT now()
);

CREATE TABLE addresses (
    address_id SERIAL PRIMARY KEY,
    customer_id INT REFERENCES customers(customer_id) ON DELETE CASCADE,
    street TEXT NOT NULL,
    city TEXT NOT NULL,
    state TEXT NOT NULL,
    zip TEXT NOT NULL
);

CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    customer_id INT REFERENCES customers(customer_id),
    order_date TIMESTAMP DEFAULT now(),
    total NUMERIC(10,2) DEFAULT 0,
    status TEXT DEFAULT 'PENDING'
);

CREATE TABLE order_items (
    order_item_id SERIAL PRIMARY KEY,
    order_id INT REFERENCES orders(order_id) ON DELETE CASCADE,
    product_id INT REFERENCES products(product_id),
    quantity INT CHECK (quantity > 0),
    price NUMERIC(10,2) CHECK (price >= 0)
);

-- PAYMENTS & SHIPMENTS
CREATE TABLE payments (
    payment_id SERIAL PRIMARY KEY,
    order_id INT REFERENCES orders(order_id) ON DELETE CASCADE,
    amount NUMERIC(10,2) NOT NULL,
    paid_at TIMESTAMP DEFAULT now(),
    method TEXT DEFAULT 'CARD'
);

CREATE TABLE shipments (
    shipment_id SERIAL PRIMARY KEY,
    order_id INT REFERENCES orders(order_id) ON DELETE CASCADE,
    shipped_at TIMESTAMP,
    tracking_number TEXT
);

-- AUDIT LOGS
CREATE TABLE audit_log (
    log_id SERIAL PRIMARY KEY,
    table_name TEXT NOT NULL,
    record_id INT NOT NULL,
    action TEXT NOT NULL,
    changed_at TIMESTAMP DEFAULT now()
);

-- FUNCTIONS & TRIGGERS
CREATE OR REPLACE FUNCTION trg_update_timestamp() RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION trg_audit_change() RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO audit_log(table_name, record_id, action)
    VALUES (TG_TABLE_NAME, NEW.product_id, TG_OP);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply update trigger to products
CREATE TRIGGER products_update_timestamp
BEFORE UPDATE ON products
FOR EACH ROW
EXECUTE FUNCTION trg_update_timestamp();

-- Apply audit trigger to products
CREATE TRIGGER products_audit
AFTER INSERT OR UPDATE OR DELETE ON products
FOR EACH ROW
EXECUTE FUNCTION trg_audit_change();

-- VIEWS
CREATE VIEW vw_order_summary AS
SELECT o.order_id, c.name AS customer_name, o.total, o.status, COUNT(oi.order_item_id) AS item_count
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
LEFT JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY o.order_id, c.name, o.total, o.status;

CREATE VIEW vw_low_stock AS
SELECT p.product_id, p.name, p.stock
FROM products p
WHERE p.stock < 5;
