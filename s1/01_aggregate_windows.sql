-- =====================================================================
-- 01 · Aggregate windows: detail and group context on the same row
-- Session 1 · Week 1
-- =====================================================================
-- CORE IDEA
--   GROUP BY collapses rows: one row per group (it changes the GRAIN).
--   A window function keeps every row and writes the group value beside it.
--   PARTITION BY = "which rows belong together", like GROUP BY without collapsing.
--   OVER () with empty brackets = the whole result is one window.


-- ---------------------------------------------------------------------
-- PATTERN:  aggregate OVER (PARTITION BY ...)
-- QUESTION: For each payment, show the customer's total beside it.
-- WHY:      GROUP BY would lose the individual payments.
-- ---------------------------------------------------------------------
SELECT payment_id, customer_id, amount,
       SUM(amount) OVER (PARTITION BY customer_id) AS customer_total
FROM payment
ORDER BY customer_id, payment_id;


-- ---------------------------------------------------------------------
-- PATTERN:  window value inside a calculation
-- QUESTION: Each payment vs the customer's average payment (my Session 1, ex 1).
-- GOTCHA:   AVG on money gives long decimals, so ROUND(..., 2).
--           Without a final ORDER BY the output order can change between runs.
-- ---------------------------------------------------------------------
SELECT customer_id, payment_id, amount,
       ROUND(AVG(amount) OVER (PARTITION BY customer_id), 2)          AS customer_avg,
       ROUND(amount - AVG(amount) OVER (PARTITION BY customer_id), 2) AS diff_from_avg
FROM payment
ORDER BY customer_id, payment_id;


-- ---------------------------------------------------------------------
-- PATTERN:  COUNT / MAX OVER
-- QUESTION: Each payment with the customer's payment count and biggest payment.
-- ---------------------------------------------------------------------
SELECT payment_id, customer_id, amount,
       COUNT(*)    OVER (PARTITION BY customer_id) AS customer_payment_count,
       MAX(amount) OVER (PARTITION BY customer_id) AS customer_max_amount
FROM payment
ORDER BY customer_id, payment_id;


-- ---------------------------------------------------------------------
-- PATTERN:  share of total
-- QUESTION: What % of the customer's total is each payment?
-- WHY:      100.0 (with a decimal point) keeps the division in decimals.
-- ---------------------------------------------------------------------
SELECT payment_id, customer_id, amount,
       ROUND(100.0 * amount / SUM(amount) OVER (PARTITION BY customer_id), 2) AS pct_of_customer
FROM payment
ORDER BY customer_id, payment_id;


-- ---------------------------------------------------------------------
-- PATTERN:  filter on a window value with a CTE
-- QUESTION: Payments worth more than 10% of the customer's total.
-- GOTCHA:   WHERE runs BEFORE window functions, so
--           WHERE pct_of_customer > 10 fails. Compute in a CTE, filter outside.
-- ---------------------------------------------------------------------
WITH payment_share AS (
    SELECT payment_id, customer_id, amount,
           ROUND(100.0 * amount / SUM(amount) OVER (PARTITION BY customer_id), 2) AS pct_of_customer
    FROM payment
)
SELECT payment_id, customer_id, amount, pct_of_customer
FROM payment_share
WHERE pct_of_customer > 10
ORDER BY pct_of_customer DESC, payment_id;


-- ---------------------------------------------------------------------
-- PATTERN:  "equals the group max" (keeps ties!)
-- QUESTION: Each customer's biggest payment(s) (my Session 1, ex 3).
-- GOTCHA:   A customer with two payments equal to their max appears twice.
--           Need exactly one row per customer? Use ROW_NUMBER (see 04).
--           Name the CTE after the table, the column after the value:
--           never give both the same name.
-- ---------------------------------------------------------------------
WITH payments_with_max AS (
    SELECT payment_id, customer_id, amount,
           MAX(amount) OVER (PARTITION BY customer_id) AS max_amount
    FROM payment
)
SELECT payment_id, customer_id, amount
FROM payments_with_max
WHERE amount = max_amount
ORDER BY customer_id, payment_id;
