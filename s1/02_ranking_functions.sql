-- =====================================================================
-- 02 · Ranking functions: ROW_NUMBER, RANK, DENSE_RANK
-- Session 2 · Week 1
-- =====================================================================
-- CORE IDEA
--   A ranking function numbers rows inside each group in an order you choose.
--   PARTITION BY = where the numbering restarts.
--   ORDER BY inside OVER = who comes first (required for ranking functions).
--   The final ORDER BY only controls how the output is DISPLAYED.
--
--   Ties (same value in the sort column):
--     length | ROW_NUMBER | RANK | DENSE_RANK
--      185   |     1      |  1   |     1
--      185   |     2      |  1   |     1
--      184   |     3      |  3   |     2
--
--   ROW_NUMBER: always unique, picks a tied row ARBITRARILY unless you add a tiebreaker.
--   RANK:       ties share a number, then a gap (1, 1, 3), like Olympic medals.
--   DENSE_RANK: ties share a number, no gap (1, 1, 2).


-- ---------------------------------------------------------------------
-- PATTERN:  all three side by side
-- QUESTION: Rank films by rental_rate, highest first (my Session 2, ex 1).
-- WHAT I SAW: only 3 rental rates exist, so DENSE_RANK = 1..3,
--             RANK jumps after each block of ties, ROW_NUMBER = 1..1000.
-- WHY:      film_id is the tiebreaker: it makes ROW_NUMBER the same on every run.
--           RANK/DENSE_RANK don't need one: tied rows get the same number anyway.
-- ---------------------------------------------------------------------
SELECT film_id, title, rental_rate,
       ROW_NUMBER() OVER (ORDER BY rental_rate DESC, film_id) AS row_num,
       RANK()       OVER (ORDER BY rental_rate DESC)          AS rank_num,
       DENSE_RANK() OVER (ORDER BY rental_rate DESC)          AS dense_rank_num
FROM film
ORDER BY rental_rate DESC, film_id;


-- ---------------------------------------------------------------------
-- PATTERN:  ranking restarted per group
-- QUESTION: Rank films by length inside each rating.
-- ---------------------------------------------------------------------
SELECT title, rating, length,
       ROW_NUMBER() OVER (PARTITION BY rating ORDER BY length DESC, film_id) AS rn,
       RANK()       OVER (PARTITION BY rating ORDER BY length DESC)          AS rnk,
       DENSE_RANK() OVER (PARTITION BY rating ORDER BY length DESC)          AS dense_rnk
FROM film
ORDER BY rating, rn;


-- ---------------------------------------------------------------------
-- See the tiebreaker effect yourself:
-- rn_no_tiebreaker can change between runs for tied lengths,
-- rn_with_tiebreaker always puts the smaller film_id first.
-- ---------------------------------------------------------------------
SELECT film_id, title, length,
       ROW_NUMBER() OVER (ORDER BY length DESC)          AS rn_no_tiebreaker,
       ROW_NUMBER() OVER (ORDER BY length DESC, film_id) AS rn_with_tiebreaker
FROM film
ORDER BY length DESC, film_id
LIMIT 10;
