# sql-analytics-practice

My analytics SQL practice for the 64-week Analytics Engineering roadmap (SQL track).
Database: **Pagila** (PostgreSQL version of Sakila). Later stages move to DuckDB, Snowflake and BigQuery.

## How this repo is organised

- **One file per pattern, not per session.** Each file answers one kind of question.
- Every query starts with a comment header:

  ```sql
  -- PATTERN:  the reusable technique
  -- QUESTION: the business question in plain words
  -- WHY:      why this function / approach, and not the alternatives
  -- GOTCHA:   the mistake I made or the trap to avoid
  ```

- `CHEATSHEET.md` is the one-page summary in my own words: which window for which question,
  order of execution, and my own mistakes log. Read it first when coming back after a break.

## Layout

| Folder | Stage | Weeks |
| --- | --- | --- |
| `s1/` | S1 · Core analytical SQL (window functions) | 1–2 |
| `s2/` | S2 · Analytics patterns (cohorts, retention, gaps and islands) | 3–4 |
| `s3/` | S3 · SQL for dbt models and data-quality checks | 5–6 |

## Habits

1. Run the whole file before committing: `psql -d pagila -f s1/03_top_n_per_group.sql`
2. Every final query ends with `ORDER BY`.
3. `ROW_NUMBER` always gets a unique tiebreaker (usually the primary key).
4. Check important numbers with a second, different query.
5. Commit after every session: `git add . && git commit -m "s1: top N per group"`
