-- =============================================================================
-- Project: E-Commerce Store & Order Management Database (PostgreSQL)
-- Session 4 - Assignment: AI-Assisted PostgreSQL Database Project
-- File: 04_joins_aggregations_pagination.sql
-- Description: Demonstrates JOINs, GROUP BY, Aggregate functions, HAVING,
--              and Pagination queries.
-- =============================================================================

-- =============================================================================
-- 1. JOIN QUERIES
-- =============================================================================

-- 1.1 INNER JOIN: Get orders along with customer details
SELECT 
    o.order_id,
    o.order_date,
    o.status,
    c.customer_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    c.email,
    o.shipping_city,
    o.total_amount
FROM orders o
INNER JOIN customers c ON o.customer_id = c.customer_id
ORDER BY o.order_date DESC
LIMIT 10;

-- 1.2 LEFT JOIN: Find all customers and identify those who have NEVER placed an order
SELECT 
    c.customer_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    c.email,
    c.city,
    COUNT(o.order_id) AS total_orders_placed,
    COALESCE(SUM(o.total_amount), 0.00) AS total_money_spent
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, customer_name, c.email, c.city
ORDER BY total_orders_placed ASC, c.customer_id ASC;

-- 1.3 MULTI-TABLE JOIN (4 Tables): Complete Order Details Breakdown
-- Connects customers -> orders -> order_items -> products
SELECT 
    o.order_id,
    o.order_date,
    c.first_name || ' ' || c.last_name AS customer_name,
    p.product_name,
    p.category,
    oi.quantity,
    oi.unit_price,
    oi.subtotal
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
WHERE o.order_id = 1
ORDER BY oi.subtotal DESC;

-- =============================================================================
-- 2. GROUP BY & AGGREGATE QUERIES (COUNT, SUM, AVG, MIN, MAX, HAVING)
-- =============================================================================

-- 2.1 Order Summary by Status (Count, Total Revenue, Average Order Value)
SELECT 
    status,
    COUNT(*) AS total_orders,
    SUM(total_amount) AS total_revenue,
    ROUND(AVG(total_amount), 2) AS average_order_value,
    MIN(total_amount) AS minimum_order,
    MAX(total_amount) AS maximum_order
FROM orders
GROUP BY status
ORDER BY total_revenue DESC;

-- 2.2 Top Selling Products with Sales Volume and Revenue
SELECT 
    p.product_id,
    p.product_name,
    p.category,
    SUM(oi.quantity) AS total_units_sold,
    SUM(oi.subtotal) AS gross_sales_revenue,
    COUNT(DISTINCT oi.order_id) AS orders_count
FROM products p
JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY p.product_id, p.product_name, p.category
ORDER BY gross_sales_revenue DESC;

-- 2.3 GROUP BY with HAVING Clause:
-- High-Value Customers who have spent more than 1,000 SAR across multiple orders
SELECT 
    c.customer_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    c.email,
    COUNT(o.order_id) AS total_completed_orders,
    ROUND(SUM(o.total_amount), 2) AS lifetime_value
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
WHERE o.status != 'CANCELLED'
GROUP BY c.customer_id, customer_name, c.email
HAVING COUNT(o.order_id) >= 2 AND SUM(o.total_amount) > 1000.00
ORDER BY lifetime_value DESC;

-- 2.4 Sales Performance by Category
SELECT 
    p.category,
    COUNT(DISTINCT p.product_id) AS products_count,
    SUM(oi.quantity) AS total_items_sold,
    ROUND(SUM(oi.subtotal), 2) AS total_category_revenue,
    ROUND(AVG(oi.unit_price), 2) AS avg_item_price
FROM products p
JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY p.category
HAVING SUM(oi.quantity) > 5
ORDER BY total_category_revenue DESC;

-- =============================================================================
-- 3. PAGINATION QUERIES
-- =============================================================================

-- 3.1 Standard Offset-Based Pagination (Page 1: 5 items per page)
SELECT 
    order_id,
    customer_id,
    order_date,
    status,
    total_amount
FROM orders
ORDER BY order_date DESC, order_id DESC
LIMIT 5 OFFSET 0;

-- 3.2 Standard Offset-Based Pagination (Page 2: next 5 items)
SELECT 
    order_id,
    customer_id,
    order_date,
    status,
    total_amount
FROM orders
ORDER BY order_date DESC, order_id DESC
LIMIT 5 OFFSET 5;

-- 3.3 High-Performance Keyset (Cursor-Based) Pagination
-- Ideal for large-scale datasets; avoids the performance degradation of high OFFSET values
-- Fetch next page of orders where order_id < last_seen_order_id
SELECT 
    order_id,
    customer_id,
    order_date,
    status,
    total_amount
FROM orders
WHERE order_id < 9995  -- Cursor from previous page
ORDER BY order_id DESC
LIMIT 5;
