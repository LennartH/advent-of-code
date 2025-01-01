### Day 7: Bridge Repair

The input is a list of _biggish_ numbers followed by some _smallish_ numbers, for example:
```
190: 10 19
3267: 81 40 27
83: 17 5
156: 15 6
7290: 6 8 6 15
161011: 16 10 13
192: 17 8 14
21037: 9 7 18 13
292: 11 6 16 20
```
The puzzle is about combining the _smallish_ numbers (the operands) with some operators and check if there is a combination that results in the _biggish_ number (the target). The operators are _addition_ `+`, _multiplication_ `*` and _concatenation_ `||` (only part 2) and are always evaluated left-to-right, so `2 + 2 * 3 + 4` is actually `((2 + 2) * 3) + 4`. The final result is the sum of all targets that can be formed this way. For the full description see the [original puzzle text](https://adventofcode.com/2024/day/7).

The difficulty is that the number of combinations grows very quickly, although a naive brute-force approach is still feasible. But not every combination needs to explored in full, for example if the value is already bigger than the target. Another optimization I found on reddit is to process the operands from right-to-left instead, which has a huge impact on the runtime. For example looking at the line `292: 11 6 16 20` with solution `11 + 6 * 16 + 20`, the L2R approach pruning results larger than the target allowing all operators would look like this:
```
11  + 6 =  17 ✔️
11  * 6 =  66 ✔️
11 || 6 = 116 ✔️

17  + 16 =   33 ✔️   66  + 16 =   82 ✔️   116  + 16 =   132 ✔️   
17  * 16 =  272 ✔️   66  * 16 = 1056 ❌   116  * 16 =  1856 ❌
17 || 16 = 1716 ❌   66 || 16 = 6616 ❌   116 || 16 = 11616 ❌

33  + 20 =   53 ✔️   272  + 20 =   292 ✔️   82  + 20 =  102 ✔️   132  + 20 =   152 ✔️
33  * 20 =  660 ❌   272  * 20 =  5440 ❌   82  * 20 = 1640 ❌   132  * 20 =  2640 ❌
33 || 20 = 3320 ❌   272 || 20 = 27220 ❌   82 || 20 = 8220 ❌   132 || 20 = 13220 ❌

292 in [53, 292, 102, 152] ✅
```
In total 24 operations were performed (without pruning it would have been 39). The R2L approach works by starting with the target instead of the first operand and checking if it can be the result of the last operand and some operator. For example, _multiplication_ is only valid if the current value divided by the next operand is an integer, which is the same as the value modulo the operand must be 0.
```
292 - 20 >  0 ✔️ -> 272
292 % 20 =  0 ❌
    2|92 = 20 ❌

272 - 16 >  0 ✔️ -> 256
272 % 16 =  0 ✔️ ->  17
    2|72 = 16 ❌

256 - 6 > 0 ✔️ -> 250   17 - 6 > 0 ✔️ -> 11
256 % 6 = 0 ❌          17 % 6 = 0 ❌
   25|6 = 6 ✔️ ->  25      1|7 = 6 ❌

11 in [250, 25, 11] ✅
```
This only performs 12 operations, resulting in a huge performance boost for the real input, even though the implementation for _multiplication_ and _concatenation_ is more complex. So much so that implementing _concatenation_ with string instead of math operations didn't impact the runtime at all. For the naive and pruning approach the runtime nearly doubled.

#### Refactoring the original solution

This was a puzzle where my original solution had a surprisingly long runtime even with pruning results larger than the target value. It takes ~3 times longer than my original solution for day 6, which required some non-trivial graph traversal and loop detecion, and ~20 times longer than the pruning solution in python.

Using [`EXPLAIN ANALYZE`](https://duckdb.org/docs/guides/meta/explain_analyze.html) to profile the [main query](./solution.original.sql#L37-L73) shows that unnesting the results after applying the operators accounts for ~89% of the total time and is done **before** pruning ([profiler output](./profiler)).

I made the following changes, keeping track of their impact on the runtime. The original runtime was **~50s**, but note that it fluctuates between 45s and 55s, so this isn't an exact science.

- Use latest template version
- Use [`FROM`-first syntax](https://duckdb.org/docs/sql/query_syntax/from.html#from-first-syntax) with `SELECT` clause
- Reduce size of calculations table and simplify results query (down by ~5s to **~45s**)
- Improve input parsing
  - Remove window function for the line number
  - Add number of operands as column instead of using `len(operands)` in multiple places
- Use tables instead of views for intermediate queries (down by ~3s to **~42s**)
- Implement _concatenation_ using math instead of string operations
  - Surprisingly this didn't improve the runtime, I'm wondering if DuckDB is doing some optimizations in the background
- Only track if _concatenation_ has been used instead of maintaining a list of all operators (down by ~9s to **~33s**)
- Replace `unnest` with `UNION` of query per operator (<u>down by ~31s to **~2s**</u>)
  - I tried unnesting only the results that would be less or equals the target (effectively pruning before unnesting), but that didn't effect the runtime (and was convoluted)
  - My guess why this improves performance so much is that `UNION` merges three datasets (one per operator), while `unnest` merges one dataset per row
  - Applying only this change to the original solution reduces the runtime to ~6.8s, so the other changes make a differences, although a lot is probably optimized in the background by DuckDB.
- Implement R2L approach (<u>down by ~1.94s to **~0.06s**</u>)

From **~50s** to **~0.06s**, an improvement of three orders of magnitude. Not bad at all (if you don't think about how bad the original solution was).

#### Stats

|                                           Variant | Runtime[^runtime] | LoC[^loc] |
| ------------------------------------------------: | ----------------- | --------- |
|                       [SQL - R2L](./solution.sql) | ~0.06s            | 109       |
|                           SQL - Pruning TODO Link | ~2s               | TODO      |
| [Original SQL - Pruning](./solution.original.sql) | ~50s              | 79        |
|             [Python - R2L](./solution.py#L34-L50) | ~0.08s            | 80        |
|         [Python - Pruning](./solution.py#L53-L66) | ~2.3s             | 80        |
|           [Python - Naive](./solution.py#L69-L80) | ~4s               | 78        |

[^runtime]: Running `time <cmd to run solution>` several times and averaging by eyesight.
[^loc]: Number of non-empty lines (comments count) using `grep -cve '^\s*$' *.{sql,py}`. For Python it's the sum of the test and solution file, but only counting the lines used by the approach.
