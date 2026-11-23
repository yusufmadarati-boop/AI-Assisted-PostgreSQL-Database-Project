-- ============================================================================
-- Project: AI-Assisted PostgreSQL Database Project
-- Script: 02_seed_data.sql
-- Description: Realistic sample dataset for development, testing, and queries.
-- ============================================================================

-- Clear existing data (in case of re-run)
TRUNCATE TABLE order_items, orders, products, customers RESTART IDENTITY CASCADE;

-- ---------------------------------------------------------------------------
-- 1. Insert Customers (10 diverse customer profiles)
-- ---------------------------------------------------------------------------
INSERT INTO customers (first_name, last_name, email, phone, address, city, country, status, created_at)
VALUES
    ('Alice', 'Johnson', 'alice.johnson@example.com', '+1-555-0101', '124 Market St', 'San Francisco', 'United States', 'active', '2024-01-10 09:30:00+00'),
    ('Bob', 'Smith', 'bob.smith@example.com', '+1-555-0102', '456 Elm Ave', 'Austin', 'United States', 'active', '2024-01-15 14:20:00+00'),
    ('Charlie', 'Brown', 'charlie.brown@example.com', '+1-555-0103', '789 Oak Blvd', 'Seattle', 'United States', 'active', '2024-02-01 11:15:00+00'),
    ('Diana', 'Prince', 'diana.prince@example.com', '+1-555-0104', '321 Pine Rd', 'Chicago', 'United States', 'active', '2024-02-14 16:45:00+00'),
    ('Evan', 'Wright', 'evan.wright@example.com', '+1-555-0105', '654 Maple Dr', 'New York', 'United States', 'inactive', '2024-02-20 08:00:00+00'),
    ('Fiona', 'Gallagher', 'fiona.g@example.com', '+1-555-0106', '987 Cedar Ln', 'Boston', 'United States', 'active', '2024-03-05 13:10:00+00'),
    ('George', 'Clark', 'george.clark@example.com', '+1-555-0107', '159 Spruce Way', 'Denver', 'United States', 'suspended', '2024-03-12 17:30:00+00'),
    ('Hannah', 'Abbott', 'hannah.abbott@example.com', '+1-555-0108', '753 Willow Ct', 'San Diego', 'United States', 'active', '2024-03-25 10:00:00+00'),
    ('Ian', 'Malcolm', 'ian.malcolm@example.com', '+1-555-0109', '852 Birch St', 'Miami', 'United States', 'active', '2024-04-02 12:40:00+00'),
    ('Julia', 'Roberts', 'julia.roberts@example.com', '+1-555-0110', '963 Redwood Pl', 'Portland', 'United States', 'active', '2024-04-18 15:50:00+00');

-- ---------------------------------------------------------------------------
-- 2. Insert Products (12 items across Tech & Accessories)
-- ---------------------------------------------------------------------------
INSERT INTO products (sku, name, category, price, cost_price, stock_quantity, is_active, created_at)
VALUES
    ('LAP-PRO-15', 'Apex Pro Laptop 15"', 'Computers', 1299.99, 900.00, 25, TRUE, '2024-01-01 00:00:00+00'),
    ('LAP-AIR-13', 'Apex Air Laptop 13"', 'Computers', 999.50, 700.00, 40, TRUE, '2024-01-01 00:00:00+00'),
    ('PHN-X1', 'NovaPhone X1 256GB', 'Smartphones', 849.00, 550.00, 60, TRUE, '2024-01-05 00:00:00+00'),
    ('PHN-MINI', 'NovaPhone Mini 128GB', 'Smartphones', 599.00, 380.00, 35, TRUE, '2024-01-05 00:00:00+00'),
    ('TAB-PRO-11', 'UltraTab Pro 11"', 'Tablets', 649.99, 420.00, 30, TRUE, '2024-01-08 00:00:00+00'),
    ('AUD-ANC-01', 'SonicBlast ANC Headphones', 'Audio', 199.99, 95.00, 80, TRUE, '2024-01-10 00:00:00+00'),
    ('AUD-EAR-02', 'SonicBuds Wireless Earphones', 'Audio', 89.99, 35.00, 150, TRUE, '2024-01-10 00:00:00+00'),
    ('ACC-KB-MEC', 'Mechanical RGB Keyboard', 'Accessories', 119.50, 60.00, 75, TRUE, '2024-01-12 00:00:00+00'),
    ('ACC-MS-ERG', 'Ergonomic Wireless Mouse', 'Accessories', 49.99, 22.00, 110, TRUE, '2024-01-12 00:00:00+00'),
    ('MON-4K-27', 'UltraView 27" 4K Monitor', 'Monitors', 379.00, 240.00, 20, TRUE, '2024-01-15 00:00:00+00'),
    ('ACC-USB-HUB', '7-in-1 USB-C Multiport Hub', 'Accessories', 39.99, 15.00, 200, TRUE, '2024-01-15 00:00:00+00'),
    ('ACC-CHG-65W', '65W GaN Fast Wall Charger', 'Accessories', 29.99, 11.00, 0, FALSE, '2024-01-15 00:00:00+00');

