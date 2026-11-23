-- ============================================================================
-- Project: AI-Assisted PostgreSQL Database Project
-- Script: 04_transactions.sql
-- Description: Demonstrates ACID Transaction management fulfilling Requirement 5:
--              - Transaction 1: Successful checkout with COMMIT
--              - Transaction 2: Handled failure scenario with ROLLBACK
--              - Transaction 3: Advanced partial rollback using SAVEPOINT
-- ============================================================================

-- ============================================================================
-- SCENARIO 1: SUCCESSFUL ORDER TRANSACTION (COMMIT)
-- Business Flow:
-- 1. Begin transaction.
-- 2. Verify product inventory availability.
-- 3. Create new order record for Customer 1 (Alice).
-- 4. Add items to order_items.
-- 5. Deduct inventory stock quantity.
-- 6. Recalculate order total amount.
-- 7. COMMIT the transaction permanently.
-- ============================================================================

BEGIN;

-- Step 1: Check and reserve product stock (Pencil in Product 9: Ergonomic Wireless Mouse)
SELECT product_id, name, stock_quantity, price
FROM products
WHERE product_id = 9
FOR UPDATE; -- Row-level lock to prevent race conditions during concurrent checkouts

-- Step 2: Insert the order header
INSERT INTO orders (customer_id, order_date, status, shipping_address, total_amount)
VALUES (1, CURRENT_TIMESTAMP, 'processing', '124 Market St, San Francisco, CA', 49.99);

-- Step 3: Insert order items referencing currval of the order sequence
INSERT INTO order_items (order_id, product_id, quantity, unit_price)
VALUES (
    currval(pg_get_serial_sequence('orders', 'order_id')),
    9,
    1,
    49.99
);

-- Step 4: Decrement the stock in products table
UPDATE products
SET stock_quantity = stock_quantity - 1
WHERE product_id = 9;

-- Step 5: Update the order total from actual inserted items
UPDATE orders
SET total_amount = (
    SELECT COALESCE(SUM(subtotal), 0)
    FROM order_items
    WHERE order_id = currval(pg_get_serial_sequence('orders', 'order_id'))
)
WHERE order_id = currval(pg_get_serial_sequence('orders', 'order_id'));

-- Step 6: Commit all changes safely
COMMIT;

-- Verify the commit succeeded:
SELECT o.order_id, o.customer_id, o.status, o.total_amount, p.name, p.stock_quantity
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
WHERE o.order_id = (SELECT MAX(order_id) FROM orders);


-- ============================================================================
-- SCENARIO 2: FAILED ORDER TRANSACTION WITH ROLLBACK
-- Business Flow:
-- 1. Begin transaction.
-- 2. Attempt to purchase more units than available (e.g. 50 units of product with only 20 in stock).
-- 3. Detect stock constraint or business violation.
-- 4. Execute ROLLBACK to ensure zero dirty reads or partial writes.
-- ============================================================================

BEGIN;

-- Step 1: Insert an order for customer 3
INSERT INTO orders (customer_id, order_date, status, shipping_address, total_amount)
VALUES (3, CURRENT_TIMESTAMP, 'pending', '789 Oak Blvd, Seattle, WA', 18950.00);

-- Step 2: Attempt to deduct 50 units from product 10 (UltraView Monitor has only 20 units)
-- In a real application or trigger, if stock_quantity < requested, or if CHECK constraint fails:
UPDATE products
SET stock_quantity = stock_quantity - 50
WHERE product_id = 10 AND stock_quantity >= 50;

-- Verification check in transaction: No rows affected because check condition failed!
-- Therefore, application aborts and rolls back:
ROLLBACK;

-- Verify rollback: Confirm no orphaned order was created for Customer 3
SELECT * FROM orders WHERE customer_id = 3 AND status = 'pending';
-- Confirm product 10 stock remained unchanged
SELECT product_id, name, stock_quantity FROM products WHERE product_id = 10;


-- ============================================================================
-- SCENARIO 3: PARTIAL ROLLBACK USING SAVEPOINTS
-- Business Flow:
-- 1. Customer orders multiple items.
-- 2. Main item is successfully added.
-- 3. A promotional optional item fails availability check.
-- 4. Rollback only to SAVEPOINT without aborting the primary order.
-- ============================================================================

BEGIN;

-- 1. Create order
INSERT INTO orders (customer_id, order_date, status, shipping_address, total_amount)
VALUES (2, CURRENT_TIMESTAMP, 'processing', '456 Elm Ave, Austin, TX', 0.00);

-- 2. Add primary item (Product 7: SonicBuds)
INSERT INTO order_items (order_id, product_id, quantity, unit_price)
VALUES (currval(pg_get_serial_sequence('orders', 'order_id')), 7, 1, 89.99);

UPDATE products
SET stock_quantity = stock_quantity - 1
WHERE product_id = 7;

-- Set a checkpoint
SAVEPOINT after_primary_item;

-- 3. Attempt to add an out-of-stock promotional item (Product 12: 65W Fast Wall Charger has 0 stock)
-- Trying to insert 1 unit, but stock check fails
-- Simulate error recovery:
ROLLBACK TO SAVEPOINT after_primary_item;

-- 4. Complete the order with just the primary item
UPDATE orders
SET total_amount = (
    SELECT SUM(subtotal)
    FROM order_items
    WHERE order_id = currval(pg_get_serial_sequence('orders', 'order_id'))
)
WHERE order_id = currval(pg_get_serial_sequence('orders', 'order_id'));

COMMIT;
