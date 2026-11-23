# 🤖 AI Usage Documentation & Engineering Reflection

**Project:** AI-Assisted PostgreSQL Database Project  
**Domain:** TechStore E-Commerce Platform  
**Target:** Session 4 Assignment Requirements  

---

## 1. Overview of AI Integration

Artificial Intelligence was leveraged across every phase of this project to design, optimize, generate synthetic data, analyze query execution plans, and troubleshoot PostgreSQL behaviors. 

This document details:
1. The exact **prompts** used with the AI model.
2. The AI's **contributions** in architectural decisions, query design, and data generation.
3. The **evaluation and refinement** applied by human engineering judgment.
4. The **indexing performance analysis** comparing before/after execution plans with `EXPLAIN ANALYZE`.

---

## 2. Prompt Log & AI Interaction Pipeline

### Phase 1: Domain Selection & Schema Design
* **Prompt provided to AI:**
  > *"Design a normalized relational database schema (3 to 4 related tables) for an e-commerce platform in PostgreSQL. Include primary keys, foreign keys with appropriate cascade rules, check constraints, unique constraints, and sensible defaults. Justify each constraint."*
* **AI Output:**
  Suggested 4 core tables: `customers`, `products`, `orders`, and `order_items`.
* **Refinement Applied:**
  - AI initially omitted an ON DELETE RESTRICT for products. We mandated `ON DELETE RESTRICT` on `order_items.product_id` to prevent deletion of products that are historically part of completed sales.
  - Added a generated column: `subtotal NUMERIC(10, 2) GENERATED ALWAYS AS (quantity * unit_price) STORED` to guarantee data integrity without trigger overhead.
  - Added a check constraint `chk_price_cost CHECK (price >= cost_price)` to enforce business logic at the database layer.

---

### Phase 2: Realistic Sample & Benchmark Data Generation
* **Prompt provided to AI:**
  > *"Generate realistic seed data for the TechStore schema. Also provide a PL/pgSQL block using `generate_series()` to generate 30,000+ orders and 60,000+ line items to stress-test query plans with `EXPLAIN ANALYZE`."*
* **AI Output:**
  Provided `02_seed_data.sql` with real-world products and users, and `06_benchmark_data.sql` utilizing `generate_series()`, random arrays, and interval mathematics.
* **Refinement Applied:**
  - Added `ON CONFLICT (email) DO NOTHING` and `ON CONFLICT (order_id, product_id) DO UPDATE` to ensure idempotent script execution without primary/unique key collision failures.

---

### Phase 3: Query Catalog Design (CRUD, JOINs, GROUP BY, Pagination)
* **Prompt provided to AI:**
  > *"Write practical SQL queries fulfilling: 1) CRUD operations with RETURNING clause; 2) INNER and LEFT JOINs demonstrating real business use cases (including customers with zero orders); 3) Multi-table analytics using GROUP BY, SUM, AVG, and HAVING; 4) Pagination comparing traditional OFFSET/LIMIT against Keyset (cursor-based) pagination."*
* **AI Output:**
  Clean, well-commented SQL queries in `03_queries.sql`.
* **Refinement Applied:**
  - Ensured Keyset pagination used the tuple comparison `(order_date, order_id) < (:last_date, :last_id)` with deterministic sorting `ORDER BY order_date DESC, order_id DESC` to prevent skipped rows across duplicate timestamps.

---

### Phase 4: ACID Transactions & Concurrency
* **Prompt provided to AI:**
  > *"Demonstrate ACID transactions in PostgreSQL. Include a successful multi-step checkout with COMMIT, an inventory-failure scenario triggering a complete ROLLBACK, and a partial rollback using SAVEPOINT."*
* **AI Output:**
  Provided `04_transactions.sql`.
* **Refinement Applied:**
  - Incorporated `SELECT ... FOR UPDATE` row-level locking on the product table before checking and updating inventory to demonstrate concurrency safety and prevent race conditions.

---

## 3. Deep Dive: Indexing Evaluation via `EXPLAIN ANALYZE`

### 3.1 The Scenario
In an e-commerce platform with tens of thousands of orders, querying the order history of a specific customer within a given time window is a high-frequency query:

```sql
SELECT order_id, customer_id, order_date, status, total_amount
FROM orders
WHERE customer_id = 150
  AND order_date >= NOW() - INTERVAL '180 days';
```

### 3.2 Before Indexing (Baseline)
- **Table Size:** 30,000+ orders.
- **Index State:** Only primary key `orders_pkey` on `order_id` exists.

**Execution Plan (`EXPLAIN (ANALYZE, BUFFERS)`):**
```text
Seq Scan on public.orders  (cost=0.00..854.00 rows=15 width=48) (actual time=0.045..14.850 rows=14 loops=1)
  Output: order_id, customer_id, order_date, status, total_amount
  Filter: ((orders.customer_id = 150) AND (orders.order_date >= (now() - '180 days'::interval)))
  Rows Removed by Filter: 29996
  Buffers: shared hit=420 read=134
Planning Time: 0.182 ms
Execution Time: 15.021 ms
```

**Plan Analysis:**
1. **Node Type:** `Seq Scan` (Sequential Scan). PostgreSQL had to inspect every single block of the `orders` table.
2. **Efficiency:** 29,996 rows were read and discarded by the CPU filter to return only 14 matching rows.
3. **I/O:** Required reading 554 shared buffer pages (`420 hit + 134 read`).
4. **Execution Time:** ~15.02 ms.

---

### 3.3 Index Creation (The Optimization)
We introduced a composite B-Tree index:
```sql
CREATE INDEX idx_orders_customer_date ON orders (customer_id, order_date DESC);
```
- **Why Composite?** The query filters by equality on `customer_id` and range on `order_date`. A composite index allows the engine to jump directly to the customer's entries and scan only the date range.

---

### 3.4 After Indexing
**Execution Plan (`EXPLAIN (ANALYZE, BUFFERS)`):**
```text
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
```

### 3.5 Comparative Summary Table

| Metric | Before Index | After Index | Improvement Factor |
| :--- | :--- | :--- | :--- |
| **Scan Type** | `Seq Scan` | `Bitmap Index Scan` + `Bitmap Heap Scan` | Targeted B-Tree lookup |
| **Execution Time** | `15.021 ms` | `0.071 ms` | **~211x faster** |
| **Cost Estimation** | `0.00..854.00` | `4.42..38.20` | **~22x lower estimated cost** |
| **Buffer Access** | `554 buffers` | `14 buffers` | **~97.5% reduction in disk/memory I/O** |
| **Rows Discarded** | `29,996 rows` | `0 rows` | Zero unnecessary reads |

---

## 4. Key Takeaways & Reflection

1. **AI as an Accelerator:** AI dramatically reduced the time required to scaffold boilerplate SQL, generate realistic multi-column test distributions, and explain execution nodes.
2. **Need for Human Verification:** AI can propose generic indexes (e.g. single column `customer_id`), but domain engineering knowledge determined that a **composite index** `(customer_id, order_date DESC)` was necessary to eliminate sorting overhead and avoid secondary sequential filters.
3. **Database Integrity:** Relying on declarative constraints (`CHECK`, `UNIQUE`, `FOREIGN KEY ON DELETE`) ensures that application errors cannot corrupt relational integrity.
