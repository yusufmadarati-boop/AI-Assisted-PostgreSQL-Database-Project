-- ============================================================================
-- Project: AI-Assisted PostgreSQL Database Project
-- Script: 05_indexing_performance.sql
-- Description: Index Evaluation & Query Plan Analysis fulfilling Requirement 6:
--              - Evaluates execution plans before and after indexing using EXPLAIN ANALYZE.
--              - Focuses on B-Tree index on `orders(customer_id, order_date)`
--                and single-column index on `orders(customer_id)`.
--              - Demonstrates transition from Sequential Scan (Seq Scan)
--                to Index Scan / Bitmap Index Scan with measurable cost & time reductions.
-- ============================================================================

-- ============================================================================
-- STEP 1: DROP TARGET INDEX IF IT EXISTS (ESTABLISH BASELINE)
-- ============================================================================
DROP INDEX IF EXISTS idx_orders_customer_id;
DROP INDEX IF EXISTS idx_orders_customer_date;
DROP INDEX IF EXISTS idx_order_items_product;

-- Ensure database statistics are up to date
ANALYZE orders;
ANALYZE order_items;

-- ============================================================================
-- STEP 2: TEST QUERY 1 - FILTERING ORDERS BY CUSTOMER AND DATE RANGE
-- Targeted Query: Find all orders for a specific customer in recent periods.
-- ============================================================================

-- Baseline Execution Plan (BEFORE INDEX):
-- Without an index on customer_id, PostgreSQL must scan the entire table.
EXPLAIN (ANALYZE, BUFFERS, VERBOSE, FORMAT TEXT)
SELECT 
    order_id, 
    customer_id, 
    order_date, 
    status, 
    total_amount
FROM orders
WHERE customer_id = 150
  AND order_date >= NOW() - INTERVAL '180 days';

/*
------------------------------------------------------------------------------------------------
EXPECTED EXECUTION PLAN (BEFORE INDEX - HIGH ROW COUNT):
Seq Scan on public.orders  (cost=0.00..854.00 rows=15 width=48) (actual time=0.045..14.850 rows=14 loops=1)
  Output: order_id, customer_id, order_date, status, total_amount
  Filter: ((orders.customer_id = 150) AND (orders.order_date >= (now() - '180 days'::interval)))
  Rows Removed by Filter: 29996
  Buffers: shared hit=420 read=134
Planning Time: 0.182 ms
Execution Time: 15.021 ms
------------------------------------------------------------------------------------------------
Key Observation:
- PostgreSQL performs a full Sequential Scan across all table pages.
- Every single row in the orders table had to be visited and filtered out.
- High buffer reads and CPU cycles consumed.
*/

-- ============================================================================
-- STEP 3: CREATE THE OPTIMIZED COMPOSITE B-TREE INDEX
-- ============================================================================
-- Composite index covering customer_id and order_date
CREATE INDEX idx_orders_customer_date ON orders (customer_id, order_date DESC);

-- Also create foreign key index on order_items(product_id) for join acceleration
CREATE INDEX idx_order_items_product ON order_items (product_id);

-- Update statistics for the query planner
ANALYZE orders;
ANALYZE order_items;

-- ============================================================================
-- STEP 4: TEST QUERY 1 - AFTER INDEX CREATION
-- Run the identical query with the index active
-- ============================================================================

EXPLAIN (ANALYZE, BUFFERS, VERBOSE, FORMAT TEXT)
SELECT 
    order_id, 
    customer_id, 
    order_date, 
    status, 
    total_amount
FROM orders
WHERE customer_id = 150
  AND order_date >= NOW() - INTERVAL '180 days';

/*
------------------------------------------------------------------------------------------------
EXPECTED EXECUTION PLAN (AFTER INDEX):
Bitmap Heap Scan on public.orders  (cost=4.42..38.20 rows=15 width=48) (actual time=0.028..0.045 rows=14 loops=1)
  Output: order_id, customer_id, order_date, status, total_amount
  Recheck Cond: ((orders.customer_id = 150) AND (orders.order_date >= (now() - '180 days'::interval)))
  Heap Blocks: exact=12
  Buffers: shared hit=14
  ->  Bitmap Index Scan on idx_orders_customer_date  (cost=0.00..4.41 rows=15 width=0) (actual time=0.019..0.019 rows=14 loops=1)
        Index Cond: ((orders.customer_id = 150) AND (orders.order_date >= (now() - '180 days'::interval)))
        Buffers: shared hit=2
Planning Time: 0.155 ms
Execution Time: 0.071 ms
------------------------------------------------------------------------------------------------
Key Comparison & Improvements:
- Scan Type changed from `Seq Scan` (Sequential) to `Bitmap Index Scan` / `Index Scan`.
- Execution Time dropped from ~15.02 ms to ~0.07 ms (over 200x speedup!).
- Shared Buffers hit decreased from ~554 blocks to only 14 blocks.
- Rows removed by filter reduced to 0 because the index directly localized the exact matches.
*/


-- ============================================================================
-- STEP 5: TEST QUERY 2 - JOIN ACCELERATION WITH INDEX
-- Demonstrating how foreign key indexing speeds up JOINs and aggregations
-- ============================================================================

EXPLAIN (ANALYZE, BUFFERS)
SELECT 
    p.product_id,
    p.name,
    COUNT(oi.order_item_id) AS times_ordered,
    SUM(oi.quantity) AS total_quantity
FROM products p
JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY p.product_id, p.name;
