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
The puzzle is about comparing the lists to each other in some way. For the full description see the [original puzzle text](https://adventofcode.com/2024/day/1).

**Part 1:** Pairwise difference in order from small to large value
- Sort both lists ascending
- Calculate absolute difference for each pair of numbers
- Sum of differences is the solution

**Part 2:** Occurences of left numbers in right list
- Order doesn't matter anymore
- Count how often each number of the right list occurs in the right list
- Multiply each number in the left list with how often it occurs in the right list and calculate the sum

#### Changes from original solution

- Use latest template version
- Better table and column names
- Use [`FROM`-first syntax](https://duckdb.org/docs/sql/query_syntax/from.html#from-first-syntax) with `SELECT` clause
- `ORDER BY` + [`POSITIONAL JOIN` ](https://duckdb.org/docs/sql/query_syntax/from.html#positional-joins) instead of window functions
- Use compact subqueries to make solution more concise
- Simplify join for similarity score calculation

#### Stats

|                                 Variant | Runtime[^runtime] | LoC[^loc] |
| --------------------------------------: | ----------------- | --------- |
|                   [SQL](./solution.sql) | ~0.04s            | 67        |
| [Original SQL](./solution.original.sql) | ~0.04s            | 74        |
|                 [Python](./solution.py) | ~0.05s            | 55        |

[^runtime]: Running `time <cmd to run solution>` several times and averaging by eyesight.
[^loc]: Number of non-empty lines (comments count) using `grep -cve '^\s*$' *.{sql,py}`. For Python it's the sum of the test and solution file.
