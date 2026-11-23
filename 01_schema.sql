-- =============================================================================
-- Project: E-Commerce Store & Order Management Database (PostgreSQL)
-- Session 4 - Assignment: AI-Assisted PostgreSQL Database Project
-- File: 01_schema.sql
-- Description: DDL script creating 4 related tables with PK, FK, and Constraints
-- =============================================================================

-- 1. Drop existing tables if they exist (clean setup in reverse dependency order)
DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS customers CASCADE;

-- -----------------------------------------------------------------------------
-- Table 1: customers
-- Description: Stores customer profile details and contact information
-- -----------------------------------------------------------------------------
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

    -- Constraints
    CONSTRAINT chk_customer_email_format 
        CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    CONSTRAINT chk_customer_name_length 
        CHECK (LENGTH(TRIM(first_name)) >= 2 AND LENGTH(TRIM(last_name)) >= 2)
);

-- -----------------------------------------------------------------------------
-- Table 2: products
-- Description: Stores item catalog, inventory stock levels, and unit pricing
-- -----------------------------------------------------------------------------
CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    product_name VARCHAR(120) NOT NULL,
    category VARCHAR(50) NOT NULL,
    unit_price NUMERIC(10, 2) NOT NULL,
    stock_quantity INTEGER NOT NULL DEFAULT 0,
    sku VARCHAR(30) NOT NULL UNIQUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    -- Constraints
    CONSTRAINT chk_product_price_positive 
        CHECK (unit_price > 0),
    CONSTRAINT chk_product_stock_non_negative 
        CHECK (stock_quantity >= 0),
    CONSTRAINT chk_product_category 
        CHECK (category IN ('Electronics', 'Fitness', 'Accessories', 'Nutrition', 'Books'))
);

-- -----------------------------------------------------------------------------
-- Table 3: orders
-- Description: Tracks customer purchase transactions, fulfillment statuses, and totals
-- -----------------------------------------------------------------------------
CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    customer_id INTEGER NOT NULL,
    order_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    shipping_city VARCHAR(50) NOT NULL,
    total_amount NUMERIC(10, 2) NOT NULL DEFAULT 0.00,

    -- Foreign Key Constraint (RESTRICT deletes if customer has existing orders)
    CONSTRAINT fk_orders_customer 
        FOREIGN KEY (customer_id) 
        REFERENCES customers(customer_id) 
        ON DELETE RESTRICT 
        ON UPDATE CASCADE,

    -- Constraints
    CONSTRAINT chk_order_status 
        CHECK (status IN ('PENDING', 'PROCESSING', 'SHIPPED', 'DELIVERED', 'CANCELLED')),
    CONSTRAINT chk_order_total_non_negative 
        CHECK (total_amount >= 0)
);

-- -----------------------------------------------------------------------------
-- Table 4: order_items (Junction Table)
-- Description: Line items per order linking orders to products with historical pricing
-- -----------------------------------------------------------------------------
CREATE TABLE order_items (
    order_item_id SERIAL PRIMARY KEY,
    order_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    quantity INTEGER NOT NULL,
    unit_price NUMERIC(10, 2) NOT NULL,
    subtotal NUMERIC(10, 2) GENERATED ALWAYS AS (quantity * unit_price) STORED,

    -- Foreign Key Constraints
    -- When an order is deleted, cascade deletion to its line items
    CONSTRAINT fk_order_items_order 
        FOREIGN KEY (order_id) 
        REFERENCES orders(order_id) 
        ON DELETE CASCADE 
        ON UPDATE CASCADE,

    -- Prevent product deletion if it exists in historical order records
    CONSTRAINT fk_order_items_product 
        FOREIGN KEY (product_id) 
        REFERENCES products(product_id) 
        ON DELETE RESTRICT 
        ON UPDATE CASCADE,

    -- Unique composite constraint: a product can only appear once per order
    CONSTRAINT uq_order_product 
        UNIQUE (order_id, product_id),

    -- Check constraints
    CONSTRAINT chk_order_item_quantity_positive 
        CHECK (quantity > 0),
    CONSTRAINT chk_order_item_price_positive 
        CHECK (unit_price > 0)
);

-- Comments on Tables for Documentation
COMMENT ON TABLE customers IS 'Stores customer personal records, credentials, and location';
COMMENT ON TABLE products IS 'Product inventory catalog with pricing and stock levels';
COMMENT ON TABLE orders IS 'Customer orders header with status tracking and total calculation';
COMMENT ON TABLE order_items IS 'Detailed order line items with product quantity and locked purchase price';
