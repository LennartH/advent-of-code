[**Day 6: Guard Gallivant**](#day-5-guard-gallivant)</br>
&ensp;&ensp;[Part 1](#part-1)</br>
&ensp;&ensp;[Part 2](#part-2)</br>
&ensp;&ensp;[Abstract Approach](#abstract-approach)</br>
&ensp;&ensp;&ensp;&ensp;[_Naive Approach_](#naive-approach)</br>
&ensp;&ensp;&ensp;&ensp;[_Raywalking Approach_](#raywalking-approach)</br>
&ensp;&ensp;&ensp;&ensp;[_Loop Detection Optimizations_](#loop-detection-optimizations)</br>
<!-- [**Python Solution**](#python-solution)</br>
&ensp;&ensp;[Part 1](#part-1-1)</br>
&ensp;&ensp;&ensp;&ensp;[_Naive Approach_](#naive-approach)</br>
&ensp;&ensp;&ensp;&ensp;[_Raywalking Approach_](#raywalking-approach)</br>
&ensp;&ensp;[Part 2](#part-2-1)</br>
[**SQL Solution**](#sql-solution)</br>
&ensp;&ensp;[Original Approach](#original-approach)</br>
&ensp;&ensp;[Improving the Original SQL Solution](#improving-the-original-sql-solution)</br> -->
[**Stats**](#stats)</br>

### Day 6: Guard Gallivant

This is the first 2D grid puzzle of 2024. A common problem class of AoC, but each has something that makes them feel novel. This one is no exception, having a very interesting part 2. Even though this doesn't need any (shortest) pathfinding, 2D grid puzzles were quite intimidating to solve with SQL. All of this together made this quite the (early) challenging day. As always see the [original puzzle text](https://adventofcode.com/2024/day/6) for all the details.

The input is a map where `#` are walls, `.` walkable tiles and `^` the starting position and direction. For example:
```
....#.....
.........#
..........
..#.......
.......#..
..........
.#..^.....
........#.
#.........
......#...
```
The rules of movement are simple:
- Move in the current direction
- When a wall is encountered turn right
- This continues until the map is exited (and no, part 2 is not about wrapping around the edges)

Here is each wall encounter for the example and the final position before exiting the map
```
Start         1)            2)            3)            4)            5)            6)            7)            8)            9)            10)           Exit      
....#.....    ....#.....    ....#.....    ....#.....    ....#.....    ....#.....    ....#.....    ....#.....    ....#.....    ....#.....    ....#.....    ....#.....
.........#    ....>....#    ........v#    .........#    .........#    .........#    .........#    .........#    .........#    .........#    .........#    .........#
..........    ..........    ..........    ..........    ..........    ..........    ..........    ..........    ..........    ..........    ..........    ..........
..#.......    ..#.......    ..#.......    ..#.......    ..#.......    ..#.......    ..#.......    ..#.......    ..#.......    ..#.......    ..#.......    ..#.......
.......#..    .......#..    .......#..    .......#..    .......#..    ..>....#..    ......v#..    .......#..    .......#..    .......#..    .......#..    .......#..
..........    ..........    ..........    ..........    ..........    ..........    ..........    ..........    ..........    ..........    ..........    ..........
.#..^.....    .#........    .#........    .#......<.    .#^.......    .#........    .#........    .#........    .#........    .#........    .#........    .#........
........#.    ........#.    ........#.    ........#.    ........#.    ........#.    ........#.    ........#.    ........#.    .>......#.    .......v#.    ........#.
#.........    #.........    #.........    #.........    #.........    #.........    #.........    #.....<...    #^........    #.........    #.........    #.........
......#...    ......#...    ......#...    ......#...    ......#...    ......#...    ......#...    ......#...    ......#...    ......#...    ......#...    ......#v..
```

#### Part 1

Since this is only day 6, part 1 starts off easy. The task is to count the number of **distinct tiles** that were visited before leaving the map (including the starting position). The only thing to keep in mind is to not count tiles multiple times, so a simple step count won't do. Below is the path when encountering the 6th wall and after leaving the map. Tiles visited more than once are marked as `X`. In the example a total of **41** distinct tiles are visited.
```
6)              Exit      
....#.....      ....#.....
....+---+#      ....+---+#
....|...|.      ....|...|.
..#.|...|.      ..#.|...|.
..+-X->#|.      ..+-X-+#|.
..|.|...|.      ..|.|.|.|.
.#+-X---+.      .#+-X-X-+.
........#.      .+----X+#.
#.........      #+----+|..
......#...      ......#v..
```

An edge case that isn't shown in the example is that encountering two walls consecutively results in a 180 degree turn.
```
Map             Path      
...#......      .^.#......
#.......#.      #+-XXXXX#.
.......#..      ...|...#..
...^......      ...|......
..........      ..........
```

#### Part 2

Now for the twist of part 2, where the objective is to introduce loops by placing a single new obstacle on the map. I didn't expect this and usually when doing pathfinding or graph traversal loops are something to prune or prevent. Here it's about provoking them instead. This is what I meant with each puzzle bringing something novel to this class of problems. The solution for part 2 is the total number of loops that can be created by placing obstacles on the given map. In the example **6** loops can be created. A few of them are shown below in detail as well as all obstacles at once.
```
1)              2)              3)              All       
....#.....      ....#.....      ....#.....      ....#.....
....+---+#      ....+---+#      ....+---+#      .........#
....|...|.      ....|...|.      ....|...|.      ..........
..#.|...|.      ..#.|...|.      ..#.|...|.      ..#.......
....|..#|.      ..+-+-+#|.      ..+-+-+#|.      .......#..
....|...|.      ..|.|.|.|.      ..|.|.|.|.      ..........
.#.O^---+.      .#+-^-+-+.      .#+-^-+-+.      .#.O^.....
........#.      ......O.#.      ....|.|.#.      ......OO#.
#.........      #.........      #..O+-+...      #O.O......
......#...      ......#...      ......#...      ......#O..
```

But what's not completely obvious (at least it wasn't to me), is that the obstacle must be placed before movement starts. So the following is **not valid** and mustn't count towards the total number of loops.
```
Map                Path               Invalid Loop 
.#...........      .#....^......      .#...........
............#      .+----X----+#      .+----O̶----+#
.^..........#      .|....|....|#      .^....+----+#
.....#.......      .....#+----+.      .....#+----+.
...........#.      ...........#.      ...........#.
```

A few other things that are not shown in the puzzle example. All loops in the example "re-use" walls from the original path, but that doesn't have to be the case (especially for larger maps):
```
Map            Path           Loop     
.........      .^.......      .........
....#....      .|..#....      .O..#....
.......#.      .|.....#.      .+--+-+#.
...#.....      .|.#.....      .|.#+-+..
......#..      .|....#..      .|....#..
.^.......      .|.......      .^.......
.........      .........      .........
```

Also, note that loop three from above consists of more than 4 segments. But it's also possible to have loops with fewer. In general loops can have an arbitrary length:
```
Map         Path        Loop  
......      ...^..      ......
.#..#.      .#.|#.      .#..#.
.....#      .+-X+#      .+--+#
......      .|.||.      .|..|.
.^#...      .|#++.      .^#O+.
....#.      ....#.      ....#.
```

#### Abstract Approach

There is a lot beneath the surface for this one, especially when going into specific implementations. I wasn't sure how to slice this, but decided to start with a programming language agnostic abstract approach to introduce common concepts and go into some details in the Python / SQL solutions.

##### Naive Approach

The most simple approach I can think of is to move tile by tile, checking ahead for walls or moving out of bounds. For part 1, each visited tile would increment a counter, if not previously visited. Or all visited tiles are collected and deduplicated at the end. Part 2 is a bit more complicated, because some logic for loop detection is necessary, but the simplest approach would be to place an obstacle on each distinct visited tile and perform the movement again from the start. With that simply counting the number of times a loop is encountered gives the solution.

##### Raywalking Approach

Most of the movement done in the naive approach is unnecessary, since nothing needs to be done apart from advancing the current position by 1 in the current direction. Only when a wall is encountered the program state is impacted significantly. **So the idea is to directly move to the closest wall in the current direction, skipping all steps in between.** Finding the closest wall reminded me of casting a ray of light, hence the name raywalking for this approach. This reduces the number of steps significantly. In the example from above it takes **11** _ray steps_ to exit the map, compared to **55** steps for the naive approach, a factor of **0.2**. The impact gets more apparent looking at my actual input. **138** _ray steps_ compared to **4960** naive steps, a factor of about **0.028**. Also, (nearly) every visited tile leads to another walk of the map for part 2.

Of course this doesn't come without downsides. Finding the closest wall to arbitrary positions needs to be more efficient than simply walking forward until a wall is encountered. So some supporting data structures providing efficient access to walls are necessary. Another issue is to count the distinct visited tiles and collect the obstacle placements without performing all those moves that were saved by raywalking. But this won't invalidate the approach, since searching for loops in part 2 is still benefiting significantly. Both downsides are a lot easier to manage in SQL than in Python (suspicious, I know) and I'll go into some detail in the sections for my SQL / Python solution.

##### Loop Detection Optimizations

The simplest way to find all loops would be to place the obstacle and walking the map from the starting position until a previously visited tile having the same direction is encountered or the map is exited.

An obvious optimization is to **start from the position when encountering the obstacle** instead from the start. This can be done by remembering/storing the previous position for each visited tile. But makes deduplication a bit more complicated, because the order when a tile was visited is important. Only the first entry for a visited tile can be used or the obstacle would've been placed after movement started, creating invalid loops like the one shown above.

Another optimization is to **terminate the loop detection as early as possible** by utilizing the available context from walking the map for part 1. For this it helps to look at the anatomy of an obstacle placement:
```
Path              Obstacle  
....#.....        ....#.....       obstacle: (3, 6)
....+---+#        ....P---P#       position: (3, 6, <)
....|...|.        ....|...|.
..#.|...|.        ..#.|...|.       previous tiles: [(4, 1, ^), (8, 1, >), (8, 6, v)]
..+-+-+#|.        ..F-+-F#|.         future tiles: [(2, 6, <), (2, 4, ^), (6, 4, >), (6, 8, v),
..|.|.|.|.        ..|.|.|.|.                        (1, 8, <), (1, 7, ^), (7, 7, >)]
.#+-+-+-+.        .#FO<-+-P.
.+----++#.        .F----+F#.       position after obstacle: (4, 1, ^)
#+----+|..        #F----F|..
......#v..        ......#|..
```
Placing an obstacle effectively splits the original path in 2 sets. A set of tiles visited before encountering the obstacle and a set of tiles that would have been visited, ultimately exiting the map. These 2 sets are useful for early loop detection termination. In the example the next position after encountering the obstacle is the first entry of the tiles that have been visited previously. **In general, as soon as a tile from the set of previous tiles is visited again, a loop has been found.**

Similarly **the set of future tiles can be used to detect early that an obstacle cannot cause a loop**:
```
Path              Obstacle  
....#.....        ....#.....       obstacle: (7, 1)
....+---+#        ....P->OF#       position: (6, 1, >)
....|...|.        ....|...|.       
..#.|...|.        ..#.|...|.       previous tiles: [(4, 1, ^)]
..+-+-+#|.        ..F-+-F#|.         future tiles: [(8, 1, >), (8, 6, v), (2, 6, <), (2, 4, ^), (6, 4, >),
..|.|.|.|.        ..|.|.|.|.                        (6, 8, v), (1, 8, <), (1, 7, ^), (7, 7, >)]
.#+-+-+-+.        .#F-+-+-F.       
.+----++#.        .F----+F#.       position after obstacle: (6, 8, v)
#+----+|..        #F----F|..       
......#v..        ......#|..       
```

Here the next position after encountering the obstacle is already in the set of future tiles. Since we know that the original path exited the map and that the next position is part of the original path, it is not possible the obstacle causes a loop. But there is a pretty mean edge case leading to a false negative:
```
Map               Obstacle
.#.#.........     .#|#.........      obstacle: (2, 3)
.......#.....     .F+---F#.....      position: (3, 3, <)
.............     .||...|......
#.........<..     #FO<--+----..      previous tiles: []
.........#...     ..|...|..#...        future tiles: [(1, 3, <), (1, 1, ^), (6, 1, >), (6, 5, v), (2, 5, <)]
.#...........     .#F---F......                                                 ^
......#.#....     ......#.#....                                                 |
                                     positions after obstacle: [         in future tiles
Path              Obstacle Path          (3, 1, ^),                             |
.#^#.........     .#.#.........          (6, 1, >), (6, 5, v), <----------------+
.++---+#.....     ...+--+#.....    +---> (2, 5, <), (2, 4, ^), (8, 4, >), (8, 5, v), 
.||...|......     ...|..|......    |     (2, 5, <), ...  ^
#++---+----..     #.O+--+----..    | ]                   |
..|...|..#...     ..+---+-+#...    |                     +--- second obstacle encounter
.#+---+......     .#+-<-+-+....    |
......#.#....     ......#.#....    +--- this is the loop
```

Here the second position after encountering the obstacle is contained by the set of future tiles, but the obstacle is encountered again from a different direction just before the map would be exited. This alters the original path again, so terminating the loop detection at that point would be premature. **So not all future tiles can be used, but only the ones after the obstacle would be encountered the last time**. For the example that is an empty set, but that's unlikely for the real input.

These optimizations can be used regardless of the chosen approach, but I'd argue that a naive approach with early loop detection termination isn't really naive anymore. With that out of the way, we can start looking at some actual implementations for day 6.


### Python Solution

FIXME structure solutions by approach or by part?

#### Part 1

##### Naive Approach

TODO add relative measures with slowest as baseline

The naive approach for part 1 is pretty straightforward, simply walk the map according to the rules. But there are still a few things to play around with regarding how to only count the distinct visited tiles. The main decisions are to just increment a counter during traversal or to actually collect the visited positions and in case of the latter, what data structures to use. I tested a few different combinations, the runtimes are the average of 1000 runs using `timeit` excluding IO from reading the input, but including parsing the input:
1. **Using a set**, deduplicating the visited tiles from the start
    - with **strings** like `f'{x},{y}'` for entries: _0.00320s_
    - with **tuples** like `(x,y)` for entries: _0.00176s_
2. **Using a list**, collecting all visited tiles and deduplicating at the end by creating a `set` from the list
    - with **strings** like `f'{x},{y}'` for entries: _0.00300s_
    - with **tuples** like `(x,y)` for entries: _0.00175s_
3. **Using a boolean grid** to track which tiles have been visited
    - collecting visited tiles as **strings** like `f'{x},{y}'`: _0.00280s_
    - collecting visited tiles as **tuples** like `(x,y)` for entries: _0.00162s_
    - Only incrementing a counter: _0.00144s_

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

This shows that using a string to represent a position is a lot more costly than using a tuple and that it doesn't seem to matter, whether a set is used from the start or only at the end to determine the total count of visited tiles. Solving part 1 only requires the number visited tiles, but the list of positions and directions is useful for part 2. This is the main reason to I decided to stick with approach 3, so I that the direction doesn't have to be excluded when calculating the hash during deduplication.

The final implementation of this approach builds a list of visited tiles with the information necessary for part 2 and takes _0.00310s_ in isolation and **~0.065s** with IO.

##### Raywalking Approach

Since no branching is necessary to traverse the map, one thought is to reduce the number of computational steps by directly jumping to the next obstacle. Of course this requires a different way of storing information and moving on the map. But the bigger issue will be with not overcounting already visited tiles without iterating them, which would defeat the purpose. I wanted to try the approach anyway, because I was curious how the performance would be compared to the intuitive approach. Below is the example using this approach marking jumps with `@`, the rays inbetween with `|` and `-` and tiles visited more than once with `X`.
```                 
....#.....      ....#.....      ....#.....
....@---@#      ....@---@#      ....@---@#
....|...|.      ....|...|.      ....|...|.
..#.|...|.      ..#.|...|.      ..#.|...|.
....|..#|.      ..@-X->#|.      ..@-X-@#|.
....|...|.      ..|.|...|.      ..|.|.|.|.
.#..|...v.      .#@-X---@.      .#@-X-X-@.
........#.      ........#.      .@----X@#.
#.........      #.........      #@----@|..
......#...      ......#...      ......#|..
```

Did I say I was done with theory? Well I lied. The total number of steps is calculated by summing the manhatten distance `abs(x1 - x2) + abs(y1 - y2)` of all rays plus one. What's left is to subtract the number of tiles visited more than once to get the solution. Those can be determined by checking if rays are crossing each other like shown below.
```
....#.....    r0: x = 4, y = 1 to 6
....1....#    r3: y = 6, x = 2 to 8
....|.....    r5: y = 4, x = 2 to 6
..#.|.....    r7: y = 8, x = 1 to 6
..5-+-6#.. 
....|.....           r0   rn   r0    rn   r0   rn
.#4-O̶---3.    r3/r0: 1 <= 6 <= 6  ✅ 2 <= 4 <= 8  ✅
........#.    r5/r0: 1 <= 4 <= 6  ✅ 2 <= 4 <= 6  ✅
#8----7...    r7/r0: 1 <= 8 <= 6  ❌ 1 <= 4 <= 6  ✅
......#... 
```
TODO All rays need to be checked not just different orientations

In general crossing rays can be found by checking if a rays axis is within another rays length and vice versa and it's sufficient to check rays with different orientations. But there is an edge case for 180° turns, where the complete ray needs to be subtracted from the total number of steps.
```
   ...#......      .|.#......    r1: y = 1, x = 3 to 7
   #.......#.      #3-1---2#.    r2: y = 1, x = 1 to 7
   .......#..      ...|...#..
   ...^......      ...0......    The shorter ray r1 needs to be discarded
   ..........      ..........

........#....      ........#....
.............      ........9----
.#...........      .#......|....
.........#...      .1------2#...
.^..#........      .0..#...|....
............#      ....5---+--6#
.............      ....|...|..|.
.............      ....|...|..|.
.......#.....      ....|..#8--7.
...#.......#.      ...#4---3..#.
........#....      ........#....
```

For the actual walking it's necessary to get the closest obstacle in the current walking direction. If none is found, the map is exited. This is one of the situations where the declarative nature of SQL is quite handy. One approach to do this in Python is to collect all obstacles and map an (ordered) list of their y/x positions by their x/y position. This requires iterating the whole map to collect all obstacles, but roughly half is already iterated to find the starting position and [day 4](../day-04_ceres-search#day-4-ceres-search) showed that additional iterations aren't necessarily impacting performance. But I don't expect a huge improvement from this approach.
```
  012345678    Obstacles by
0 .#.......    x          y
1 ....#..#.    0: 7       0: 1
2 .........    1: 0       1: 4, 7
3 ....#....    3: 4       3: 4
4 ...#....#    4: 1, 3    4: 3, 8
5 .........    7: 1, 8    7: 0
6 ....^....    8: 4       8: 7
7 #........
8 .......#.
```

The closest obstacle in the current direction can be found by simply iterating the list of obstacles for the current position or with an [adapted binary search](https://en.wikipedia.org/wiki/Binary_search#Approximate_matches). An example doesn't really help when there are only a few obstacles in a line, so below is one line from a larger map.
```
..#........#....#.......#......#..>.#..#..#.......

Position and direction
x: 34, dx: 1

           0  1   2   3   4   5   6   7
Obstacles: 2, 11, 16, 24, 31, 36, 39, 42
Midpoint is 3 (or 4)

O[3]: 24 < 34 -> continue to right
O[5]: 36 > 34 -> continue to left
O[4]: 31 < 34

Predecessor: 31, Successor: 36
Next position: 36 - 1 = 35
```
This already feels a lot like handrolling tables and indexes in DB. There probably is a tree structure that is more efficient, but I find this more accessible.

TODO ... data for part 2 ...

#### Part 2

part 2: check different optimizations

### SQL Solution

#### Original Approach

- Runtime via `perf stat -r 10 -B duckdb -f solution.original.sql`
  - DuckDB v1.2.2 7c039464e4
    - Both parts: **14.645** +- 0.114 seconds (+- 0.78%)
    - Only part 1: **0.49385** +- 0.00488 seconds (+- 0.99%)
  - DuckDB v1.3.1 2063dda3e6
    - Both parts: **13.187** +- 0.126 seconds (+- 0.96%)
    - Only part 1: **0.51725** +- 0.00533 seconds (+- 1.03%)
- Input data: Table with x, y coordinates and the symbol in the grid
- Rough approach part 1
  - Raywalking with collecting "steps on the axis" on the fly (generate_series)
    - Limited to single cursor while walking
    - Complex "cross join" (case when, order by limit 1) to find nearest obstacle
  - Collect all visited tiles (including duplicate positions) by exploding previous "steps on axis" to a table
  - Count distinct on visited tiles is result for part 1
- Rough approach part 2
  - Build dataset of all viable obstacle positions, direction at that time and the previous positions on the path
    - Based on dataset of all visited tiles
    - Entries of path are encoded as strings `x|y|dir` via `MACRO` (no trust in tuples at the time I guess)
    - Obstacles need to be deduplicated for each positions based on order of occurence to satisfy condition that obstacle must be placed before walking starts
  - Place obstacle and perform same raywalking approach from part 1 until loop is detected or walking terminates
    - New obstacle must be considered when finding nearest obstacle since it can be hit more than the one time at the start
    - Only considered previously visited tiles, not future tiles that guarantee termination without loop (tile of set `E`)
    - Runs all obstacles in parallel

#### Reworking Part 1

- Runtime of naive approach: **4.5222** +- 0.0780 seconds (+- 1.72%)
  - `INNER JOIN` on set of all tiles on next position terminates recursive CTE
  - Using a `VIEW` for tiles instead of a `TABLE` increases runtime to ~18s

#### Reworking Part 2

### Stats

|                                       Variant | Runtime[^runtime] | LoC[^loc] |
| --------------------------------------------: | ----------------- | --------- |
|                         [SQL](./solution.sql) |                   |           |
|       [Original SQL](./solution.original.sql) | ~15s              | ~300      |
|     [Python - Seeking](./solution.py#L19-L37) |                   |           |
| [Python - Single Loop](./solution.py#L40-L83) |                   |           |
|      [Python - Naive](./solution.py#L86-L134) |                   |           |

[^runtime]: Running `time <cmd to run solution>` several times and averaging by eyesight.
[^loc]: Number of non-empty lines (comments count) using `grep -cve '^\s*$' *.{sql,py}`. For Python it's the sum of the test and solution file, but only counting the lines used by the approach.
