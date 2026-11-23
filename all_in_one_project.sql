-- =============================================================================
-- ALL-IN-ONE POSTGRESQL DATABASE PROJECT SCRIPT
-- Project: E-Commerce Store & Order Management Database
-- Session 4 - Assignment: AI-Assisted PostgreSQL Database Project
-- =============================================================================

-- =============================================================================
-- SECTION 1: SCHEMA DDL (4 RELATED TABLES WITH CONSTRAINTS)
-- =============================================================================

DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS customers CASCADE;

-- 1.1 customers
CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    phone VARCHAR(20),
    city VARCHAR(50) NOT NULL,
    country VARCHAR(50) NOT NULL DEFAULT 'Saudi Arabia',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,

    CONSTRAINT chk_customer_email_format 
        CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    CONSTRAINT chk_customer_name_length 
        CHECK (LENGTH(TRIM(first_name)) >= 2 AND LENGTH(TRIM(last_name)) >= 2)
);

-- 1.2 products
CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    product_name VARCHAR(120) NOT NULL,
    category VARCHAR(50) NOT NULL,
    unit_price NUMERIC(10, 2) NOT NULL,
    stock_quantity INTEGER NOT NULL DEFAULT 0,
    sku VARCHAR(30) NOT NULL UNIQUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_product_price_positive 
        CHECK (unit_price > 0),
    CONSTRAINT chk_product_stock_non_negative 
        CHECK (stock_quantity >= 0),
    CONSTRAINT chk_product_category 
        CHECK (category IN ('Electronics', 'Fitness', 'Accessories', 'Nutrition', 'Books'))
);

-- 1.3 orders
CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    customer_id INTEGER NOT NULL,
    order_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    shipping_city VARCHAR(50) NOT NULL,
    total_amount NUMERIC(10, 2) NOT NULL DEFAULT 0.00,

    CONSTRAINT fk_orders_customer 
        FOREIGN KEY (customer_id) 
        REFERENCES customers(customer_id) 
        ON DELETE RESTRICT 
        ON UPDATE CASCADE,
    CONSTRAINT chk_order_status 
        CHECK (status IN ('PENDING', 'PROCESSING', 'SHIPPED', 'DELIVERED', 'CANCELLED')),
    CONSTRAINT chk_order_total_non_negative 
        CHECK (total_amount >= 0)
);

-- 1.4 order_items
CREATE TABLE order_items (
    order_item_id SERIAL PRIMARY KEY,
    order_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    quantity INTEGER NOT NULL,
    unit_price NUMERIC(10, 2) NOT NULL,
    subtotal NUMERIC(10, 2) GENERATED ALWAYS AS (quantity * unit_price) STORED,

    CONSTRAINT fk_order_items_order 
        FOREIGN KEY (order_id) 
        REFERENCES orders(order_id) 
        ON DELETE CASCADE 
        ON UPDATE CASCADE,
    CONSTRAINT fk_order_items_product 
        FOREIGN KEY (product_id) 
        REFERENCES products(product_id) 
        ON DELETE RESTRICT 
        ON UPDATE CASCADE,
    CONSTRAINT uq_order_product 
        UNIQUE (order_id, product_id),
    CONSTRAINT chk_order_item_quantity_positive 
        CHECK (quantity > 0),
    CONSTRAINT chk_order_item_price_positive 
        CHECK (unit_price > 0)
);

-- =============================================================================
-- SECTION 2: SEED DATA & BULK SYNTHETIC DATA GENERATOR
-- =============================================================================

INSERT INTO customers (first_name, last_name, email, phone, city, country, is_active) VALUES
('Ahmed', 'Al-Mansoor', 'ahmed.mansoor@example.com', '+966501112233', 'Riyadh', 'Saudi Arabia', TRUE),
('Sara', 'Al-Otaibi', 'sara.otaibi@example.com', '+966502223344', 'Jeddah', 'Saudi Arabia', TRUE),
('Omar', 'Farooq', 'omar.farooq@example.com', '+966503334455', 'Dammam', 'Saudi Arabia', TRUE),
('Fatima', 'Al-Zahrani', 'fatima.zahrani@example.com', '+966504445566', 'Makkah', 'Saudi Arabia', TRUE),
('Khalid', 'Al-Ghamdi', 'khalid.ghamdi@example.com', '+966505556677', 'Madinah', 'Saudi Arabia', TRUE),
('Noura', 'Al-Shehri', 'noura.shehri@example.com', '+966506667788', 'Khobar', 'Saudi Arabia', TRUE),
('Mohammed', 'Al-Harbi', 'mohammed.harbi@example.com', '+966507778899', 'Abha', 'Saudi Arabia', TRUE),
('Reem', 'Al-Dosari', 'reem.dosari@example.com', '+966508889900', 'Tabuk', 'Saudi Arabia', TRUE),
('Youssef', 'Al-Qarni', 'youssef.qarni@example.com', '+966509990011', 'Taif', 'Saudi Arabia', FALSE),
('Huda', 'Al-Mutairi', 'huda.mutairi@example.com', '+966501234567', 'Riyadh', 'Saudi Arabia', TRUE);

