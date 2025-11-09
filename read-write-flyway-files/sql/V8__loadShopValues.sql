-- SAMPLE DATA
INSERT INTO roles (role_name) VALUES ('admin'), ('customer');
INSERT INTO categories (name, description) VALUES ('Electronics','Devices'), ('Clothing','Apparel');
INSERT INTO products (category_id, name, price, stock) VALUES (1,'Laptop',899.99,10), (2,'T-Shirt',19.99,3);
