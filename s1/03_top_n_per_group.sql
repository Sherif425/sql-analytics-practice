-- =====================================================================
-- 03 · Top N per group
-- Session 2 · Week 1
-- =====================================================================
-- RECIPE
--   1. Get the data on one row (joins).
--   2. Rank inside each group (window function).
--   3. Wrap in a CTE and filter rank <= N outside (WHERE can't see windows).
--
-- WHICH FUNCTION?
--   "Top N values, ties included"      -> DENSE_RANK
--   "Top N positions, competition gaps" -> RANK
--   "Exactly N rows, no matter what"   -> ROW_NUMBER + tiebreaker


-- ---------------------------------------------------------------------
-- PATTERN:  top N per group with ties
-- QUESTION: 3 longest films in each category (my Session 2, ex 3).
-- RESULT:   75 rows. Action = 7 rows (lengths 184, 184, 183, 183, 182, 182, 182).
--           Row count differs per category: that IS "ties included".
-- WHY:      With RANK, Action gave ranks 1,1,3,3,5,... so "<= 3" kept only
--           4 films and 2 different lengths: the 182-minute films were cut.
-- GOTCHA:   Partition by category_id (unique), not by name.
--           Name the CTE after what it holds (all ranked films), not the filtered result.
-- ---------------------------------------------------------------------
WITH ranked_films AS (
    SELECT cat.name AS category_name, f.title, f.length,
           DENSE_RANK() OVER (PARTITION BY cat.category_id
                              ORDER BY f.length DESC) AS length_rank
    FROM category cat
    JOIN film_category fcat ON cat.category_id = fcat.category_id
    JOIN film f             ON fcat.film_id   = f.film_id
)
SELECT category_name, length_rank, title, length
FROM ranked_films
WHERE length_rank <= 3
ORDER BY category_name, length_rank, title;


-- ---------------------------------------------------------------------
-- TODO (Session 2, ex 4): top 3 customers by total spend in each store.
--   CTE 1 customer_spend:   one row per customer (customer_id, store_id, SUM(amount))
--   CTE 2 ranked_customers: rank inside each store, highest spend first
--   Then filter to the top 3. Comment which ranking function and why.
-- ---------------------------------------------------------------------
