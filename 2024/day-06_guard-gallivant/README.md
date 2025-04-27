[**Day 6: Guard Gallivant**](#day-5-guard-gallivant)</br>
&ensp;&ensp;[Part 1](#part-1)</br>
&ensp;&ensp;[Part 2](#part-2)</br>
[**Python Solution**](#python-solution)</br>
&ensp;&ensp;[Part 1](#part-1-1)</br>
&ensp;&ensp;&ensp;&ensp;[_Intuitive Approach_](#intuitive-approach)</br>
&ensp;&ensp;&ensp;&ensp;[_Raywalking Approach_](#raywalking-approach)</br>
&ensp;&ensp;[Part 2](#part-2-1)</br>
[**SQL Solution**](#sql-solution)</br>
&ensp;&ensp;[Original Approach](#original-approach)</br>
&ensp;&ensp;[Improving the Original SQL Solution](#improving-the-original-sql-solution)</br>
[**Stats**](#stats)</br>

### Day 6: Guard Gallivant

This is the first 2D grid puzzle of 2024. A common problem class of AoC, but each has something that makes them feel novel. This one is no exception, with a very interesting [part 2](#part-2). Even though this doesn't need any (shortest) pathfinding, 2D grid puzzles seemed quite intimidating to solve with SQL. All of this together made this quite the (eraly) challenging day. As always see the [original puzzle text](https://adventofcode.com/2024/day/6) for all the details.

The input is a map where `#` are obstacles, `.` walkable tiles and `^` the starting position and direction. For example:
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
- When an obstacle is encountered turn right and continue

Here is the example when the 4th obstacle is encountered, the movement would be continued upwards:
```
....#.....
.........#
..........
..#.......
.......#..
..........
.#<.......
........#.
#.........
......#E..
```
This goes on until the map is exited at tile `E`. And no, part 2 is not about wrapping around the edges.

#### Part 1

Since this is only day 6, part 1 starts off easy. The task is to count the number of **distinct tiles** that were visited before leaving the map (including the starting position). The only thing to keep in mind is to not count tiles multiple times, so a simple step count won't do. Below is the path when encountering the 4th obstacle and after leaving the map. Visited tiles are marked as `x` or `X`, if visited more than once. A total of **41** distinct tiles are visited.
```
....#.....      ....#.....
....xxxxx#      ....xxxxx#
....x...x.      ....x...x.
..#.x...x.      ..#.x...x.
....x..#x.      ..xxXxx#x.
....x...x.      ..x.x.x.x.
.#<xXxxxx.      .#xxXxXxx.
........#.      .xxxxxXx#.
#.........      #xxxxxxx..
......#...      ......#x..
```

An edge case that isn't shown in the example is that encountering two obstacles consecutively results in a 180 degree turn.
```
Map             Path      
...#......      .x.#......
#.......#.      #xxXXXXX#.
.......#..      ...x...#..
...^......      ...x......
..........      ..........
```

#### Part 2

Now for the twist of part 2, where the objective is to introduce loops by placing a (single) new obstacle on the map. I didn't expect this and usually when doing pathfinding stuff loops are something to avoid or to detect and prune. Here it's about provoking them instead. This is what I meant with each puzzle bringing something novel to this class of problems. The solution for part 2 is the total number of loops that can be created by placing a single new obstacle on the given map. For the example the count is **6**. A few of them are shown below, with `O` marking the obstacle creating the loop and `-`, `|` and `+` showing the path.
```
....#.....      ....#.....      ....#.....
....+---+#      ....+---+#      ....+---+#
....|...|.      ....|...|.      ....|...|.
..#.|...|.      ..#.|...|.      ..#.|...|.
....|..#|.      ..+-+-+#|.      ..+-+-+#|.
....|...|.      ..|.|.|.|.      ..|.|.|.|.
.#.O^---+.      .#+-^-+-+.      .#+-^-+-+.
........#.      ......O.#.      ....|.|.#.
#.........      #.........      #..O+-+...
......#...      ......#...      ......#...
```

Note that the third loop consists of more than 4 segments. It's also possible to have loops with fewer segments.
```
Map         Path        Loop  
......      ...x..      ......
.#..#.      .#.x#.      .#..#.
.....#      .xxXx#      .+--+#
......      .x.xx.      .|..|.
.^#...      .x#xx.      .^#O+.
....#.      ....#.      ....#.
```

Loops don't have to be composed of segments of the original path, but can be on portions on the map that are only accessible by the newly placed obstacle.
```
Map            Loop     
.........      .........
....#....      .O..#....
.......#.      .+--+-+#.
...#.....      .|.#+-+..
......#..      .|....#..
.^.......      .^.......
.........      .........
```

But what's not completely obvious (at least it wasn't to me), is that the obstacle must be placed before starting to move. So the following is **not valid** and wouldn't count towards the total number of loops.
```
Map                Path               Loop         
.#...........      .#....x......      .#...........
............#      .xxxxxXxxxxx#      .+----O̶----+#
.^..........#      .x....x....x#      .^....+----+#
.....#.......      .....#xxxxxx.      .....#+----+.
...........#.      ...........#.      ...........#.
```

Or a more extreme example.
```
Map           Path          Loop    
.#...#..      .#...#..      .#...#..
......#.      xXXXXX#.      .+--O̶+#.
.....#..      .x...#..      .|...#..
.^......      .^......      .^......
........      ........      ........
```

**Approach**

The brute force approach would be to try every empty tile, place the obstacle there and run the movements until the map is exited or the step count exceeds a threshold which would be counted as a loop (e.g. the total area of the map). This can be improved (duh) in two regards. Reducing the number of tiles to place the obstacle on and reducing the number of steps necessary to detect (or reject) a loop.

Reducing the number of viable tiles is simple enough. For the obstacle to have any effect it must be encountered, so only tiles collected during part 1 have to be tested. As mentioned before the obstacle must be placed before starting to move, so it's sufficient to test each tile once.

To reduce the number of necessary steps before knowing that placing the obstacle did or did not create a loop it helps to look at the anatomy of an obstacle placement. Given the original path from part 1, placing an obstacle splits it into two sets. A set of tiles `W` visited before encountering the obstacle and a set of tiles `E` that would have been visited, ultimately leading off the map. In the example below tiles of these sets are marked as `w` and `e` or `z`, if contained in both sets. A third set of tiles `O` contains all tiles visted after encountering the new obstacle. In the example below those are marked as `o` (overwriting other symbols).
```
..#...#.......      ..#...#.......      ..#...#.......
.#....+------E      .#....eeeeeeee      .#....eeeeeeee
.+----+---+#..      .wwwwwz>Oee#..      .wwwwwzoOee#..
.|....|..#|...      .w....e..#e...      .w....eo.#e...
.|...#+---+...      .w...#eeeee...      .w...#eoeee...
.^......#.#...      .w......#.#...      .w.....o#.#...
..............      ..............      .......o......
```

This already shows that it won't be enough to store the tile positions, the direction when the tile was visited is necessary as well. All that can be used to create rules to determine if a loop has been created, but also if it is guaranteed to leave the map. Note that in those rules "revisiting a tile" is meant as being in the same position having the same direction.

- Revisiting a tile of set `W` or `O` will always result in a loop
- Revisiting a tile of set `E` wil always exit the map

Other situations need to be explored fully, since loops can be arbitrarily long or the obstacle leads to a far away portion of the map with a "natural" loop. Below are some examples with `X` marking the tile matching the rule.
```
Revisiting a tile of set E
..#...#.......      ..#...#.......      ..#...#.......
.#....+------E      .#....eeeeeeee      .#....eeeeeeee
.O----+---+#..      .Oeeeeeeeee#..      .Oeeeeeeeee#..
.|....|..#|...      .^....e..#e...      .oooooooo#e...
.|...#+---+...      .w...#eeeee...      .w...#eXoee...
.^......#.#...      .w......#.#...      .w......#.#...
..............      ..............      ..............

Revisiting a tile of set W
..#...#.......      ..#...#.......      ..#...#.......
.#....O------E      .#....Oeeeeeee      .#....Oeeeeeee
.+----+---+#..      .wwwww^wwww#..      .wwwwwoXwww#..
.|....|..#|...      .w....w..#w...      .w....w..#w...
.|...#+---+...      .w...#wwwww...      .w...#wwwww...
.^......#.#...      .w......#.#...      .w......#.#...
..............      ..............      ..............

..#...#.......      ..#...#.......      ..#...#.......
.#....+--O---E      .#....ww>Oeeee      .#....wwoOeeee
.+----+---+#..      .wwwwwwwwww#..      .wwwwwwwoww#..
.|....|..#|...      .w....w..#w...      .w....w.o#w...
.|...#+---+...      .w...#wwwww...      .w...#wXoww...
.^......#.#...      .w......#.#...      .w......#.#...
..............      ..............      ..............

Revisiting a tile of set O
..#...#.......      ..#...#.......      ..#...#.......
.#....+-----OE      .#....wwwww>Oe      .#oXooooooooOe
.+----+---+#..      .wwwwwwwwww#..      .wwwwwwwwww#..
.|....|..#|...      .w....w..#w...      .w....w..#w...
.|...#+---+...      .w...#wwwww...      .w...#wwwww...
.^......#.#...      .w......#.#...      .w......#.#...
..............      ..............      ..............
```

So much for the theory, on to actually doing things.

### Python Solution

#### Part 1

##### Intuitive Approach

Part 1 is pretty straightforward, but there are still a few things to play around with. The intuitive approach is to simply walk the map according to the rules. The first question is how to collect the visited tiles without overcounting. I see three different ways to do that, the runtimes are the average of 1000 runs using `timeit` excluding IO from reading the input, but including parsing the input:
1. **Using a set**, letting Python take care of the deduplication 
    - When creating entries with `f'{x},{y}'`: _0.00320s_
    - When creating entries with `(x,y)`: _0.00176s_
2. **Using a list** while walking and deduplicate once after exiting the map with `set`
    - When creating entries with `f'{x},{y}'`: _0.00300s_
    - When creating entries with `(x,y)`: _0.00175s_
3. **Using a boolean grid** to track which tiles have been visited
    - Collecting positions, creating entries with `f'{x},{y}'`: _0.00280s_
    - Collecting positions, creating entries with `(x,y)`: _0.00162s_
    - Only incrementing a counter: _0.00144s_

This shows that using a string to represent a position is a lot more costly than using a tuple and that it doesn't seem to matter, whether a set is used from the start or only at the end to determine the total count of visited tiles. Solving part 1 only requires the number visited tiles, but the list of positions and directions is useful for part 2. This is the main reason to I decided to stick with approach 3, so I that the direction doesn't have to be excluded when calculating the hash during deduplication.

The final implementation of this approach builds a list of visited tiles with the information necessary for part 2 and takes _0.00310s_ in isolation and **~0.075s** with IO.

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

#### Improving the Original SQL Solution

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
