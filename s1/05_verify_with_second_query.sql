-- =====================================================================
-- 05 · Verify a result with a second, different query
-- Session 1 · Week 1   ·   required for the Gate 1 self-test
-- =====================================================================
-- IDEA
--   A query that runs is not a query that is right. Rebuild the number a
--   different way and compare. The classic alternative to a window:
--   GROUP BY in a subquery, then JOIN back to the detail rows.


-- ---------------------------------------------------------------------
-- PATTERN:  join to a grouped subquery (the "old way")
-- QUESTION: Same as 01: each payment with the customer's average.
-- ---------------------------------------------------------------------
SELECT p.customer_id, p.payment_id, p.amount,
       ROUND(av.customer_avg, 2)            AS customer_avg,
       ROUND(p.amount - av.customer_avg, 2) AS diff_from_avg
FROM payment p
JOIN (SELECT customer_id, AVG(amount) AS customer_avg
      FROM payment
      GROUP BY customer_id) av
  ON av.customer_id = p.customer_id
ORDER BY p.customer_id, p.payment_id;


-- ---------------------------------------------------------------------
-- PATTERN:  EXCEPT check (zero rows = the two queries agree)
-- GOTCHA:   same columns, same order, same rounding on both sides.
--           Run it in BOTH directions (A EXCEPT B, then B EXCEPT A).
-- ---------------------------------------------------------------------
(SELECT payment_id,
        ROUND(AVG(amount) OVER (PARTITION BY customer_id), 2) AS avg_amt
 FROM payment)
EXCEPT
(SELECT p.payment_id, ROUND(av.avg_amt, 2)
 FROM payment p
 JOIN (SELECT customer_id, AVG(amount) AS avg_amt
       FROM payment
       GROUP BY customer_id) av
   ON av.customer_id = p.customer_id);
