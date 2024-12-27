### 2024: SQL with DuckDB

I decided to do AoC 2024 with SQL, partially because my SQL has gotten a bit rusty, partially as a challenge and partially out of curiosity
how these kind of problems can be solved in SQL. I chose DuckDB because it's [easy to setup](https://duckdb.org/why_duckdb#simple),
[reasonably fast](https://duckdb.org/why_duckdb#fast) and has some [nice QoL features](https://duckdb.org/docs/sql/dialect/friendly_sql).

- I did the previous years in TypeScript using a [template](../template/typescript/day-{{day}}_{{title}}/index.test.ts) with separate
tests for example and real input for both parts and tried to replicate something similar for my SQL template, which is probably not a
common use case. I found a [somewhat comparable setup](../template/duckdb/day-{{day}}_{{title}}/solution.sql) using variables and
some utility functions, but it definetely adds some bloat.
- DuckDB also has some unusual features (e.g. [MACROs](https://duckdb.org/docs/sql/statements/create_macro),
[list comprehensions](https://duckdb.org/docs/sql/functions/list#list-comprehension) and [lambdas](https://duckdb.org/docs/sql/functions/lambda)),
but using them felt a bit like cheating, so I tried to limit their usage as much as possible (except for troubleshooting/debugging).
- As soon as there is some kind of repetition involved, there's only one tool in the box (and it's a hammer), [recursive CTEs](https://duckdb.org/docs/sql/query_syntax/with#recursive-ctes).
No imperative elements like some [other SQL dialects](https://www.postgresql.org/docs/current/plpgsql-control-structures.html#PLPGSQL-CONTROL-STRUCTURES-LOOPS).
So you're using that hammer, even if the assignment is to write something on a piece of paper. You also have to think differently about
"looping over stuff and doing things", because recursive CTEs have some restrictions.
  - Basically they are split into two parts, the first sets up the initial state (e.g. for _day 10_ [all coordinates with height 0](https://github.com/LennartH/advent-of-code/blob/f448e1166d9805e763a45414f0561e26788472c0/2024/day-10_hoof-it/solution.sql#L34-L40))
  and the second part is "called with the previous state" and produces the next one. This continues until the that second parts results
  in 0 records and in the end all states are combined with the specified set operation (e.g. `UNION`) to the final result.
  - This means you're logic can only access the information of the previous iteration and if you need stuff from before (e.g. "jumping wires" in _day 24_)
  you have to either [duplicate them](https://github.com/LennartH/advent-of-code/blob/f448e1166d9805e763a45414f0561e26788472c0/2024/day-24_crossed-wires/solution.sql#L142-L156) (_day 24_)
  in each iteration or [integrate some context](https://github.com/LennartH/advent-of-code/blob/f448e1166d9805e763a45414f0561e26788472c0/2024/day-09_disk-fragmenter/solution.sql#L130-L150) (_day 9_)
  in the records themselves. This makes memoization practically impossible (for me).
  - As soon as the second part isn't running out on it's own (`LEFT JOIN`, dragging state through each step), you'll also have to manage the
  query termination explicitly. That's easy enough if you want to [do something N times](https://github.com/LennartH/advent-of-code/blob/f448e1166d9805e763a45414f0561e26788472c0/2024/day-14_restroom-redoubt/solution.sql#L51-L67) (_day 14_),
  but can also be [a bit tricky](https://github.com/LennartH/advent-of-code/blob/f448e1166d9805e763a45414f0561e26788472c0/2024/day-12_garden-groups/solution.sql#L141-L147) (_day 12_)
  or [very tricky](https://github.com/LennartH/advent-of-code/blob/f448e1166d9805e763a45414f0561e26788472c0/2024/day-24_crossed-wires/solution.sql#L165-L171) (_day 24_)
  without terminating too early or the records you want are dropped before making it into the final result.


**The Good**

- In general DB engines are quite good at doing things "broad". Like doing the same thing to a lot of stuff and as long as it's
not too complicated and you don't have to collect and unnest lists all the time it doesn't matter that much if a lot of records
are created along the way (although space requirements are probably a lot higher compared to other languages)
  - For example [generating the random numbers](https://github.com/LennartH/advent-of-code/blob/f448e1166d9805e763a45414f0561e26788472c0/2024/day-22_monkey-market/solution.sql#L27-L56)
  for _day 22_ creates ~4 million (~200 MiB) records in ~0.4 seconds and [simulating the robot movements](https://github.com/LennartH/advent-of-code/blob/f448e1166d9805e763a45414f0561e26788472c0/2024/day-14_restroom-redoubt/solution.sql#L47-L77)
  for _day 14_ results in ~5 million records (~300 MiB) in ~2 seconds
  - But it's useful beyond crunching "a lot" of data. Going broad by default means a lot of things can be tested at the same time,
  for example [searching the input](https://github.com/LennartH/advent-of-code/blob/f448e1166d9805e763a45414f0561e26788472c0/2024/day-17_chronospatial-computer/solution.sql#L156-L193)
  that prints the program for _day 17_ "octet-wise" checks all 8 possible values simultaneously at once essentially walking down
  the tree row by row
- Having access to all the data, including from steps inbetween, by default (except within recursive CTEs) can be very convenient.
And of course being able to run complex/arbitrary queries is extremely powerful.
  - For _day 10_, using a naive BFS pathfinding for all trails provides [everything you need](https://github.com/LennartH/advent-of-code/blob/f448e1166d9805e763a45414f0561e26788472c0/2024/day-10_hoof-it/solution.sql#L57-L73)
  to solve both parts without much hassle
  - Similar with [finding the best seats](https://github.com/LennartH/advent-of-code/blob/f448e1166d9805e763a45414f0561e26788472c0/2024/day-16_reindeer-maze/solution.sql#L136-L169)
  for _day 16_, since not only the shortest path is kept, but everything that has been searched but discarded, makes it a lot
  easier to reconstruct the other paths with equal length
  - SQLs power got blatantly obvious to me on _day 22_. [Finding the optimal sequence](https://github.com/LennartH/advent-of-code/blob/f448e1166d9805e763a45414f0561e26788472c0/2024/day-22_monkey-market/solution.sql#L58-L89)
  of price changes was practically trivial with SQL handling all the relationships between the data points behind the scenes. Very neat.


**The Bad**

- With all that, it's probably not surprising that SQL gets in your way when you want to do something depth-first. Like when a BFS
pathfinding would explode due to too many possible next moves or if you want to get some result as early as possible to reuse it later.
Doing something with a single record and then doing the same stuff with the next one just isn't natural for SQL (or for me when trying
to do that with SQL) and if what you're doing is a bit complex or costly, performance takes a serious hit.
  - I think _day 20_ is a good example for that. The racetrack has a single path, but a [naive pathfinder](https://github.com/LennartH/advent-of-code/blob/f448e1166d9805e763a45414f0561e26788472c0/2024/day-20_race-condition/solution.sql#L54-L88)
  takes ~10 seconds and optimizing by [jumping ahead to the next wall](https://github.com/LennartH/advent-of-code/blob/f448e1166d9805e763a45414f0561e26788472c0/2024/day-20_race-condition/solution.sql#L90-L139)
  still needs 6-7 seconds. The path is nearly 10000 tiles long, but simulating movements of 500 robots for 10000 steps only takes ~2 seconds.
  It's not like using an A* would help and I'm not even maintaining an expensive data structure to track the visited tiles, because I
  just have to prevent going backwards. I'm pretty sure this can be improved by starting the search from multiple points, joining paths
  on contact, I might try that in the future.
  - I tried to solve _day 9_ differently, but in the end I had to surrender and move the files [one at a time](https://github.com/LennartH/advent-of-code/blob/f448e1166d9805e763a45414f0561e26788472c0/2024/day-09_disk-fragmenter/solution.sql#L109-L151)
  which got quite costly, because it's necessary to track how much space is already occupied in each gap. I'm using a MAP for that
  ([which thankfully exists](https://duckdb.org/docs/sql/data_types/map)), but it needs to be dragged (and thus copied) through all
  10000 iterations. Again there are definitely ways to improve this (e.g. iterating over the gaps instead of a single file maybe?),
  I'm hoping to get to play around with.
  - But in regards of performance impact the crown goes to _day 15_. This one is responsible for nearly 60% of the total runtime
  of all 2024 solutions needing ~4 minutes of the ~7 minutes total. [Walking a single robot](https://github.com/LennartH/advent-of-code/blob/f448e1166d9805e763a45414f0561e26788472c0/2024/day-15_warehouse-woes/solution.sql#L197-L301)
  through a warehouse step by step with each step being potentially very expensive, because another recursive CTE is needed to
  collect all boxes that have to move or alternatively find out that it behaves like a wall. That query alone is 100 lines long.
  No idea how to improve that one, but I'm sure there is something.
- I don't think SQL is bad because of that, it just shows that you need to think differently about how to get things done and
that you need to approach problems from unusual directions.
- The only really bad thing I have to say about SQL is that it has just awful ergonomics. To understand a query you need to start
reading somewhere from the middle (and it has to be the right middle as well) and continue upwards and downwards at the same time.
It absolutely makes sense that what you're grouping by is specified at the very end, but what you're doing with those groups is at
the start of the query. Put a [subquery in the middle](https://github.com/LennartH/advent-of-code/blob/f448e1166d9805e763a45414f0561e26788472c0/2024/day-11_plutonian-pebbles/solution.sql#L36-L55)
and you can be sure that everyone has to read that at least three times to get an idea about what's going on. Common table
expressions help, but my point remains.


**The** ~~Ugly~~ **Remarkable**

- _Day 6_ was an early curveball. Not only was it the first time to do some kind of pathfinding, causing loops instead of preventing
them made things extra spicy. Took me nearly two days to get that done and putting in the work to get [some kind of visual represenation](https://github.com/LennartH/advent-of-code/blob/f448e1166d9805e763a45414f0561e26788472c0/2024/day-06_guard-gallivant/solution.sql#L230-L335)
was mandatory.
- Another tough one was _day 12_ (again around two days), because I couldn't wrap my head around how to find the connected components
using a BFS without exploding into millions of duplicate records or tracking which tiles have already been visited in a DFS. In
the end I resorted to implementing a simplified contraction algorithm from [this paper](https://arxiv.org/pdf/1802.09478). It was a
lot of fun to build the [sides detection](https://github.com/LennartH/advent-of-code/blob/f448e1166d9805e763a45414f0561e26788472c0/2024/day-12_garden-groups/solution.sql#L163-L273)
logic and I find my approach quite neat (no recursive CTE necessary), even though it isn't really concise with over 100 lines.
All those optimizations payed of, because the solution runs in ~1 second, but the [python variant](https://github.com/LennartH/advent-of-code/blob/f448e1166d9805e763a45414f0561e26788472c0/2024/day-12_garden-groups/solution.py)
with a simple floodfill and direct translation of the side finding approach only takes ~0.15 seconds (and around 150 lines shorter).
- The most difficult puzzle for me this year was _day 21_ by far. I chewed on that one for a few days before I had to put it aside
and continue with the other days. In fact _day 21_ was the last one I solved before picking up my 50th star (for the first time). At
times I had over 1000 lines of commented code with previous attempts and explorative queries. I only got it to work, after looking
up the optimal moves for the directional keypad and [manually define](https://github.com/LennartH/advent-of-code/blob/f448e1166d9805e763a45414f0561e26788472c0/2024/day-21_keypad-conundrum/solution.sql#L113-L157)
them to eliminate branching, so calculating the amount of button presses 25 robots deep doesn't explode or scramble the histogram.
This one is definitely on the "revisit later" list.
- My personal highlight was _day 15_ despite it being my longest running and probably most convoluted solution. I had a blast building
part 1 and the twist for part 2 was just awesome. I can see why some don't get a lot out of these kind of challenges, but for me
this was the perfect balance between [incremental progress and insanity](https://github.com/LennartH/advent-of-code/blob/f448e1166d9805e763a45414f0561e26788472c0/2024/day-15_warehouse-woes/solution.sql#L242-L247).


**Now What?**

- Clean up the remaining "very bad stuff" ([I'm looking at you](https://github.com/LennartH/advent-of-code/blob/f448e1166d9805e763a45414f0561e26788472c0/2024/day-13_claw-contraption/solution.sql#L175-L186) _day 13_)
- There are a lot of ideas I had to leave behind I'd like to pick up again and approaches from other people to try out
  - Finally get a working A* implementation (e.g. for _day 18_ instead of [limiting the number of tracks](https://github.com/LennartH/advent-of-code/blob/f448e1166d9805e763a45414f0561e26788472c0/2024/day-18_ram-run/solution.sql#L127-L136)
  for the BFS)
  - Implement Bron Kerbosch (or something comparable) to solve the max clique problem for _day 23_
  - [Other stuff](https://github.com/search?q=repo%3ALennartH%2Fadvent-of-code+path%3A%2F%5E2024%5C%2F%2F+TODO+OR+FIXME&type=code)
- Revisit the early days to see if I would do things differently now
- Try to find faster solutions for the >10 seconds days
- Implement the solutions in Python for comparison
- Implement the solutions with as much of the fancy stuff (MACROS, lambdas, etc.) as I want to see if that changes anything

Let's see how much of that I'm actually going to do.



### Running a Solution

- You need to have [DuckDB installed](https://duckdb.org/docs/installation), the solutions were implemented with version 1.1.3
- You're input needs to be in a file with name `input` in the same directory as the `solution.sql` file
    - Alternatively you can change the `mode` variable to `example` in the SQL file
- To execute the SQL do one of the following:
    - `cd` into the directory for the day and run `duckdb < solution.sql`
    - Run the script `run.sh` with the day number as first argument (e.g. `./run.sh 5` or `./run.sh day-21`)

#### Runtimes

Times are for both parts including DuckDB startup and reading the input from file measured with `time duckdb < solution.sql` (system info: AMD Ryzen 7 2700X, 32 GiB memory)
|                                                                                                                                    Day | Runtime |
| -------------------------------------------------------------------------------------------------------------------------------------: | ------- |
|          [Day 1: Historian Hysteria](https://github.com/LennartH/advent-of-code/blob/main/2024/day-01_historian-hysteria/solution.sql) | ~0.03s  |
|            [Day 2: Red-Nosed Reports](https://github.com/LennartH/advent-of-code/blob/main/2024/day-02_red-nosed-reports/solution.sql) | ~0.08s  |
|                      [Day 3: Mull It Over](https://github.com/LennartH/advent-of-code/blob/main/2024/day-03_mull-it-over/solution.sql) | ~0.02s  |
|                      [Day 4: Ceres Search](https://github.com/LennartH/advent-of-code/blob/main/2024/day-04_ceres-search/solution.sql) | ~0.02s  |
|                        [Day 5: Print Queue](https://github.com/LennartH/advent-of-code/blob/main/2024/day-05_print-queue/solution.sql) | ~0.85s  |
|                [Day 6: Guard Gallivant](https://github.com/LennartH/advent-of-code/blob/main/2024/day-06_guard-gallivant/solution.sql) | ~15s    |
|                    [Day 7: Bridge Repair](https://github.com/LennartH/advent-of-code/blob/main/2024/day-07_bridge-repair/solution.sql) | ~45s    |
|    [Day 8: Resonant Collinearity](https://github.com/LennartH/advent-of-code/blob/main/2024/day-08_resonant-collinearity/solution.sql) | ~0.04s  |
|                [Day 9: Disk Fragmenter](https://github.com/LennartH/advent-of-code/blob/main/2024/day-09_disk-fragmenter/solution.sql) | ~40s    |
|                               [Day 10: Hoof It](https://github.com/LennartH/advent-of-code/blob/main/2024/day-10_hoof-it/solution.sql) | ~0.2s   |
|           [Day 11: Plutonian Pebbles](https://github.com/LennartH/advent-of-code/blob/main/2024/day-11_plutonian-pebbles/solution.sql) | ~0.7s   |
|                   [Day 12: Garden Groups](https://github.com/LennartH/advent-of-code/blob/main/2024/day-12_garden-groups/solution.sql) | ~1s     |
|             [Day 13: Claw Contraption](https://github.com/LennartH/advent-of-code/blob/main/2024/day-13_claw-contraption/solution.sql) | ~0.15s  |
|             [Day 14: Restroom Redoubt](https://github.com/LennartH/advent-of-code/blob/main/2024/day-14_restroom-redoubt/solution.sql) | 2-3s    |
|                 [Day 15: Warehouse Woes](https://github.com/LennartH/advent-of-code/blob/main/2024/day-15_warehouse-woes/solution.sql) | ~4m     |
|                   [Day 16: Reindeer Maze](https://github.com/LennartH/advent-of-code/blob/main/2024/day-16_reindeer-maze/solution.sql) | ~24s    |
| [Day 17: Chronospatial Computer](https://github.com/LennartH/advent-of-code/blob/main/2024/day-17_chronospatial-computer/solution.sql) | ~4.5s   |
|                               [Day 18: RAM Run](https://github.com/LennartH/advent-of-code/blob/main/2024/day-18_ram-run/solution.sql) | ~11.5s  |
|                     [Day 19: Linen Layout](https://github.com/LennartH/advent-of-code/blob/main/2024/day-19_linen-layout/solution.sql) | ~4.75s  |
|                 [Day 20: Race Condition](https://github.com/LennartH/advent-of-code/blob/main/2024/day-20_race-condition/solution.sql) | ~11s    |
|             [Day 21: Keypad Conundrum](https://github.com/LennartH/advent-of-code/blob/main/2024/day-21_keypad-conundrum/solution.sql) | ~0.1s   |
|                   [Day 22: Monkey Market](https://github.com/LennartH/advent-of-code/blob/main/2024/day-22_monkey-market/solution.sql) | ~1.5s   |
|                           [Day 23: Lan Party](https://github.com/LennartH/advent-of-code/blob/main/2024/day-23_lan-party/solution.sql) | ~22s    |
|                   [Day 24: Crossed Wires](https://github.com/LennartH/advent-of-code/blob/main/2024/day-24_crossed-wires/solution.sql) | ~0.3s   |
|                 [Day 25: Code Chronicle](https://github.com/LennartH/advent-of-code/blob/main/2024/day-25_code-chronicle/solution.sql) | ~0.07s  |
|                                                                                                                              **Total** | ~7m 5s  |
