-- ============================================================================
-- Project: AI-Assisted PostgreSQL Database Project
-- Script: 01_schema.sql
-- Description: Database Schema definition for TechStore E-Commerce Platform.
-- Covers: Tables, Primary Keys, Foreign Keys, Unique & Check Constraints, Defaults.
-- ============================================================================

-- Clean up existing tables if they exist (in reverse dependency order)
DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS customers CASCADE;

-- ---------------------------------------------------------------------------
-- 1. Table: customers
-- Description: Stores customer registration, contact details, and account status.
-- ---------------------------------------------------------------------------
CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(120) NOT NULL UNIQUE,
    phone VARCHAR(25),
    address TEXT,
    city VARCHAR(50),
    country VARCHAR(50) NOT NULL DEFAULT 'United States',
    status VARCHAR(20) NOT NULL DEFAULT 'active' 
        CHECK (status IN ('active', 'inactive', 'suspended')),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Comments on table & columns for schema clarity
COMMENT ON TABLE customers IS 'Stores customer account information and operational status';
COMMENT ON COLUMN customers.email IS 'Unique customer email used for authentication and communications';
COMMENT ON COLUMN customers.status IS 'Account status: active, inactive, or suspended';

-- ---------------------------------------------------------------------------
-- 2. Table: products
-- Description: Stores catalog items, pricing, inventory stock, and status.
-- ---------------------------------------------------------------------------
CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    sku VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(150) NOT NULL,
    category VARCHAR(60) NOT NULL,
    price NUMERIC(10, 2) NOT NULL CHECK (price >= 0),
    cost_price NUMERIC(10, 2) NOT NULL CHECK (cost_price >= 0),
    stock_quantity INT NOT NULL DEFAULT 0 CHECK (stock_quantity >= 0),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_price_cost CHECK (price >= cost_price)
);

COMMENT ON TABLE products IS 'Product catalog with inventory levels and pricing structure';
COMMENT ON COLUMN products.sku IS 'Stock Keeping Unit: Unique product identifier';
COMMENT ON COLUMN products.stock_quantity IS 'Available stock units; cannot be negative';

-- ---------------------------------------------------------------------------
-- 3. Table: orders
-- Description: Stores high-level order headers linked to customers.
-- ---------------------------------------------------------------------------
CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    customer_id INT NOT NULL REFERENCES customers(customer_id) ON DELETE CASCADE,
    order_date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) NOT NULL DEFAULT 'pending' 
        CHECK (status IN ('pending', 'processing', 'completed', 'cancelled')),
    shipping_address TEXT NOT NULL,
    total_amount NUMERIC(10, 2) NOT NULL DEFAULT 0.00 CHECK (total_amount >= 0.00)
);

COMMENT ON TABLE orders IS 'Customer orders containing total transaction summary and fulfillment state';
COMMENT ON COLUMN orders.customer_id IS 'Foreign Key linking order to customer; cascades on customer deletion';

-- ---------------------------------------------------------------------------
-- 4. Table: order_items
-- Description: Stores line-item details for each order, linking to products.
-- ---------------------------------------------------------------------------
CREATE TABLE order_items (
    order_item_id SERIAL PRIMARY KEY,
    order_id INT NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,
    product_id INT NOT NULL REFERENCES products(product_id) ON DELETE RESTRICT,
    quantity INT NOT NULL CHECK (quantity > 0),
    unit_price NUMERIC(10, 2) NOT NULL CHECK (unit_price >= 0),
    subtotal NUMERIC(10, 2) GENERATED ALWAYS AS (quantity * unit_price) STORED,
    CONSTRAINT uq_order_product UNIQUE (order_id, product_id)
);

COMMENT ON TABLE order_items IS 'Line items belonging to an order with computed subtotal and quantity';
COMMENT ON COLUMN order_items.product_id IS 'Foreign Key to product; deletion restricted if referenced in orders';

-- ---------------------------------------------------------------------------
-- Summary View for Convenience
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_order_summaries AS
SELECT 
    o.order_id,
    o.order_date,
    o.status AS order_status,
    c.customer_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    c.email AS customer_email,
    COUNT(oi.order_item_id) AS items_count,
    COALESCE(SUM(oi.subtotal), 0.00) AS calculated_total,
    o.total_amount AS recorded_total
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
LEFT JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY o.order_id, o.order_date, o.status, c.customer_id, c.first_name, c.last_name, c.email, o.total_amount;
