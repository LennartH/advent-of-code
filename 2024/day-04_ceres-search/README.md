### Day 4: Ceres Search

This one is like these word search puzzles where you're given a grid of letters, but in this case you have to find all instances of `XMAS`. Here is a small example:
```
MMMSXXMASM
MSAMXMSMSA
AMXSXMAAMM
MSAMASMSMX
XMASAMXAMM
XXAMMXXAMA
SMSMSASXSS
SAXAMASAAA
MAMMMXMMMM
MXMXAXMASX
```
For the full description see the [original puzzle text](https://adventofcode.com/2024/day/4).

#### Part 1

For part 1 the goal is to count all instances of `XMAS` horizontal, vertical and diagonal in forwards and backwards direction and instances overlapping each other are allowed as well. So the following smaller example would have a count of 3, while the example above has 18 instances.
```
XMAS.
.M...
.SAMX
...S.
```
A naive approach would be to simply iterate over all horizontal, vertical and diagonal lines in both directions and incrementing a counter every time `XMAS` is detected.
TODO Combine loops to reduce number of iterations
TODO Search for and around X

#### Part 2

Part 2 looks more complicated, because you now have to count how often this structure occurs:
```
M.S
.A.
M.A
```
The dots can be any other character, since overlaps are allowed and the can be anything as long as both diagonals spell out `MAS` (forwards or backwards). The only thing to keep in my (which I didn't, initially) is that if opposite corners have the same character it doesn't count, because that would spell `MAM` and `SAS`. For example:
```
M.S
.A.
S.M
```
A good approach is to take all occurrences of `A` and check their diagonal neighbours for valid combinations.

#### Refactoring the original solution


#### Stats

|                                           Variant | Runtime[^runtime] | LoC[^loc] |
| ------------------------------------------------: | ----------------- | --------- |
|                       [SQL - R2L](./solution.sql) | ~0.06s            | 109       |
| [SQL - Pruning](https://github.com/LennartH/advent-of-code/blob/7bad233775feb3de9cfdcc448267eb9b3450875a/2024/day-07_bridge-repair/solution.sql) | ~2s | 103 |
| [Original SQL - Pruning](./solution.original.sql) | ~50s              | 79        |
|             [Python - R2L](./solution.py#L34-L50) | ~0.08s            | 80        |
|         [Python - Pruning](./solution.py#L53-L66) | ~2.3s             | 80        |
|           [Python - Naive](./solution.py#L69-L80) | ~4s               | 78        |

[^runtime]: Running `time <cmd to run solution>` several times and averaging by eyesight.
[^loc]: Number of non-empty lines (comments count) using `grep -cve '^\s*$' *.{sql,py}`. For Python it's the sum of the test and solution file, but only counting the lines used by the approach.
