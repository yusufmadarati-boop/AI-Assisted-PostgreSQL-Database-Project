-- ============================================================================
-- Project: AI-Assisted PostgreSQL Database Project
-- Script: 06_benchmark_data.sql
-- Description: Generates 50,000+ orders and 100,000+ items using generate_series()
--              specifically designed for EXPLAIN ANALYZE benchmarking.
-- ============================================================================

-- Function / Procedural block to populate high-volume benchmark data
DO $$
DECLARE
    v_customer_count INT;
    v_product_count INT;
BEGIN
    SELECT COUNT(*) INTO v_customer_count FROM customers;
    SELECT COUNT(*) INTO v_product_count FROM products;

    RAISE NOTICE 'Starting benchmark data generation...';

    -- 1. Generate 2,000 additional customers if needed
    INSERT INTO customers (first_name, last_name, email, phone, address, city, country, status, created_at)
    SELECT
        'Customer_' || i,
        'LastName_' || i,
        'customer_' || i || '@benchmark.test',
        '+1-555-' || LPAD(i::text, 4, '0'),
        i || ' Synthetic Road',
        (ARRAY['New York', 'Los Angeles', 'Chicago', 'Houston', 'Phoenix', 'Philadelphia', 'San Antonio'])[1 + (i % 7)],
        'United States',
        (ARRAY['active', 'active', 'active', 'inactive', 'suspended'])[1 + (i % 5)],
        NOW() - (i || ' hours')::interval
    FROM generate_series(11, 2010) AS i
    ON CONFLICT (email) DO NOTHING;

    -- Refresh customer count
    SELECT COUNT(*) INTO v_customer_count FROM customers;

    -- 2. Generate 30,000 orders
    INSERT INTO orders (customer_id, order_date, status, shipping_address, total_amount)
    SELECT
        1 + (i % v_customer_count),
        NOW() - ((i % 365) || ' days')::interval - ((i % 24) || ' hours')::interval,
        (ARRAY['completed', 'completed', 'processing', 'pending', 'cancelled'])[1 + (i % 5)],
        (i % 1000) || ' Delivery Avenue, Suite ' || (i % 50),
        ROUND((50 + (i % 1500) + ((i % 99) * 0.01))::numeric, 2)
    FROM generate_series(11, 30010) AS i;

    -- 3. Generate 60,000 order items
    INSERT INTO order_items (order_id, product_id, quantity, unit_price)
    SELECT
        11 + (i % 30000),
        1 + (i % v_product_count),
        1 + (i % 4),
        ROUND((20 + (i % 200) + 0.99)::numeric, 2)
    FROM generate_series(1, 60000) AS i
    ON CONFLICT (order_id, product_id) DO UPDATE 
        SET quantity = order_items.quantity + 1;

    RAISE NOTICE 'Benchmark data generation completed successfully!';
END $$;

-- Analyze tables to refresh planner statistics
ANALYZE customers;
ANALYZE products;
ANALYZE orders;
ANALYZE order_items;