-- ---------------------------------------------------------------------------
-- 3. Insert Orders (10 orders showing various statuses and totals)
-- Note: Customer 9 (Ian) and 10 (Julia) have NO orders intentionally for LEFT JOIN tests.
-- ---------------------------------------------------------------------------
INSERT INTO orders (customer_id, order_date, status, shipping_address, total_amount)
VALUES
    (1, '2024-02-01 10:30:00+00', 'completed', '124 Market St, San Francisco, CA', 1499.98),
    (1, '2024-03-10 16:15:00+00', 'completed', '124 Market St, San Francisco, CA', 89.99),
    (2, '2024-02-15 11:00:00+00', 'completed', '456 Elm Ave, Austin, TX', 849.00),
    (3, '2024-02-28 14:00:00+00', 'completed', '789 Oak Blvd, Seattle, WA', 1169.49),
    (4, '2024-03-01 09:45:00+00', 'processing', '321 Pine Rd, Chicago, IL', 649.99),
    (5, '2024-03-15 13:20:00+00', 'cancelled', '654 Maple Dr, New York, NY', 999.50),
    (6, '2024-03-20 17:00:00+00', 'completed', '987 Cedar Ln, Boston, MA', 249.98),
    (7, '2024-04-01 10:10:00+00', 'pending', '159 Spruce Way, Denver, CO', 379.00),
    (8, '2024-04-05 15:30:00+00', 'completed', '753 Willow Ct, San Diego, CA', 1339.98),
    (2, '2024-04-12 18:00:00+00', 'processing', '456 Elm Ave, Austin, TX', 169.49);

-- ---------------------------------------------------------------------------
-- 4. Insert Order Items (Items mapping into each order)
-- ---------------------------------------------------------------------------
INSERT INTO order_items (order_id, product_id, quantity, unit_price)
VALUES
    -- Order 1: Alice bought Laptop 15" and SonicBlast Headphones
    (1, 1, 1, 1299.99),
    (1, 6, 1, 199.99),

    -- Order 2: Alice bought SonicBuds
    (2, 7, 1, 89.99),

    -- Order 3: Bob bought NovaPhone X1
    (3, 3, 1, 849.00),

    -- Order 4: Charlie bought Laptop 13" and Mechanical Keyboard
    (4, 2, 1, 999.50),
    (4, 8, 1, 119.50),
    (4, 11, 1, 39.99), -- (Remaining: rounded/discounted total 1169.49)

    -- Order 5: Diana bought UltraTab Pro 11"
    (5, 5, 1, 649.99),

    -- Order 6: Evan tried to buy Laptop 13" (Cancelled)
    (6, 2, 1, 999.50),

    -- Order 7: Fiona bought ANC Headphones and Mouse
    (7, 6, 1, 199.99),
    (7, 9, 1, 49.99),

    -- Order 8: George ordered 4K Monitor
    (8, 10, 1, 379.00),

    -- Order 9: Hannah bought Laptop 15" and USB Hub
    (9, 1, 1, 1299.99),
    (9, 11, 1, 39.99),

    -- Order 10: Bob bought Keyboard and Mouse
    (10, 8, 1, 119.50),
    (10, 9, 1, 49.99);

-- Update order totals to accurately match calculated subtotal sums
UPDATE orders o
SET total_amount = sub.sum_total
FROM (
    SELECT order_id, SUM(subtotal) AS sum_total
    FROM order_items
    GROUP BY order_id
) sub
WHERE o.order_id = sub.order_id;
