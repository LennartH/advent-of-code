[**Day 5: Guard Gallivant**](#day-5-guard-gallivant)</br>
&ensp;&ensp;[Part 1](#part-1)</br>
&ensp;&ensp;[Part 2](#part-2)</br>
[**Python Solution**](#python-solution)</br>
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
This goes on until the map is exited (marked as `E`). And no, part 2 is not about wrapping around the edges.

#### Part 1

Since this is only day 6, part 1 starts of easy. The task is to count the number of **distinct tiles** that were visited before leaving the map (including the starting position). The only thing to keep in mind is to not count tiles multiple times, so a simple step count won't do. Below is the path when encountering the 4th obstacle and after leaving the map. Visited tiles are marked as `x` or `X`, if visited more than once. A total of **41** distinct tiles are visited.
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

Now for the twist of part 2, I already said it's not about wrapping around the map edges, instead it's about introducing loops, by placing a new obstacle on the map. I didn't expect this and usually loops are things to avoid when doing pathfinding related stuff. This is what I meant with that each puzzle brings something novel to this problem class. The answer for part 2 is the total number of loops that can be introduced for the given map. For the small example a total of **6** loops can be created. A few of them are shown below, with `O` marking the obstacle creating the loop and `-`, `|` and `+` showing the path.
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

So much (and it is a lot) for the theory, let's see what that actually does in praxis.

### Python Solution

part 1:
- collecting in set vs collecting in list and only count via set
- naive walking vs "raywalking" / collecting obstacles and iterating them

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