INSERT INTO products (product_name, category, unit_price, stock_quantity, sku) VALUES
('Smart Fitness Watch Pro', 'Electronics', 599.00, 50, 'ELEC-WATCH-001'),
('Wireless Noise-Canceling Earbuds', 'Electronics', 349.50, 75, 'ELEC-BUDS-002'),
('Ultra HD 4K Action Camera', 'Electronics', 899.00, 30, 'ELEC-CAM-003'),
('Adjustable Dumbbell Set (20kg)', 'Fitness', 250.00, 40, 'FIT-DUMB-001'),
('Premium Yoga & Workout Mat', 'Fitness', 120.00, 100, 'FIT-MAT-002'),
('Resistance Bands Set (5-Pack)', 'Fitness', 75.00, 150, 'FIT-BAND-003'),
('Waterproof Sports Gym Backpack', 'Accessories', 160.00, 60, 'ACC-BAG-001'),
('Stainless Steel Insulated Water Bottle', 'Accessories', 85.00, 120, 'ACC-BTL-002'),
('Whey Protein Isolate (2kg)', 'Nutrition', 310.00, 80, 'NUT-PROT-001'),
('Branched-Chain Amino Acids (BCAA)', 'Nutrition', 145.00, 90, 'NUT-BCAA-002'),
('Daily Multivitamin Complex (90 Caps)', 'Nutrition', 95.00, 110, 'NUT-VITA-003'),
('Science and Practice of Strength Training', 'Books', 180.00, 25, 'BOOK-STR-001');

INSERT INTO orders (customer_id, order_date, status, shipping_city, total_amount) VALUES
(1, CURRENT_TIMESTAMP - INTERVAL '15 days', 'DELIVERED', 'Riyadh', 1009.00),
(2, CURRENT_TIMESTAMP - INTERVAL '12 days', 'DELIVERED', 'Jeddah', 469.50),
(3, CURRENT_TIMESTAMP - INTERVAL '10 days', 'SHIPPED', 'Dammam', 370.00),
(4, CURRENT_TIMESTAMP - INTERVAL '8 days', 'PROCESSING', 'Makkah', 899.00),
(1, CURRENT_TIMESTAMP - INTERVAL '5 days', 'DELIVERED', 'Riyadh', 325.00),
(5, CURRENT_TIMESTAMP - INTERVAL '3 days', 'PROCESSING', 'Madinah', 599.00),
(6, CURRENT_TIMESTAMP - INTERVAL '2 days', 'PENDING', 'Khobar', 235.00),
(7, CURRENT_TIMESTAMP - INTERVAL '1 day', 'PENDING', 'Abha', 150.00),
(2, CURRENT_TIMESTAMP - INTERVAL '12 hours', 'PENDING', 'Jeddah', 620.00),
(8, CURRENT_TIMESTAMP - INTERVAL '2 hours', 'CANCELLED', 'Tabuk', 250.00);

INSERT INTO order_items (order_id, product_id, quantity, unit_price) VALUES
(1, 1, 1, 599.00),
(1, 4, 1, 250.00),
(1, 7, 1, 160.00),
(2, 2, 1, 349.50),
(2, 5, 1, 120.00),
(3, 9, 1, 310.00),
(3, 6, 1, 60.00),
(4, 3, 1, 899.00),
(5, 4, 1, 250.00),
(5, 6, 1, 75.00),
(6, 1, 1, 599.00),
(7, 5, 1, 120.00),
(7, 10, 1, 115.00),
(8, 6, 2, 75.00),
(9, 9, 2, 310.00),
(10, 4, 1, 250.00);

-- Update totals accurately
UPDATE orders o
SET total_amount = sub.calculated_total
FROM (
    SELECT order_id, SUM(quantity * unit_price) AS calculated_total
    FROM order_items
    GROUP BY order_id
) sub
WHERE o.order_id = sub.order_id;

-- Generate 5,000 orders for index testing
DO $$
DECLARE
    v_order_id INTEGER;
    v_cust_id INTEGER;
    v_prod_id INTEGER;
    v_qty INTEGER;
    v_price NUMERIC(10,2);
    v_i INTEGER;
