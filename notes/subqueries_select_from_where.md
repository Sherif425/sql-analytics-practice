# Subqueries in SELECT, FROM, and WHERE

## Why courses split subqueries into three places

A subquery is always the same thing: a query inside a query. What changes is **what each clause expects to receive**. Where you put the subquery decides what shape its result has to be and what SQL does with it.

Every clause asks its own question, and the subquery has to answer in the form that clause expects:

| Where | The clause is asking… | Subquery must return | Common name |
|---|---|---|---|
| `SELECT` | "What value goes in this column for this row?" | **One value** (1 row × 1 column) | Scalar subquery |
| `FROM` | "What table am I reading from?" | **A whole table** (any rows, any columns) | Derived table / inline view |
| `WHERE` | "Do I keep this row or not?" | **Something to test against**: a single value, a list, or "does anything exist?" | Filter subquery |

All examples below use two tables:

```sql
customers(customer_id, name)
orders(order_id, customer_id, amount)
```

---

## 1. Subquery in SELECT: produces one value per row

```sql
SELECT
    c.name,
    (SELECT COUNT(*)
     FROM orders o
     WHERE o.customer_id = c.customer_id) AS order_count
FROM customers c;
```

- A column cell can only hold **one value**, so the subquery has to return exactly 1 row and 1 column. If it returns 2 rows, you get an error ("more than one row returned by a subquery used as an expression").
- `o.customer_id = c.customer_id` uses a column from the outer query. This makes it a **correlated subquery**: it runs again for every customer row. It's like a loop in Python: `for each customer: count their orders`.
- In practice, a `LEFT JOIN` plus `GROUP BY` often does the same job, and it usually runs faster on big tables.

## 2. Subquery in FROM: produces a temporary table

```sql
SELECT customer_id, total_spent
FROM (
    SELECT customer_id, SUM(amount) AS total_spent
    FROM orders
    GROUP BY customer_id
) AS customer_totals
WHERE total_spent > 1000;
```

- `FROM` needs a table, so here the subquery can return **many rows and many columns**. The outer query treats the result like a real table.
- It must have an **alias** (`AS customer_totals`) because every table in FROM needs a name.
- Why use it? To do work in **steps**: first build a result (totals per customer), then query that result. A common case is aggregating twice, like "the average of each customer's total." You can't nest `AVG(SUM(...))` directly, but you can with a FROM subquery.
- **Why this matters for analytics engineering:** CTEs (`WITH customer_totals AS (...)`) are basically FROM subqueries with a name, written at the top so they're easier to read. dbt models are built almost entirely from CTEs.

The same query written as a CTE:

```sql
WITH customer_totals AS (
    SELECT customer_id, SUM(amount) AS total_spent
    FROM orders
    GROUP BY customer_id
)
SELECT customer_id, total_spent
FROM customer_totals
WHERE total_spent > 1000;
```

## 3. Subquery in WHERE: decides which rows survive

The shape depends on the operator you use:

```sql
-- a) Compare with ONE value (=, >, <): must return a single value
SELECT * FROM orders
WHERE amount > (SELECT AVG(amount) FROM orders);

-- b) IN: must return ONE column, but it can have many rows (a list)
SELECT * FROM customers
WHERE customer_id IN (SELECT customer_id FROM orders WHERE amount > 500);

-- c) EXISTS: the shape doesn't matter; it only checks "is there at least one row?"
SELECT * FROM customers c
WHERE EXISTS (SELECT 1 FROM orders o WHERE o.customer_id = c.customer_id);
```

- This is the main way to **filter using another table** without joining it into your result.
- `NOT EXISTS` is the safe way to ask "customers with **no** orders." `NOT IN` returns surprising empty results if the subquery returns any `NULL`s. This is a classic interview trap.
- `HAVING` works the same way as `WHERE`, except it filters groups after `GROUP BY`.

---

## Summary

The location decides the **shape** of what the subquery must return:

- In **SELECT** it returns a single value.
- In **FROM** it returns a table.
- In **WHERE** it returns a value, a list, or a yes/no existence check.

Whether a subquery is **correlated** (uses outer columns and re-runs per row) or **independent** (runs once) is a separate question. Either kind can appear in any of the three places.

---

## Practice exercises

Use the `customers` and `orders` tables above.

1. **SELECT:** List each customer's name with their **largest** single order amount.
2. **FROM:** Find the **average number of orders per customer**. Hint: count orders per customer in a subquery first, then average that.
3. **WHERE:** List customers who have **never** placed an order. Write it once with `NOT EXISTS` and once with `LEFT JOIN ... WHERE o.order_id IS NULL`.
