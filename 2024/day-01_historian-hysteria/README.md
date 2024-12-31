### Day 1: Historian Hysteria

The input is two lists of numbers "side by side", for example:
```
3   4
4   3
2   5
1   3
3   9
3   3
```

**Part 1:**
- Sort both lists ascending
- Calculate absolute difference for each pair of numbers
- Sum of differences is the solution

**Part 2:**
- Order doesn't matter anymore
- Count how often each number of the right list occurs in the right list
- Multiply each number in the left list with how often it occurs in the right list and calculate the sum

#### Changes from original solution

- Use most recent template version
- Better table and column names
- Use [`FROM`-first syntax](https://duckdb.org/docs/sql/query_syntax/from.html#from-first-syntax) with `SELECT` clause
- `ORDER BY` + [`POSITIONAL JOIN` ](https://duckdb.org/docs/sql/query_syntax/from.html#positional-joins) instead of window functions
- Use compact subqueries to make solution more concise
- Simplify join for similarity score calculation

#### Runtimes

|      Variant | Runtime |
| -----------: | ------- |
|          SQL | ~0.04s  |
| Original SQL | ~0.04s  |
|       Python | ~0.05s  |
