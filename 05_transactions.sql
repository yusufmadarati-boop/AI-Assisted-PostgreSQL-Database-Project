-- =============================================================================
-- Project: E-Commerce Store & Order Management Database (PostgreSQL)
-- Session 4 - Assignment: AI-Assisted PostgreSQL Database Project
-- File: 05_transactions.sql
-- Description: Demonstrates ACID transactions using COMMIT (successful order)
--              and ROLLBACK (failure recovery due to business constraint check).
-- =============================================================================

-- =============================================================================
-- SCENARIO 1: Successful Order Placement Transaction (COMMIT)
-- =============================================================================
-- Business Flow:
-- 1. Customer 1 wants to buy:
--    - 1 unit of Product 1 ("Smart Fitness Watch Pro", Price: 599.00)
-- 2. Verify and decrement inventory stock.
-- 3. Create order record with status 'PENDING'.
-- 4. Create order line item.
-- 5. Commit all changes atomically to ensure data consistency.

-- Step 0: Check stock before transaction
SELECT product_id, product_name, stock_quantity 
FROM products 
WHERE product_id = 1;

-- START TRANSACTION
BEGIN;

    -- Step 1: Deduct product inventory stock
    UPDATE products
    SET stock_quantity = stock_quantity - 1
    WHERE product_id = 1 
      AND stock_quantity >= 1;

    -- Step 2: Insert into orders header table
    INSERT INTO orders (customer_id, order_date, status, shipping_city, total_amount)
    VALUES (1, CURRENT_TIMESTAMP, 'PENDING', 'Riyadh', 599.00);

    -- Step 3: Insert into order_items junction table (using currval of orders_order_id_seq)
    INSERT INTO order_items (order_id, product_id, quantity, unit_price)
    VALUES (currval('orders_order_id_seq'), 1, 1, 599.00);

-- Finalize and persist changes permanently
COMMIT;

-- Verification Query: Check that stock was decremented and new order exists
SELECT product_id, product_name, stock_quantity 
FROM products 
WHERE product_id = 1;

SELECT o.order_id, o.customer_id, o.status, o.total_amount, oi.product_id, oi.quantity
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_id = currval('orders_order_id_seq');


-- =============================================================================
-- SCENARIO 2: Failed Order Placement with Graceful Recovery (ROLLBACK)
-- =============================================================================
-- Business Flow:
-- 1. Customer 2 attempts to purchase 1,000 units of Product 3 ("Action Camera").
-- 2. Product 3 only has 30 units in stock.
-- 3. Stock deduction violates the CHECK constraint (stock_quantity >= 0)
--    OR application detects insufficient stock condition.
-- 4. Rollback transaction so NO partial order or inconsistent stock is saved.

-- Step 0: Verify initial stock before failure test
SELECT product_id, product_name, stock_quantity 
FROM products 
WHERE product_id = 3;

-- Record initial count of orders to verify no phantom orders are created
SELECT COUNT(*) AS total_orders_before FROM orders;

-- START TRANSACTION
BEGIN;

    -- Step 1: Create an order record
    INSERT INTO orders (customer_id, order_date, status, shipping_city, total_amount)
    VALUES (2, CURRENT_TIMESTAMP, 'PENDING', 'Jeddah', 899000.00);

    -- Step 2: Attempt to deduct 1,000 units from stock (Product only has ~30 units)
    -- This update condition fails to match sufficient stock
    UPDATE products
    SET stock_quantity = stock_quantity - 1000
    WHERE product_id = 3 AND stock_quantity >= 1000;

    -- Simulate application-level validation check:
    -- If no rows were updated, stock was insufficient, so we issue a manual ROLLBACK
    -- In PostgreSQL script demonstration:
    ROLLBACK;

-- Verification Query: Verify complete rollback
-- 1. Product stock is unchanged
SELECT product_id, product_name, stock_quantity 
FROM products 
WHERE product_id = 3;

-- 2. Total order count is unchanged (no dangling order created)
SELECT COUNT(*) AS total_orders_after FROM orders;

-- Result: ACID properties (Atomicity, Consistency, Isolation, Durability) fully preserved!
