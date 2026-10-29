-- =====================================================================
-- 04 · Latest record per key (deduplication)
-- Session 2 · Week 1   ·   used constantly in dbt staging models
-- =====================================================================
-- RECIPE
--   ROW_NUMBER() OVER (PARTITION BY <key> ORDER BY <date> DESC, <unique id> DESC)
--   then keep row_num = 1.
--
-- WHY ROW_NUMBER: you need EXACTLY one row per key.
-- WHY THE TIEBREAKER: two rows can share the same timestamp. Without a unique
--   tiebreaker the database picks one arbitrarily, so the result can change
--   between runs with the same data (non-deterministic) -> a classic dbt bug.


-- ---------------------------------------------------------------------
-- PATTERN:  latest per key
-- QUESTION: Latest payment for each customer (my Session 2, ex 2).
-- CHECK:    row count must equal SELECT COUNT(DISTINCT customer_id) FROM payment
-- ---------------------------------------------------------------------
WITH ranked_payments AS (
    SELECT customer_id, payment_id, payment_date, amount,
           ROW_NUMBER() OVER (PARTITION BY customer_id
                              ORDER BY payment_date DESC, payment_id DESC) AS row_num
    FROM payment
)
SELECT customer_id, payment_id, payment_date, amount
FROM ranked_payments
WHERE row_num = 1
ORDER BY customer_id;


-- Verification: one row per customer?
SELECT COUNT(DISTINCT customer_id) AS customers_with_payments
FROM payment;
