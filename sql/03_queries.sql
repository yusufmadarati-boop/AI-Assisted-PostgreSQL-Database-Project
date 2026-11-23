-- ============================================================================
-- Project: AI-Assisted PostgreSQL Database Project
-- Script: 03_queries.sql
-- Description: Comprehensive query catalog fulfilling Requirement 4:
--              - CRUD Operations (Create, Read, Update, Delete)
--              - JOIN Queries (INNER JOIN, LEFT JOIN, Multi-table JOIN)
--              - GROUP BY and Aggregations (with HAVING)
--              - Pagination (OFFSET/LIMIT and Keyset Cursor Pagination)
-- ============================================================================

-- ============================================================================
-- SECTION 1: CRUD OPERATIONS
-- ============================================================================

-- 1.1 CREATE (INSERT)
-- Insert a new customer record
INSERT INTO customers (first_name, last_name, email, phone, address, city, country, status)
VALUES ('Michael', 'Scott', 'm.scott@dundermifflin.com', '+1-555-0199', '1725 Slough Ave', 'Scranton', 'United States', 'active')
RETURNING customer_id, first_name, last_name, email, created_at;

-- Insert a new product record
INSERT INTO products (sku, name, category, price, cost_price, stock_quantity, is_active)
VALUES ('ACC-WEBCAM-4K', 'UltraClear 4K Pro Webcam', 'Accessories', 149.99, 75.00, 45, TRUE)
RETURNING product_id, sku, name, price, stock_quantity;

-- 1.2 READ (SELECT)
-- Retrieve active products in the 'Accessories' category priced below $100
SELECT product_id, sku, name, price, stock_quantity
FROM products
WHERE category = 'Accessories' 
  AND is_active = TRUE 
  AND price < 100.00
ORDER BY price ASC;

-- Retrieve customer profile by email
SELECT customer_id, first_name, last_name, email, city, status, created_at
FROM customers
WHERE email = 'alice.johnson@example.com';

-- 1.3 UPDATE
-- Update stock quantity after an inventory restock
UPDATE products
SET stock_quantity = stock_quantity + 20
WHERE sku = 'ACC-USB-HUB'
RETURNING product_id, sku, name, stock_quantity;

-- Change customer status and phone
UPDATE customers
SET status = 'active', phone = '+1-555-0190'
WHERE email = 'evan.wright@example.com'
RETURNING customer_id, email, status, phone;

-- 1.4 DELETE
-- Create temporary test customer and safely delete them to demonstrate DELETE
INSERT INTO customers (first_name, last_name, email, status)
VALUES ('Temp', 'User', 'temp.user@example.com', 'inactive');

DELETE FROM customers
WHERE email = 'temp.user@example.com'
RETURNING customer_id, email;


-- ============================================================================
-- SECTION 2: JOIN QUERIES
-- ============================================================================

-- 2.1 INNER JOIN: Get orders with customer details
SELECT 
    o.order_id,
    o.order_date,
    o.status AS order_status,
    o.total_amount,
    c.customer_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    c.email AS customer_email
FROM orders o
INNER JOIN customers c ON o.customer_id = c.customer_id
WHERE o.status = 'completed'
ORDER BY o.order_date DESC;

-- 2.2 LEFT JOIN: List ALL customers and their order counts (including 0 orders)
-- This proves why LEFT JOIN is vital (captures Ian Malcolm and Julia Roberts who have no orders yet)
SELECT 
    c.customer_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    c.email,
    c.city,
    COUNT(o.order_id) AS total_orders,
    COALESCE(SUM(o.total_amount), 0.00) AS total_spent
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name, c.email, c.city
ORDER BY total_spent DESC, total_orders DESC;

-- 2.3 MULTI-TABLE JOIN (4 Tables): Detailed Order Invoice Breakdown
-- Joins customers -> orders -> order_items -> products
SELECT 
    o.order_id,
    o.order_date,
    c.first_name || ' ' || c.last_name AS customer_name,
    c.email,
    p.name AS product_name,
    p.category AS product_category,
    oi.quantity,
    oi.unit_price,
    oi.subtotal,
    o.total_amount AS order_grand_total
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
WHERE o.order_id = 4
ORDER BY oi.order_item_id;


-- ============================================================================
-- SECTION 3: GROUP BY & AGGREGATIONS
-- ============================================================================

-- 3.1 Product Performance Analytics: Sales volume, revenue & profit margin per category
SELECT 
    p.category,
    COUNT(DISTINCT p.product_id) AS distinct_products_offered,
    COALESCE(SUM(oi.quantity), 0) AS total_units_sold,
    COALESCE(SUM(oi.subtotal), 0.00) AS total_revenue,
    COALESCE(ROUND(AVG(oi.unit_price), 2), 0.00) AS avg_selling_price
FROM products p
LEFT JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY p.category
ORDER BY total_revenue DESC;

-- 3.2 High-Value Customers (GROUP BY with HAVING clause)
-- Find customers who have completed orders totaling over $1,000
SELECT 
    c.customer_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    c.email,
    COUNT(o.order_id) AS completed_orders_count,
    SUM(o.total_amount) AS total_lifetime_spend,
    ROUND(AVG(o.total_amount), 2) AS average_order_value
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
WHERE o.status = 'completed'
GROUP BY c.customer_id, c.first_name, c.last_name, c.email
HAVING SUM(o.total_amount) >= 1000.00
ORDER BY total_lifetime_spend DESC;

-- 3.3 Best-Selling Products Rank
SELECT 
    p.product_id,
    p.sku,
    p.name,
    p.category,
    SUM(oi.quantity) AS total_quantity_sold,
    SUM(oi.subtotal) AS gross_sales
FROM products p
JOIN order_items oi ON p.product_id = oi.product_id
JOIN orders o ON oi.order_id = o.order_id
WHERE o.status != 'cancelled'
GROUP BY p.product_id, p.sku, p.name, p.category
ORDER BY total_quantity_sold DESC, gross_sales DESC;


-- ============================================================================
-- SECTION 4: PAGINATION QUERIES
-- ============================================================================

-- 4.1 Traditional Offset Pagination (Page 1: 5 items per page)
SELECT 
    product_id,
    sku,
    name,
    category,
    price,
    stock_quantity
FROM products
WHERE is_active = TRUE
ORDER BY product_id ASC
LIMIT 5 OFFSET 0;

-- Traditional Offset Pagination (Page 2: 5 items per page)
SELECT 
    product_id,
    sku,
    name,
    category,
    price,
    stock_quantity
FROM products
WHERE is_active = TRUE
ORDER BY product_id ASC
LIMIT 5 OFFSET 5;

-- 4.2 Keyset (Cursor-Based) Pagination
-- Ideal for high performance on large datasets; avoids O(N) scanning of OFFSET
-- First Fetch (Page 1)
SELECT 
    order_id,
    order_date,
    total_amount,
    status
FROM orders
ORDER BY order_date DESC, order_id DESC
LIMIT 5;

-- Next Fetch (Page 2 using cursor values from last row of page 1: e.g. date '2024-03-15', id 6)
SELECT 
    order_id,
    order_date,
    total_amount,
    status
FROM orders
WHERE (order_date, order_id) < ('2024-03-15 13:20:00+00', 6)
ORDER BY order_date DESC, order_id DESC
LIMIT 5;