BEGIN
    FOR v_i IN 1..5000 LOOP
        v_cust_id := floor(random() * 10 + 1)::INTEGER;
        INSERT INTO orders (customer_id, order_date, status, shipping_city, total_amount)
        VALUES (
            v_cust_id,
            CURRENT_TIMESTAMP - (random() * 180 || ' days')::INTERVAL,
            (ARRAY['PENDING', 'PROCESSING', 'SHIPPED', 'DELIVERED', 'CANCELLED'])[floor(random() * 5 + 1)::INTEGER],
            (ARRAY['Riyadh', 'Jeddah', 'Dammam', 'Makkah', 'Madinah', 'Khobar'])[floor(random() * 6 + 1)::INTEGER],
            0.00
        ) RETURNING order_id INTO v_order_id;

        v_prod_id := floor(random() * 12 + 1)::INTEGER;
        v_qty := floor(random() * 3 + 1)::INTEGER;
        SELECT unit_price INTO v_price FROM products WHERE product_id = v_prod_id;

        INSERT INTO order_items (order_id, product_id, quantity, unit_price)
        VALUES (v_order_id, v_prod_id, v_qty, v_price);
        
        UPDATE orders SET total_amount = v_qty * v_price WHERE order_id = v_order_id;
    END LOOP;
END $$;

-- =============================================================================
-- SECTION 3: CRUD VERIFICATION
-- =============================================================================

-- CREATE
INSERT INTO customers (first_name, last_name, email, phone, city, country)
VALUES ('Majed', 'Al-Olayan', 'majed.olayan@example.com', '+966504443322', 'Riyadh', 'Saudi Arabia');

-- READ
SELECT customer_id, first_name, last_name, email, city 
FROM customers 
WHERE is_active = TRUE AND city = 'Riyadh';

-- UPDATE
UPDATE products 
SET stock_quantity = stock_quantity + 10 
WHERE product_id = 1;

-- DELETE
DELETE FROM customers WHERE email = 'majed.olayan@example.com';

-- =============================================================================
-- SECTION 4: JOINS, AGGREGATIONS, PAGINATION
-- =============================================================================

-- Multi-table JOIN
SELECT 
    o.order_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    p.product_name,
    oi.quantity,
    oi.unit_price,
    oi.subtotal
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
LIMIT 5;

-- GROUP BY with HAVING
SELECT 
    c.customer_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    COUNT(o.order_id) AS total_orders,
    ROUND(SUM(o.total_amount), 2) AS total_spent
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, customer_name
HAVING COUNT(o.order_id) > 10
ORDER BY total_spent DESC;

-- Pagination (Offset 0, Limit 5)
SELECT order_id, customer_id, order_date, status, total_amount
FROM orders
ORDER BY order_date DESC
LIMIT 5 OFFSET 0;

-- =============================================================================
-- SECTION 5: TRANSACTIONS (COMMIT & ROLLBACK)
-- =============================================================================

-- Scenario A: COMMIT
BEGIN;
    UPDATE products SET stock_quantity = stock_quantity - 1 WHERE product_id = 2;
    INSERT INTO orders (customer_id, order_date, status, shipping_city, total_amount)
    VALUES (3, CURRENT_TIMESTAMP, 'PENDING', 'Dammam', 349.50);
    INSERT INTO order_items (order_id, product_id, quantity, unit_price)
    VALUES (currval('orders_order_id_seq'), 2, 1, 349.50);
COMMIT;

-- Scenario B: ROLLBACK
BEGIN;
    INSERT INTO orders (customer_id, order_date, status, shipping_city, total_amount)
    VALUES (4, CURRENT_TIMESTAMP, 'PENDING', 'Makkah', 99999.00);
    -- Simulated stock shortage check triggers rollback
    ROLLBACK;

-- =============================================================================
-- SECTION 6: INDEX EVALUATION (EXPLAIN ANALYZE)
-- =============================================================================

DROP INDEX IF EXISTS idx_orders_customer_id;

-- 1. Explain analyze before index
EXPLAIN (ANALYZE, BUFFERS)
SELECT order_id, customer_id, order_date, status, total_amount
FROM orders
WHERE customer_id = 7
ORDER BY order_date DESC;

-- 2. Create B-Tree index
CREATE INDEX idx_orders_customer_id_date ON orders (customer_id, order_date DESC);
ANALYZE orders;

-- 3. Explain analyze after index
EXPLAIN (ANALYZE, BUFFERS)
SELECT order_id, customer_id, order_date, status, total_amount
FROM orders
WHERE customer_id = 7
ORDER BY order_date DESC;
