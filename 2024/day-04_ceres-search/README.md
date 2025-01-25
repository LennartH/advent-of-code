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

##### Naive

A naive approach would be to simply loop over all horizontal, vertical and diagonal lines in both directions and incrementing a counter every time `XMAS` is detected (8 iterations in total). While simple in theory this is surprisingly finnicky to implement with Python, since you would have a lot of duplicate code for each loop or you have to implement [a generalized function](./solution.py#L112-L134) that can loop over a line in any direction. SQLs declarative nature makes this approach more feasible and quite concise. Using the fact that all positions in the same diagonal line have the same value for `x + y` makes it possible to collect all 4 letter words in the grid with 8 window functions. This was my [original solution](./solution.original.sql#L43-L60) with SQL as well.

##### Single Loop

An idea I had was to search in several lines (and directions) at once to reduce how often the grid has to be iterated over. For example, the following code counts all occurrences in horizontal lines from left to right:
```python
count = 0
word = 'XMAS'
word_index = 0
for y in range(height):
    word_index = 0
    for x in range(width):
        if grid[y][x] == word[word_index]:
            word_index += 1
            if word_index == 4:
                word_index = 0
                count += 1
        else:
            word_index = 1 if grid[y][x] == word[0] else 0
```
It's easy enough to search for occurrences from right to left at the same time. Either with an additional index:
```python
count = 0
word = 'XMAS'
word_index_forward = 0
word_index_backward = 0
for y in range(height):
    word_index_forward = 0
    word_index_backward = 0
    for x1 in range(width):
        x2 = width - 1 - x1
        # do count for x1
        # do count for x2
```
Or by just searching for the reverted word as well:
```python
count = 0
word_forward = 'XMAS'
word_backward = 'SAMX'
word_index_forward = 0
word_index_backward = 0
for y in range(height):
    word_index_forward = 0
    word_index_backward = 0
    for x in range(width):
        # do count for word_forward
        # do count for word_backward
```
In both cases it's necessary to have a second word index to keep track of what letter should come next. In a similar fashion it's possible to search vertical lines in the same loop as well. But since the loop iterates the letters row by row adding 2 additional word indexes is not enough. Instead one per columns is necessary and not once, but twice to handle backwards search as well. This is starting to look like that wasn't such a good idea. Now for the diagonals. A `n x m` grid has `2 * (n + m - 1)` diagonal lines, with each position being part of two. To track the index for the search word for all those diagonals in both directions 4 arrays with size `n + m - 1` are needed. With that it's possible to use `x + y` and `x - y` to get the correct word index for the two diagonals the position belongs to. So it is possible to search all lines with **each position being visited only once** (here's [the proof](./solution.py#L40-L83)). This approach is significantly harder to understand when looking at the code, so is the performance gain from iterating only once at least worth it? No. It's actually slower than the naive approach taking _~0.038s_ compared to _~0.026s_ (without IO). I thought the bad performance might be due to the overhead of initializing all those arrays, but measuring it independently didn't change the time. My guess would be that switching the currently relevant word index back and forth prevents the CPU cache from being utilized properly, which costs more than doing eight times the work.

##### Seeking

So there is a slow and hard to read appraoch and a slower and harder to read approach. Fortunately there's another way that is both faster - only _~0.013s_ - and [less than 20 lines long](./solution.py#L19-L37). The idea is to take every `X` and check if the next 3 letters are `MAS` for all directions. Each match increases the count by 1. This also only has one loop over the grid, but some positions are visited multiple times (once to check for `X` and potentially once more for each `X` within 3 tiles). Rather wasteful I must say.

#### Part 2

Part 2 looks more complicated, because you now have to count how often the following structure occurs:
```
M.S
.A.
M.A
```
The dots can be any other character, since overlaps are allowed and the corners can be in any configuration as long as both diagonals are `MAS` (forwards or backwards). The only thing to keep in mind (which I didn't initially) is that if opposite corners have the same character it doesn't count, because that would spell `MAM` or `SAS`. For example:
```
M.S
.A.
S.M
```
But I think part 2 is actually easier than part 1. Compared to the last approach for part 1 where it was necessary to search in 8 directions 3 steps deep, here it's enough to check the direct diagonal neighbours for valid combinations of `S` and `M`. I could have solved both parts with a single function, but I had enough _loop combining_ for a day, so [`solve_part2`](./solution.py#L137-L153) stays.

#### Refactoring the original SQL solution

My original SQL solution for part 1 is pretty close to the naive python approach, except that I'm collecting all 4 letter words in the grid and counting the number of `XMAS`. It'll be interesting to see, if filtering earlier provides a performance gain or if the DBMS is optimizing that under the hood anyway.

For part though I've been having so much fun with window functions, I decided to keep using them and basically collected all 3x3 boxes in the grid and used DuckDBs [`SIMILAR TO`](https://duckdb.org/docs/sql/functions/char#string-similar-to-regex) operator (like `LIKE`, but with regex) to match these boxes to all valid combinations. Here's a short illustration  with and without noise:
```
MMS
SAM => MMSSAMMXS matches M.M.A.S.S|M.S.A.M.S|S.S.A.M.M|S.M.A.S.M => True
MXS    M.S.A.M.S
```
Keeping in mind that instead of having a nice block that can be transformed the grid is stored as a long list of coordinates and its letter, I'm expecting a significant performance gain by adopting the approach from above.

And of course there's a lot to be done to make the solution more concise and easier to read. So lets get into it:

- Use latest template version
  - Takes **~0.25s** to run, which will be the overall baseline
  - Running part 1 alone takes _~0.2s_ and part 2 _~0.08s_, looks like I was wrong about where potential performance gains are

#### Stats

|                                       Variant | Runtime[^runtime] | Part 1[^parttime] | Part 2[^parttime] | LoC[^loc] |
| --------------------------------------------: | ----------------- | ----------------- | ----------------- | --------- |
|                         [SQL](./solution.sql) |                   |                   |                   |           |
|       [Original SQL](./solution.original.sql) | ~0.25s            |                   |                   | 87        |
|     [Python - Seeking](./solution.py#L19-L37) | ~0.07s            | ~0.013s           | ~0.0045s          | 73        |
| [Python - Single Loop](./solution.py#L40-L83) | ~0.095s           | ~0.038s           | ~0.0045s          | 100       |
|      [Python - Naive](./solution.py#L86-L134) | ~0.08s            | ~0.026s           | ~0.0045s          | 103       |

[^runtime]: Running `time <cmd to run solution>` several times and averaging by eyesight.
[^parttime]: Average of 100 runs using `timeit`. Only the time needed to run `solve_part_x`, without IO from reading the input.
[^loc]: Number of non-empty lines (comments count) using `grep -cve '^\s*$' *.{sql,py}`. For Python it's the sum of the test and solution file, but only counting the lines used by the approach.
