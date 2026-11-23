-- =============================================================================
-- Project: E-Commerce Store & Order Management Database (PostgreSQL)
-- Session 4 - Assignment: AI-Assisted PostgreSQL Database Project
-- File: 03_crud_operations.sql
-- Description: Demonstrates complete CRUD (Create, Read, Update, Delete) operations
-- =============================================================================

-- =============================================================================
-- 1. CREATE (INSERT) Operations
-- =============================================================================

-- 1.1 Insert a single new customer
INSERT INTO customers (first_name, last_name, email, phone, city, country)
VALUES ('Tariq', 'Al-Amri', 'tariq.amri@example.com', '+966509998877', 'Riyadh', 'Saudi Arabia')
RETURNING customer_id, first_name, last_name, email, created_at;

-- 1.2 Insert multiple new products in a single statement
INSERT INTO products (product_name, category, unit_price, stock_quantity, sku)
VALUES 
('Ergonomic Gym Gloves', 'Accessories', 65.00, 80, 'ACC-GLV-001'),
('Pre-Workout Energy Formula', 'Nutrition', 190.00, 50, 'NUT-PREW-001')
RETURNING product_id, product_name, unit_price, stock_quantity;

-- =============================================================================
-- 2. READ (SELECT) Operations
-- =============================================================================

-- 2.1 Basic SELECT with filtering and sorting
-- Find all active customers living in Riyadh or Jeddah, ordered by last name
SELECT customer_id, first_name, last_name, email, city
FROM customers
WHERE is_active = TRUE AND city IN ('Riyadh', 'Jeddah')
ORDER BY last_name ASC;

-- 2.2 Range filtering & Pattern matching
-- Find products priced between 100 and 500 SAR that contain 'Fit' or 'Pro'
SELECT product_id, product_name, category, unit_price, stock_quantity
FROM products
WHERE unit_price BETWEEN 100.00 AND 500.00
  AND (product_name ILIKE '%fit%' OR product_name ILIKE '%pro%')
ORDER BY unit_price DESC;

-- 2.3 Status and Date filtering
-- Retrieve recent orders placed within the last 7 days that are not cancelled
SELECT order_id, customer_id, order_date, status, total_amount
FROM orders
WHERE status != 'CANCELLED'
  AND order_date >= CURRENT_TIMESTAMP - INTERVAL '7 days'
ORDER BY order_date DESC;

-- =============================================================================
-- 3. UPDATE Operations
-- =============================================================================

-- 3.1 Simple UPDATE
-- Update customer contact information
UPDATE customers
SET phone = '+966509998811',
    city = 'Khobar'
WHERE email = 'tariq.amri@example.com'
RETURNING customer_id, first_name, last_name, phone, city;

-- 3.2 Conditional stock replenishment UPDATE
-- Restock products that have stock quantity under 35 items by adding 25 units
UPDATE products
SET stock_quantity = stock_quantity + 25
WHERE stock_quantity < 35
RETURNING product_id, product_name, stock_quantity;

-- 3.3 UPDATE using subquery
-- Mark orders as 'DELIVERED' if they were 'SHIPPED' more than 3 days ago
UPDATE orders
SET status = 'DELIVERED'
WHERE status = 'SHIPPED'
  AND order_date < CURRENT_TIMESTAMP - INTERVAL '3 days'
RETURNING order_id, customer_id, status, order_date;

-- =============================================================================
-- 4. DELETE Operations
-- =============================================================================

-- 4.1 Safe DELETE of a cancelled order
-- Note: ON DELETE CASCADE will automatically delete corresponding order_items
DELETE FROM orders
WHERE status = 'CANCELLED' AND order_id = 10
RETURNING order_id, customer_id, status;

-- 4.2 Delete inactive customer without orders
-- This will succeed because customer 9 has no orders
DELETE FROM customers
WHERE customer_id = 9 AND is_active = FALSE
RETURNING customer_id, first_name, last_name, email;

-- 4.3 Demonstration of Foreign Key Protection:
-- Attempting to delete a customer who has orders will be rejected by PostgreSQL:
-- DELETE FROM customers WHERE customer_id = 1;
-- ERROR: update or delete on table "customers" violates foreign key constraint "fk_orders_customer" on table "orders"
