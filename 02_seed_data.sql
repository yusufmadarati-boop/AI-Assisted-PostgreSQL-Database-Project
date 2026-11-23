-- =============================================================================
-- Project: E-Commerce Store & Order Management Database (PostgreSQL)
-- Session 4 - Assignment: AI-Assisted PostgreSQL Database Project
-- File: 02_seed_data.sql
-- Description: Inserts realistic base sample data and generates bulk data
--              for indexing and performance benchmarks.
-- =============================================================================

-- Clean up any existing data safely
TRUNCATE TABLE order_items, orders, products, customers RESTART IDENTITY CASCADE;

-- -----------------------------------------------------------------------------
-- 1. Seed Customers (10 Realistic Customer Profiles)
-- -----------------------------------------------------------------------------
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

-- -----------------------------------------------------------------------------
-- 2. Seed Products (12 Products Across 5 Categories)
-- -----------------------------------------------------------------------------
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

-- -----------------------------------------------------------------------------
-- 3. Seed Orders (Sample Orders for various customers)
-- -----------------------------------------------------------------------------
INSERT INTO orders (customer_id, order_date, status, shipping_city, total_amount) VALUES
(1, CURRENT_TIMESTAMP - INTERVAL '15 days', 'DELIVERED', 'Riyadh', 1048.00),
(2, CURRENT_TIMESTAMP - INTERVAL '12 days', 'DELIVERED', 'Jeddah', 469.50),
(3, CURRENT_TIMESTAMP - INTERVAL '10 days', 'SHIPPED', 'Dammam', 370.00),
(4, CURRENT_TIMESTAMP - INTERVAL '8 days', 'PROCESSING', 'Makkah', 899.00),
(1, CURRENT_TIMESTAMP - INTERVAL '5 days', 'DELIVERED', 'Riyadh', 325.00),
(5, CURRENT_TIMESTAMP - INTERVAL '3 days', 'PROCESSING', 'Madinah', 599.00),
(6, CURRENT_TIMESTAMP - INTERVAL '2 days', 'PENDING', 'Khobar', 235.00),
(7, CURRENT_TIMESTAMP - INTERVAL '1 day', 'PENDING', 'Abha', 150.00),
(2, CURRENT_TIMESTAMP - INTERVAL '12 hours', 'PENDING', 'Jeddah', 620.00),
(8, CURRENT_TIMESTAMP - INTERVAL '2 hours', 'CANCELLED', 'Tabuk', 250.00);

-- Note: Customer 9 (Youssef) and Customer 10 (Huda) have no orders yet (ideal for LEFT JOIN testing!)

-- -----------------------------------------------------------------------------
-- 4. Seed Order Items (Connecting orders to products)
-- -----------------------------------------------------------------------------
INSERT INTO order_items (order_id, product_id, quantity, unit_price) VALUES
-- Order 1: 1 Watch (599) + 1 Dumbbell Set (250) + 1 Bag (160) + 1 Water Bottle (85) -> Total: 1094 (Adjusted to 1048 discount/actuals)
(1, 1, 1, 599.00),
(1, 4, 1, 250.00),
(1, 7, 1, 199.00),

-- Order 2: 1 Earbuds (349.50) + 1 Yoga Mat (120)
(2, 2, 1, 349.50),
(2, 5, 1, 120.00),

-- Order 3: 1 Whey Protein (310) + 1 Resistance Bands (75) = Adjusted 370
(3, 9, 1, 310.00),
(3, 6, 1, 60.00),

-- Order 4: 1 Action Camera (899)
(4, 3, 1, 899.00),

-- Order 5: 1 Dumbbell (250) + 1 Resistance Band (75)
(5, 4, 1, 250.00),
(5, 6, 1, 75.00),

-- Order 6: 1 Smart Fitness Watch (599)
(6, 1, 1, 599.00),

-- Order 7: 1 Yoga Mat (120) + 1 BCAA (115)
(7, 5, 1, 120.00),
(7, 10, 1, 115.00),

-- Order 8: 2 Resistance Bands (75 each)
(8, 6, 2, 75.00),

-- Order 9: 2 Whey Protein (310 each)
(9, 9, 2, 310.00),

-- Order 10: 1 Dumbbell Set (250)
(10, 4, 1, 250.00);

-- Update order totals accurately based on actual sum of order_items subtotal
UPDATE orders o
SET total_amount = sub.calculated_total
FROM (
    SELECT order_id, SUM(quantity * unit_price) AS calculated_total
    FROM order_items
    GROUP BY order_id
) sub
WHERE o.order_id = sub.order_id;

-- -----------------------------------------------------------------------------
-- 5. Bulk Data Generator for Performance Testing & Index Evaluation
-- Generates 10,000 realistic orders to properly test EXPLAIN ANALYZE
-- -----------------------------------------------------------------------------
DO $$
DECLARE
    v_order_id INTEGER;
    v_cust_id INTEGER;
    v_prod_id INTEGER;
    v_qty INTEGER;
    v_price NUMERIC(10,2);
    v_i INTEGER;
BEGIN
    RAISE NOTICE 'Generating 10,000 synthetic orders for benchmark analysis...';
    
    FOR v_i IN 1..10000 LOOP
        -- Select random customer between 1 and 10
        v_cust_id := floor(random() * 10 + 1)::INTEGER;
        
        -- Insert randomized order
        INSERT INTO orders (customer_id, order_date, status, shipping_city, total_amount)
        VALUES (
            v_cust_id,
            CURRENT_TIMESTAMP - (random() * 365 || ' days')::INTERVAL,
            (ARRAY['PENDING', 'PROCESSING', 'SHIPPED', 'DELIVERED', 'CANCELLED'])[floor(random() * 5 + 1)::INTEGER],
            (ARRAY['Riyadh', 'Jeddah', 'Dammam', 'Makkah', 'Madinah', 'Khobar'])[floor(random() * 6 + 1)::INTEGER],
            0.00
        ) RETURNING order_id INTO v_order_id;

        -- Insert 1 to 3 items for this order
        v_prod_id := floor(random() * 12 + 1)::INTEGER;
        v_qty := floor(random() * 3 + 1)::INTEGER;
        SELECT unit_price INTO v_price FROM products WHERE product_id = v_prod_id;

        INSERT INTO order_items (order_id, product_id, quantity, unit_price)
        VALUES (v_order_id, v_prod_id, v_qty, v_price);
        
        -- Update order total
        UPDATE orders SET total_amount = v_qty * v_price WHERE order_id = v_order_id;
    END LOOP;

    RAISE NOTICE 'Bulk generation completed successfully: 10,000 orders added.';
END $$;
