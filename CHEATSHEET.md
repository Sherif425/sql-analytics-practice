# SQL Window Functions · My Cheat Sheet

Read this first when coming back after a break. Details and runnable examples are in `s1/`.

## 1. The one idea

| | GROUP BY | Window function |
| --- | --- | --- |
| Rows in result | One per group (grain changes) | Every row kept (grain stays) |
| Typical use | Summary report | Detail + group context on the same row |
| Syntax | `GROUP BY customer_id` | `SUM(amount) OVER (PARTITION BY customer_id)` |

**Grain** = what one row of a result represents (one payment, one customer, one month...).

## 2. Anatomy

```
function()  OVER ( PARTITION BY ...   ORDER BY ...   [frame] )
   what        which rows go       order inside    which rows
 to compute    together            each group      (Week 2)
```

- `OVER ()` empty = whole result is one window.
- Ranking functions **need** `ORDER BY` inside `OVER`.
- `ORDER BY` inside `OVER` (how values are computed) is separate from the final `ORDER BY` (how output is displayed).
- ⚠️ `SUM(...) OVER (... ORDER BY ...)` gives a **running total**, not the group total (default frame, Week 2).

## 3. Logical order of execution

```
FROM → WHERE → GROUP BY → HAVING → window functions → SELECT → ORDER BY
```

- **WHERE can't use a window** (it runs first) → compute in a CTE, filter outside.
- **ORDER BY can use a window alias** (it runs last).
- **Windows run after GROUP BY** → `SUM(SUM(amount)) OVER (...)` is valid.

## 4. Which window for which question

| Question | Use |
| --- | --- |
| Row's share of its group / vs group average | `SUM` / `AVG ... OVER (PARTITION BY ...)` |
| Exactly one row per group (latest, dedup) | `ROW_NUMBER()` + unique tiebreaker, keep `= 1` |
| Top N values, ties included | `DENSE_RANK()` (1, 1, 2) |
| Position like a race, gaps after ties | `RANK()` (1, 1, 3) |
| Rows equal to the group max (ties kept) | `MAX(...) OVER` + `WHERE x = max_x` in a CTE |
| Previous / next row, period-over-period | `LAG` / `LEAD` *(Week 2: to learn)* |
| Running total, moving average | `SUM / AVG ... OVER (ORDER BY ... ROWS BETWEEN ...)` *(Week 2: to learn)* |

## 5. Ties and tiebreakers

- **Tie** = two rows with the same value in the sort column.
- `ROW_NUMBER` must still give them different numbers, so it picks one **arbitrarily** → result can change between runs (**non-deterministic**).
- **Tiebreaker** = extra unique column in the `OVER (ORDER BY ...)`, usually the primary key: `ORDER BY payment_date DESC, payment_id DESC`.
- `RANK` / `DENSE_RANK` don't need one: tied rows get the same number.

## 6. Standard recipes

```sql
-- Top N per group (ties included)
WITH ranked AS (
    SELECT ..., DENSE_RANK() OVER (PARTITION BY grp ORDER BY metric DESC) AS rnk
    FROM ...
)
SELECT ... FROM ranked WHERE rnk <= 3 ORDER BY grp, rnk;

-- Latest per key (dedup)
WITH ranked AS (
    SELECT ..., ROW_NUMBER() OVER (PARTITION BY key
                                   ORDER BY updated_at DESC, id DESC) AS rn
    FROM ...
)
SELECT ... FROM ranked WHERE rn = 1 ORDER BY key;
```

## 7. Style rules (dbt-ready)

- One CTE per step, read top to bottom; name the CTE after **what the table is** (`ranked_films`), columns after **what the value is** (`length_rank`).
- Never give a CTE and a column the same name.
- Explicit column list in the final SELECT, no `SELECT *`.
- Every query ends with `ORDER BY`.
- `ROUND(AVG(...), 2)` for money.
- Verify important numbers with a second query (join-to-subquery, or `EXCEPT` = 0 rows).

## 8. My mistakes log

| Mistake | Fix |
| --- | --- |
| `SUM(amount OVER (PARTITION BY ...))` | Close the function first: `SUM(amount) OVER (...)` |
| Two `ORDER BY` clauses in one query | One `ORDER BY`, columns separated by commas |
| `ORDER BY length` after `GROUP BY rating` | After GROUP BY only grouped columns/aggregates exist |
| `ORDER BY length` on the `payment` table | ORDER BY can only use columns the query has |
| Fixing "must appear in GROUP BY" by adding `payment_id` to GROUP BY | That changes the grain (each group = 1 payment). Remove the column instead |
| "Most first" but sorted ascending | Check the result against the question's wording: `DESC` |
| `RANK` for "top 3 longest, ties included" | `RANK` skips ranks after ties → `DENSE_RANK` |
| CTE named after the filtered result (`top3_film_cat`) | Name it after what it holds (`ranked_films`) |
| Sending queries without running them | Run the file first: `psql -d pagila -f file.sql` |
| Stray `sql` word copied from a markdown code fence | Delete it |

## 9. Glossary

- **Window**: the set of rows a window function looks at for the current row.
- **Partition**: one group of rows inside `PARTITION BY`.
- **Grain**: what one row represents.
- **CTE** (Common Table Expression): a named step, `WITH name AS (...)`; read as "first build this table, then query it".
- **Deterministic**: same input → same output, every run.
