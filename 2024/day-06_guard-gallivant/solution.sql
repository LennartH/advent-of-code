SET VARIABLE example = '
    ....#.....
    .........#
    ..........
    ..#.......
    .......#..
    ..........
    .#.x^.....
    ......xx#.
    #x.x......
    ......#x..
';
SET VARIABLE exampleSolution1 = 41;
SET VARIABLE exampleSolution2 = 6;

-- -- Example with multiple obstacles in same line
-- SET VARIABLE example = '
--     .#.......
--     ....#..#.
--     .........
--     x...#....
--     ...#....#
--     .......x.
--     ....^....
--     #..x.....
--     .......#.
-- ';
-- SET VARIABLE exampleSolution1 = 27;
-- SET VARIABLE exampleSolution2 = 3;

-- -- Loop when placing obstacle on visited cell
-- SET VARIABLE example = '
--     .#............
--     ......x......#
--     .^...........#
--     .....#........
--     ............#.
-- ';
-- SET VARIABLE exampleSolution1 = 23;
-- SET VARIABLE exampleSolution2 = 1;

-- -- Loop between 2 points
-- SET VARIABLE example = '
--    ......
--    .#..#.
--    .....#
--    .^#x..
--    ....#.
-- ';
-- SET VARIABLE exampleSolution1 = 9;
-- SET VARIABLE exampleSolution2 = 2;

-- -- Loop outside of original path
-- SET VARIABLE example = '
--    ..#.........
--    .........x..
--    ..x...#.....
--    .........#..
--    .....#......
--    ........#...
--    ..^.........
--    ............
-- ';
-- SET VARIABLE exampleSolution1 = 15;
-- SET VARIABLE exampleSolution2 = 2;

-- -- Loop without steps in original path
-- SET VARIABLE example = '
--     .#.........
--     ...........
--     .x.........
--     .........#.
--     ...........
--     #..........
--     ........#..
--     ...........
--     .^.........
--     ...........
-- ';
-- SET VARIABLE exampleSolution1 = 17;
-- SET VARIABLE exampleSolution2 = 2;

-- -- Encountering obstacle multiple times without loop
-- SET VARIABLE example = '
--     .............
--     ......#......
--     ..#..........
--     ......x......
--     ...........#.
--     .............
--     .#....^......
--     ..........#..
-- ';
-- SET VARIABLE exampleSolution1 = 11;
-- SET VARIABLE exampleSolution2 = 0;

-- -- Loop after second obstacle encounter
-- SET VARIABLE example = '
--     ......#....
--     ..#........
--     ......x....
--     .........#.
--     .#....^....
--     ........#..
--     .#.........
--     .....#.....
-- ';
-- SET VARIABLE exampleSolution1 = 8;
-- SET VARIABLE exampleSolution2 = 1;

-- -- Loop with wall from original path
-- SET VARIABLE example = '
--     .#.#.........
--     .......#.....
--     .............
--     #.x.......<..
--     .........#...
--     .#...........
--     ......#.#....
-- ';
-- SET VARIABLE exampleSolution1 = 27;
-- SET VARIABLE exampleSolution2 = 4;

CREATE OR REPLACE VIEW example AS SELECT regexp_split_to_table(trim(getvariable('example'), E'\n '), '\n\s*') as line;

CREATE OR REPLACE TABLE input AS
FROM read_text('input') SELECT regexp_split_to_table(trim(content, E'\n '), '\n\s*') as line;
SET VARIABLE solution1 = 4433;
SET VARIABLE solution2 = 1516;

.maxrows 75
-- SET VARIABLE mode = 'example';
SET VARIABLE mode = 'input';

CREATE OR REPLACE TABLE tiles AS (
-- CREATE OR REPLACE VIEW tiles AS (
    SELECT
        y,
        x: generate_subscripts(symbols, 1),
        symbol: unnest(symbols),
    FROM (
        SELECT
            y: row_number() OVER (),
            symbols: regexp_split_to_array(line, ''),
        FROM query_table(getvariable('mode'))
    )
);

CREATE OR REPLACE TABLE directions AS (
-- CREATE OR REPLACE VIEW directions AS (
    FROM (VALUES 
        ('^', '>', '<',  0, -1, NULL, 1),
        ('>', 'v', '^',  1,  0, (SELECT max(x) FROM tiles), NULL),
        ('v', '<', '>',  0,  1, NULL, (SELECT max(y) FROM tiles)),
        ('<', '^', 'v', -1,  0, 1, NULL)
    ) directions(dir, next_dir, prev_dir, dx, dy, edge_x, edge_y)
);

-- #region Part 1 - Naive Solution
-- v1.2.2 7c039464e4: 4.3820 +- 0.1090 seconds (+- 2.50%)
-- v1.3.1 2063dda3e6: 4.5222 +- 0.0780 seconds (+- 1.72%)

-- 2025-07-16
--   v1.2.2 7c039464e4: 4.0326 +- 0.0652 seconds (+- 1.62%)
--   v1.3.1 2063dda3e6: 4.0518 +- 0.0764 seconds (+- 1.89%)

-- CREATE OR REPLACE TABLE visited_tiles AS (
--     WITH RECURSIVE
--         steps AS (
--             FROM tiles t
--             JOIN directions d ON d.dir = symbol
--             SELECT
--                 step_index: 0,
--                 x, y, dir
--             UNION ALL
--             FROM steps s
--             JOIN directions d USING (dir)
--             -- inner join terminates recursion when leaving grid
--             INNER JOIN tiles t ON t.x = s.x + d.dx AND t.y = s.y + d.dy
--             SELECT
--                 step_index + 1,
--                 x: if(t.symbol = '#', s.x, t.x),
--                 y: if(t.symbol = '#', s.y, t.y),
--                 dir: if(t.symbol = '#', d.next_dir, d.dir),
--         )

--     FROM steps
--     SELECT x, y, dir
-- );
-- #endregion

-- #region Part 1 - Raywalking
-- v1.2.2 7c039464e4:
--    ASOF: 0.68808 +- 0.00510 seconds (+- 0.74%)
--    CASE: 0.17569 +- 0.00397 seconds (+- 2.26%)
--   mathy: 0.24673 +- 0.00552 seconds (+- 2.24%)
-- v1.3.1 2063dda3e6:
--    ASOF: 0.30670 +- 0.01700 seconds (+- 5.54%)
--    CASE: 0.19088 +- 0.00316 seconds (+- 1.65%)
--   mathy: 0.23788 +- 0.00743 seconds (+- 3.13%)

-- 2025-07-16
--   CASE: 0.16991 +- 0.00104 seconds (+- 0.61%)
--    ^-- deduplicated visited tiles: 0.175740 +- 0.000854 seconds (+- 0.49%)

-- CREATE OR REPLACE TABLE ray_steps AS ( -- ~0.140 s
-- -- CREATE OR REPLACE VIEW ray_steps AS (
--     WITH RECURSIVE
--         -- Materialized CTE significantly improves performance
--         -- v1.2.2 7c039464e4
--         --    ASOF: 1.06263 -> 0.68808 (-54%)
--         --    CASE: 0.23304 -> 0.17569 (-32%)
--         --   mathy: 0.28054 -> 0.24673 (-13%)
--         -- v1.3.1 2063dda3e6
--         --    ASOF: 0.30670 -> 0.73319 (+139%)
--         --    CASE: 0.22260 -> 0.19088 (-16%)
--         --   mathy: 0.28820 -> 0.23788 (-21%)
--         steps AS MATERIALIZED (
--             FROM tiles t
--             JOIN directions d ON d.dir = symbol
--             SELECT
--                 step_index: 0,
--                 prev_y: NULL,
--                 prev_x: NULL,
--                 prev_dir: NULL::STRING,
--                 y, x, dir,
--             UNION ALL
--             FROM closest_wall w
--             JOIN directions d USING (dir)
--             SELECT
--                 step_index + 1,
--                 prev_y: w.y,
--                 prev_x: w.x,
--                 prev_dir: w.dir,
--                 y: w.wall_y - d.dy,
--                 x: w.wall_x - d.dx,
--                 dir: d.next_dir,
--         ),

--         -- -- ASOF
--         -- -- v1.2.2 7c039464e4
--         -- --   Not Materialized: 1.06263 +- 0.00580 seconds (+- 0.55%)
--         -- --       Materialized: 0.68808 +- 0.00510 seconds (+- 0.74%)
--         -- -- v1.3.1 2063dda3e6
--         -- --   Not Materialized: 0.30670 +- 0.01700 seconds (+- 5.54%)
--         -- --       Materialized: 0.73319 +- 0.00650 seconds (+- 0.89%)
--         -- closest_wall AS (
--         --     -- TODO is this the best way to use ASOF joins here?
--         --     FROM steps s
--         --     ASOF INNER JOIN tiles w ON w.symbol = '#' AND w.x = s.x AND w.y < s.y
--         --     SELECT s.*, w.x as wall_x, w.y as wall_y
--         --     WHERE s.dir = '^'

--         --     UNION ALL

--         --     FROM steps s
--         --     ASOF INNER JOIN tiles w ON w.symbol = '#' AND w.y = s.y AND w.x > s.x
--         --     SELECT s.*, w.x as wall_x, w.y as wall_y
--         --     WHERE s.dir = '>'

--         --     UNION ALL

--         --     FROM steps s
--         --     ASOF INNER JOIN tiles w ON w.symbol = '#' AND w.x = s.x AND w.y > s.y
--         --     SELECT s.*, w.x as wall_x, w.y as wall_y
--         --     WHERE s.dir = 'v'

--         --     UNION ALL

--         --     FROM steps s
--         --     ASOF INNER JOIN tiles w ON w.symbol = '#' AND w.y = s.y AND w.x < s.x
--         --     SELECT s.*, w.x as wall_x, w.y as wall_y
--         --     WHERE s.dir = '<'
--         -- ),

--         -- CASE
--         -- v1.2.2 7c039464e4
--         --   Not Materialized: 0.23304 +- 0.00968 seconds (+- 4.15%)
--         --       Materialized: 0.17569 +- 0.00397 seconds (+- 2.26%)
--         -- v1.3.1 2063dda3e6
--         --   Not Materialized: 0.22260 +- 0.01500 seconds (+- 6.75%)
--         --       Materialized: 0.19088 +- 0.00316 seconds (+- 1.65%)
--         closest_wall AS (
--             FROM steps s
--             INNER JOIN tiles w ON w.symbol = '#' AND CASE dir
--                 WHEN '^' THEN s.x = w.x AND s.y > w.y
--                 WHEN '>' THEN s.y = w.y AND s.x < w.x
--                 WHEN 'v' THEN s.x = w.x AND s.y < w.y
--                 WHEN '<' THEN s.y = w.y AND s.x > w.x
--             END
--             SELECT 
--                 s.*, 
--                 wall_x: w.x,
--                 wall_y: w.y,
--             ORDER BY abs(s.x - w.x) + abs(s.y - w.y) ASC
--             LIMIT 1
--         ),

--         -- -- mathy
--         -- -- v1.2.2 7c039464e4
--         -- --   Not Materialized: 0.28054 +- 0.00902 seconds (+- 3.22%)
--         -- --       Materialized: 0.24673 +- 0.00552 seconds (+- 2.24%)
--         -- -- v1.3.1 2063dda3e6
--         -- --   Not Materialized: 0.28820 +- 0.02280 seconds (+- 7.91%)
--         -- --       Materialized: 0.23788 +- 0.00743 seconds (+- 3.13%)
--         -- closest_wall AS (
--         --     FROM steps s
--         --     JOIN directions d USING (dir)
--         --     INNER JOIN tiles w 
--         --             ON w.symbol = '#'
--         --            -- in line with current direction (either x-x/y-y is 0 or dy/dx is 0)
--         --            AND (w.y - s.y) * d.dx + (w.x - s.x) * d.dy = 0
--         --            -- is after current position in current direction
--         --            AND (w.y * d.dy > s.y * d.dy OR w.x * d.dx > s.x * d.dx)
--         --     SELECT s.*, w.x as wall_x, w.y as wall_y
--         --     ORDER BY abs(s.x - w.x) + abs(s.y - w.y) ASC
--         --     LIMIT 1
--         -- ),

--         final_step AS (
--             FROM steps s
--             JOIN directions d USING (dir)
--             SELECT
--                 step_index: step_index + 1,
--                 prev_y: y,
--                 prev_x: x,
--                 prev_dir: dir,
--                 y: coalesce(d.edge_y, y),
--                 x: coalesce(d.edge_x, x),
--                 dir,
--             ORDER BY step_index DESC
--             LIMIT 1
--         )

--     FROM steps
--     UNION ALL
--     FROM final_step
--     ORDER BY step_index
-- );

-- CREATE OR REPLACE TABLE visited_tiles AS (
-- -- CREATE OR REPLACE ViEW visited_tiles AS (
--     WITH
--         visited_tiles AS (
--             FROM ray_steps s
--             JOIN directions d ON d.dir = s.prev_dir
--             SELECT
--                 step_index,
--                 tile_index: unnest(generate_series(0, abs(if(dy = 0, prev_x - x, prev_y - y)))) + 1,
--                 y: if(dy = 0, prev_y, unnest(generate_series(prev_y, y, dy))),
--                 x: if(dx = 0, prev_x, unnest(generate_series(prev_x, x, dx))),
--                 dir: s.prev_dir,
--             WHERE step_index != 0
--         )

--     FROM visited_tiles
--     SELECT
--         index: row_number() OVER (ORDER BY step_index, tile_index),
--         *,
--     -- QUALIFY step_index = (FROM visited_tiles SELECT max(step_index)) OR row_number() OVER (PARTITION BY step_index ORDER BY tile_index DESC) != 1
-- );
-- #endregion

-- #region Part 2 - Raywalking
-- v1.2.2 7c039464e4 (no USING KEY):
--   without early pathfinding termination: 7.5202 +- 0.0539 seconds (+- 0.72%)
--   broken early pathfinding termination: 1.4767 +- 0.0268 seconds (+- 1.81%)
--    ^-- result: 1473, expected: 1516
--   early pathfinding termination: 2.4430 +- 0.0166 seconds (+- 0.68%)
-- v1.3.1 2063dda3e6:
--   without early pathfinding termination: 6.23000 +- 0.03600 seconds (+- 0.58%)
--    ^-- without loops USING KEY: 6.4490 +- 0.0100 seconds (+- 0.16%)
--    ^-- without tiles_and_obstacles materialization: 16.9771 +- 0.0874 seconds (+- 0.51%)
--   broken early pathfinding termination: 1.25312 +- 0.00599 seconds (+- 0.48%)
--    ^-- result: 1473, expected: 1516
--   hacky early pathfinding termination: 7.2873 +- 0.0463 seconds (+- 0.63%)
--    ^-- max it: 116 vs. 136 | loops where it > 50: 39 vs. 748

-- 2025-06-27
--   early pathfinding termination: 2.07755 +- 0.00920 seconds (+- 0.44%)
--    ^-- max it: 116 vs. 136 | loops where it > 50: 39 vs. 748
--    ^-- with loops USING KEY: 2.12875 +- 0.00603 seconds (+- 0.28%)
--    ^-- without tiles_and_obstacles materialization: 4.2334 +- 0.0152 seconds (+- 0.36%)
--    ^-- without obstacles materialization: 2.1791 +- 0.0371 seconds (+- 1.70%)
--    ^-- obstacle pruning with window function instead of join: 2.15847 +- 0.00823 seconds (+- 0.38%)
--    ^-- everything materialized: 2.12748 +- 0.00813 seconds (+- 0.38%)
-- 2025-06-28
--   early pathfinding termination: 2.13506 +- 0.00755 seconds (+- 0.35%)
--    ^-- only walls and obstacles: 1.96146 +- 0.00943 seconds (+- 0.48%)
-- 2025-07-16
--   early pathfinding termination: 1.8307 +- 0.0116 seconds (+- 0.63%)
--    ^-- obstacle pruning with window function instead of join: 1.85680 +- 0.00922 seconds (+- 0.50%)
--    ^-- deduplicated visited tiles: 1.8454 +- 0.0101 seconds (+- 0.55%)

-- CREATE OR REPLACE TABLE loops AS (
-- -- CREATE OR REPLACE VIEW loops AS (
--     WITH RECURSIVE
--         visited_tiles_with_path AS (
--             FROM visited_tiles
--             SELECT
--                 *,
--                 path: (FROM ray_steps SELECT list({'y': y, 'x': x, 'dir': dir} ORDER BY step_index)),
--         ),
--         obstacles AS MATERIALIZED (
--             FROM visited_tiles_with_path t
--             JOIN directions d USING (dir)
--             SELECT
--                 index, step_index, tile_index,
--                 y, x, dir,
--                 obstacle_y: y + dy,
--                 obstacle_x: x + dx,
--                 next_dir,
--                 path_before: path[:step_index],
--                 path_after: path[step_index+1:],
--             WHERE '#' != (FROM tiles SELECT symbol WHERE y = obstacle_y AND x = obstacle_x)
--             QUALIFY
--                 row_number() OVER (PARTITION BY obstacle_y, obstacle_x ORDER BY index) = 1
--             -- QUALIFY row_number() OVER (PARTITION BY obstacle_y, obstacle_x ORDER BY index) = 1
--             --     AND row_number() OVER (PARTITION BY step_index ORDER BY tile_index DESC) != 1
--         ),
--         obstacle_path_after_unnested AS (
--             FROM (
--                 FROM obstacles
--                 SELECT
--                     index, obstacle_y, obstacle_x,
--                     path_index: generate_subscripts(path_after, 1),
--                     path_step: unnest(path_after),
--             )
--             SELECT
--                 *,
--                 previous_step: lag(path_step) OVER (PARTITION BY index ORDER BY path_index),
--             QUALIFY previous_step IS NOT NULL
--         ),
--         obstacle_path_after_subsequent_hits AS (
--             FROM obstacle_path_after_unnested
--             SELECT
--                 *,
--                 distance_step_obstacle: abs(path_step.y - obstacle_y) + abs(path_step.x - obstacle_x),
--                 distance_obstacle_prev: abs(obstacle_y - previous_step.y) + abs(obstacle_x - previous_step.x),
--                 distance_step_prev: abs(path_step.y - previous_step.y) + abs(path_step.x - previous_step.x),
--                 obstacle_hit: distance_step_obstacle + distance_obstacle_prev = distance_step_prev,
--             WHERE obstacle_hit
--             QUALIFY
--                 row_number() OVER (PARTITION BY index ORDER BY path_index DESC) = 1
--         ),
--         obstacles_with_path_after_hit AS (
--             FROM obstacles o
--             LEFT JOIN obstacle_path_after_subsequent_hits h USING (index)
--             SELECT
--                 o.* EXCLUDE (path_after),
--                 path_after: if(h.path_index IS NULL, o.path_after, o.path_after[h.path_index+1:]),
--         ),
--         walls_and_obstacles AS MATERIALIZED (
--             FROM tiles t
--             LEFT JOIN obstacles o ON o.obstacle_y = t.y AND o.obstacle_x = t.x
--             SELECT
--                 t.y, t.x, t.symbol,
--                 obstacle_index: o.index,
--             WHERE symbol = '#' OR o.index IS NOT NULL
--         ),
--         loops AS (
--             FROM obstacles_with_path_after_hit
--             SELECT
--                 it: 0,
--                 index,
--                 obstacle_y, obstacle_x,
--                 obstacle_dir: dir,
--                 y, x,
--                 dir: next_dir,
--                 original_path: path_after,
--                 path: list_append(path_before, {'y': y, 'x': x, 'dir': next_dir}),
--                 loop: false,
--                 done: false,
--             UNION
--             FROM loops l
--             JOIN directions d USING (dir)
--             JOIN walls_and_obstacles w ON (w.obstacle_index IS NULL OR w.obstacle_index = l.index) AND CASE l.dir
--                 WHEN '^' THEN l.x = w.x AND l.y > w.y
--                 WHEN '>' THEN l.y = w.y AND l.x < w.x
--                 WHEN 'v' THEN l.x = w.x AND l.y < w.y
--                 WHEN '<' THEN l.y = w.y AND l.x > w.x
--             END
--             SELECT
--                 it: it + 1,
--                 index,
--                 obstacle_y, obstacle_x, obstacle_dir,
--                 y: w.y - d.dy,
--                 x: w.x - d.dx,
--                 dir: d.next_dir,
--                 original_path,
--                 path: list_append(path, {'y': w.y - d.dy, 'x': w.x - d.dx, 'dir': d.next_dir}),
--                 loop: list_contains(path, {'y': w.y - d.dy, 'x': w.x - d.dx, 'dir': d.next_dir}),
--                 done: list_contains(original_path, {'y': w.y - d.dy, 'x': w.x - d.dx, 'dir': d.next_dir}),
--             WHERE NOT l.loop AND NOT l.done
--             QUALIFY
--                 row_number() OVER (PARTITION BY index ORDER BY abs(l.y - w.y) + abs(l.x - w.x)) = 1
--         )
    
--     FROM loops
-- );
-- #endregion

-- #region Part 1 - Precalculated Steps
-- Check commit 3de826cb7edd1a3df9c337a5930aaa13ebccd78e to continue Raywalking with precalculated steps
-- Approach looks promising, but simultaneaously checking all possible obstacles gets complicated with precalculated steps

-- 2025-07-24
--   precalculated steps: 0.19348 +- 0.00146 seconds time elapsed  ( +-  0.75% )
--    ^-- wall_hits not materialized: 0.21892 +- 0.00223 seconds time elapsed  ( +-  1.02% )
--    ^-- walls not materialized: 0.21279 +- 0.00292 seconds time elapsed  ( +-  1.37% )
--    ^-- walls and wall_hits not materialized: 0.25566 +- 0.00801 seconds time elapsed  ( +-  3.13% )
--         ^-- from tiles != #: 0.20190 +- 0.00203 seconds time elapsed  ( +-  1.01% )
--         ^-- wall not exists from tiles: 0.22175 +- 0.00325 seconds time elapsed  ( +-  1.47% )
--         ^-- not wall exists from tiles: 0.22577 +- 0.00389 seconds time elapsed  ( +-  1.72% )
--    ^-- from tiles != #: 0.20109 +- 0.00441 seconds time elapsed  ( +-  2.19% )
--    ^-- wall not exists from tiles: 0.19462 +- 0.00258 seconds time elapsed  ( +-  1.32% )
--    ^-- not wall exists from tiles: 0.19432 +- 0.00272 seconds time elapsed  ( +-  1.40% )
--    ^-- separate table for walls: 0.19380 +- 0.00298 seconds time elapsed  ( +-  1.54% )
-- 2025-07-27
--   precalculated steps: 0.18268 +- 0.00231 seconds time elapsed  ( +-  1.26% )
--    ^-- wall_moves including exit moves: 0.17750 +- 0.00253 seconds time elapsed  ( +-  1.42% )

-- #TODO test other approaches with dedicated table for walls
CREATE OR REPLACE TABLE walls AS (
    FROM tiles WHERE symbol = '#'
);

CREATE OR REPLACE TABLE wall_moves AS (
    WITH
        -- walls AS MATERIALIZED (
        -- -- walls AS (
        --     FROM tiles WHERE symbol = '#'
        -- ),
        wall_hits AS MATERIALIZED (
        -- wall_hits AS (
            FROM walls w, directions d
            SELECT
                from_y: w.y - d.dy,
                from_x: w.x - d.dx,
                from_dir: d.dir,
                next_dir: d.next_dir,
            WHERE from_y > 0 AND from_y <= (FROM tiles SELECT max(y))
              AND from_x > 0 AND from_x <= (FROM tiles SELECT max(x))
              AND NOT EXISTS (FROM walls WHERE y = from_y AND x = from_x)
            --   AND (FROM tiles SELECT symbol WHERE y = from_y AND x = from_x) != '#'
            --   AND NOT EXISTS (FROM tiles WHERE y = from_y AND x = from_x AND symbol = '#')
            --   AND EXISTS (FROM tiles WHERE y = from_y AND x = from_x AND symbol != '#')
        ),
        step_starts AS (
            FROM tiles
            SELECT
                from_y: y,
                from_x: x,
                from_dir: symbol,
                next_dir: symbol,
                start: true,
            WHERE symbol IN ('^', '>', 'v', '<')
            UNION ALL
            FROM wall_hits
            SELECT
                *,
                start: false,
        ),
        wall_moves AS (
            FROM step_starts t1
            JOIN directions d ON t1.next_dir = d.dir
            LEFT JOIN wall_hits t2 ON t1.next_dir = t2.from_dir AND CASE t1.next_dir
                WHEN '^' THEN t1.from_x = t2.from_x AND t1.from_y >= t2.from_y
                WHEN '>' THEN t1.from_y = t2.from_y AND t1.from_x <= t2.from_x
                WHEN 'v' THEN t1.from_x = t2.from_x AND t1.from_y <= t2.from_y
                WHEN '<' THEN t1.from_y = t2.from_y AND t1.from_x >= t2.from_x
            END
            SELECT
                t1.from_y, t1.from_x, t1.from_dir,
                to_y: coalesce(t2.from_y, d.edge_y, t1.from_y),
                to_x: coalesce(t2.from_x, d.edge_x, t1.from_x),
                to_dir: t1.next_dir,
                start: t1.start,
                exit: t2.from_y IS NULL,
        )

    FROM wall_moves
    QUALIFY
        row_number() OVER (
            PARTITION BY from_y, from_x, from_dir
            ORDER BY abs(from_y - to_y) + abs(from_x - to_x)
        ) = 1
);

CREATE OR REPLACE TABLE guard_path AS (
    WITH RECURSIVE
        path AS (
            FROM wall_moves
            SELECT
                step_index: 0,
                *,
            WHERE from_dir = to_dir
            UNION ALL
            FROM path p
            JOIN wall_moves m ON p.to_y = m.from_y AND p.to_x = m.from_x AND p.to_dir = m.from_dir
            SELECT
                step_index: step_index + 1,
                m.*,
            WHERE NOT p.exit
        )

    FROM path
);

CREATE OR REPLACE TABLE visited_tiles AS (
    WITH
        visited_tiles AS (
            FROM guard_path
            JOIN directions ON dir = to_dir
            SELECT
                step_index,
                tile_index: unnest(generate_series(0, abs(from_y - to_y) + abs(from_x - to_x))) + 1,
                y: if(dy = 0, from_y, unnest(generate_series(from_y, to_y, dy))),
                x: if(dx = 0, from_x, unnest(generate_series(from_x, to_x, dx))),
                dir: to_dir,
        )

    FROM visited_tiles
    SELECT
        index: row_number() OVER (ORDER BY step_index, tile_index),
        *,
);
-- #endregion

-- #region Part 2 - Precalculated Steps
-- 2025-07-26
--   [BROKEN] loop detection without context: 1.5231 +- 0.0163 seconds time elapsed  ( +-  1.07% )
--    ^-- result: 1513, expected: 1516 | obstacle hits do not register when map would be exited (filtered by left join)
--   loop detection without context: 1.7594 +- 0.0103 seconds time elapsed  ( +-  0.59% )
-- 2025-07-27
--   loop detection without context: 1.7592 +- 0.0122 seconds time elapsed  ( +-  0.69% )
--    ^-- [BROKEN] obstacle_hit via CASE: 1.6605 +- 0.0126 seconds time elapsed  ( +-  0.76% )
--         ^-- result: 1574, expected: 1516
--         v-- Times are a bit wonky (up to 0.2s diff between runs)
-- |--^-- exits in precalculated moves: 1.5864 +- 0.0186 seconds time elapsed  ( +-  1.17% )
-- |       ^-- obstacle_hit via CASE: 1.6021 +- 0.0133 seconds time elapsed  ( +-  0.83% )
-- > loop detection (no context): 1.5586 +- 0.0101 seconds time elapsed  ( +-  0.65% )
--    ^-- tuple for current tile: 1.5547 +- 0.0102 seconds time elapsed  ( +-  0.66% )
--    ^-- [BROKEN] without initial_steps CTE: 1.5667 +- 0.0149 seconds time elapsed  ( +-  0.95% )
--         ^-- result: 1517, expected: 1516 | first obstacle always loops, because wall_moves contains (start) -> (first_wall)
-- |--^-- without initial_steps CTE: 1.5461 +- 0.0116 seconds time elapsed  ( +-  0.75% )
-- > loop detection (no context): 1.5461 +- 0.0116 seconds time elapsed  ( +-  0.75% )

CREATE OR REPLACE TABLE obstacles AS (
    WITH
        obstacles AS (
            FROM visited_tiles t
            JOIN directions d USING (dir)
            SELECT
                index, step_index, tile_index,
                y, x, dir,
                obstacle_y: y + dy,
                obstacle_x: x + dx,
                next_dir,
            WHERE index != (FROM visited_tiles SELECT max(index))
              AND NOT EXISTS (FROM walls WHERE y = obstacle_y AND x = obstacle_x)
            QUALIFY row_number() OVER (PARTITION BY obstacle_y, obstacle_x ORDER BY index) = 1
        )

    FROM obstacles
);

CREATE OR REPLACE TABLE obstacle_moves AS (
    WITH
        obstacle_hits AS MATERIALIZED (
            FROM obstacles o, directions d
            SELECT
                from_y: obstacle_y - d.dy,
                from_x: obstacle_x - d.dx,
                from_dir: d.dir,
                next_dir: d.next_dir,
            WHERE from_y > 0 AND from_y <= (FROM tiles SELECT max(y))
              AND from_x > 0 AND from_x <= (FROM tiles SELECT max(x))
              AND NOT EXISTS (FROM walls WHERE y = from_y AND x = from_x)
        ),
        obstacle_moves AS (
            FROM obstacle_hits t1
            JOIN directions d ON t1.next_dir = d.dir
            JOIN walls w ON CASE d.dir
                WHEN '^' THEN t1.from_x = w.x AND t1.from_y >= w.y
                WHEN '>' THEN t1.from_y = w.y AND t1.from_x <= w.x
                WHEN 'v' THEN t1.from_x = w.x AND t1.from_y <= w.y
                WHEN '<' THEN t1.from_y = w.y AND t1.from_x >= w.x
            END
            SELECT
                t1.from_y, t1.from_x, t1.from_dir,
                to_y: w.y - d.dy,
                to_x: w.x - d.dx,
                to_dir: d.dir,
                exit: false
        )

    FROM obstacle_moves
    QUALIFY
        row_number() OVER (
            PARTITION BY from_y, from_x, from_dir
            ORDER BY abs(from_y - to_y) + abs(from_x - to_x)
        ) = 1
);

CREATE OR REPLACE TABLE loops AS (
    -- #TODO add previous/future tiles from original guard path
    WITH RECURSIVE
        all_moves AS MATERIALIZED (
            FROM wall_moves SELECT * EXCLUDE(start) WHERE NOT start
            UNION ALL
            FROM obstacle_moves
        ),
        loops AS (
            FROM obstacles
            SELECT
                it: 0,
                index, step_index, tile_index,
                obstacle_y, obstacle_x,
                tile: {'y': y, 'x': x, 'dir': dir},
                previous_tiles: [tile],
                loop: false,
                done: false,
            UNION ALL
            FROM obstacled_step
            SELECT
                it: it + 1,
                index, step_index, tile_index,
                obstacle_y, obstacle_x,
                tile: if(obstacle_hit, obstacle_tile, move_tile),
                previous_tiles: list_append(previous_tiles, if(obstacle_hit, obstacle_tile, move_tile)),
                loop: list_contains(previous_tiles, if(obstacle_hit, obstacle_tile, move_tile)),
                -- done: list_contains(future_tiles, if(obstacle_hit, obstacle_tile, move_tile)),
                done: false,
            WHERE NOT loop AND NOT done
        ),
        obstacled_step AS (
            FROM loops l
            JOIN all_moves m ON l.tile.y = m.from_y AND l.tile.x = m.from_x AND l.tile.dir = m.from_dir
            JOIN directions d ON m.to_dir = d.dir
            SELECT
                it,
                index, step_index, tile_index,
                obstacle_y, obstacle_x,
                move_tile: {'y': m.to_y, 'x': m.to_x, 'dir': d.dir},
                obstacle_tile: {'y': obstacle_y - dy, 'x': obstacle_x - dx, 'dir': d.dir},
                obstacle_hit: (
                    abs(m.from_y - obstacle_y) + abs(m.from_x - obstacle_x) +
                    abs(obstacle_y - m.to_y) + abs(obstacle_x - m.to_x)
                ) = abs(m.from_y - m.to_y) + abs(m.from_x - m.to_x),
                -- obstacle_hit: CASE m.to_dir
                --     WHEN '^' THEN obstacle_x = m.to_x AND obstacle_y BETWEEN m.to_y AND m.from_y
                --     WHEN '>' THEN obstacle_y = m.to_y AND obstacle_x BETWEEN m.from_x AND m.to_x
                --     WHEN 'v' THEN obstacle_x = m.to_x AND obstacle_y BETWEEN m.from_y AND m.to_y
                --     WHEN '<' THEN obstacle_y = m.to_y AND obstacle_x BETWEEN m.to_x AND m.from_x
                -- END,
                previous_tiles,
                loop, done,
            WHERE NOT m.exit OR obstacle_hit
        )

    FROM loops
);

-- -- using tuples instead of separate columns for positions
-- -- no real change, might be different if done for all tables of the approach
-- CREATE OR REPLACE TABLE loops AS (
--     WITH RECURSIVE
--         all_moves AS MATERIALIZED (
--             FROM wall_moves
--             SELECT
--                 from_tile: {'y': from_y, 'x': from_x, 'dir': from_dir},
--                 to_tile: {'y': to_y, 'x': to_x, 'dir': to_dir},
--                 exit,
--             UNION ALL
--             FROM obstacle_moves
--             SELECT
--                 from_tile: {'y': from_y, 'x': from_x, 'dir': from_dir},
--                 to_tile: {'y': to_y, 'x': to_x, 'dir': to_dir},
--                 exit,
--         ),
--         initial_steps AS (
--             FROM obstacles o
--             -- JOIN obstacle_moves m ON o.y = m.from_y AND o.x = m.from_x AND o.dir = m.from_dir
--             JOIN all_moves m ON o.y = m.from_tile.y AND o.x = m.from_tile.x AND o.dir = m.from_tile.dir
--             SELECT
--                 index, step_index, tile_index,
--                 obstacle_y, obstacle_x,
--                 tile: m.to_tile,
--                 previous_tiles: [m.from_tile, m.to_tile],
--         ),
--         loops AS (
--             FROM initial_steps
--             SELECT
--                 it: 0,
--                 *,
--                 loop: false,
--                 done: false,
--             UNION ALL
--             FROM obstacled_step
--             SELECT
--                 it: it + 1,
--                 index, step_index, tile_index,
--                 obstacle_y, obstacle_x,
--                 tile: if(obstacle_hit, obstacle_tile, move_tile),
--                 previous_tiles: list_append(previous_tiles, if(obstacle_hit, obstacle_tile, move_tile)),
--                 loop: list_contains(previous_tiles, if(obstacle_hit, obstacle_tile, move_tile)),
--                 -- done: list_contains(future_tiles, if(obstacle_hit, obstacle_tile, move_tile)),
--                 done: false,
--             WHERE NOT loop AND NOT done
--         ),
--         obstacled_step AS (
--             FROM loops l
--             JOIN all_moves m ON l.tile = m.from_tile
--             JOIN directions d ON m.to_tile.dir = d.dir
--             SELECT
--                 it,
--                 index, step_index, tile_index,
--                 obstacle_y, obstacle_x,
--                 move_tile: m.to_tile,
--                 obstacle_tile: {'y': obstacle_y - dy, 'x': obstacle_x - dx, 'dir': d.dir},
--                 obstacle_hit: (
--                     abs(m.from_tile.y - obstacle_y) + abs(m.from_tile.x - obstacle_x) +
--                     abs(obstacle_y - m.to_tile.y) + abs(obstacle_x - m.to_tile.x)
--                 ) = abs(m.from_tile.y - m.to_tile.y) + abs(m.from_tile.x - m.to_tile.x),
--                 -- obstacle_hit: CASE m.to_dir
--                 --     WHEN '^' THEN obstacle_x = m.to_tile.x AND obstacle_y BETWEEN m.to_tile.y AND m.from_tile.y
--                 --     WHEN '>' THEN obstacle_y = m.to_tile.y AND obstacle_x BETWEEN m.from_tile.x AND m.to_tile.x
--                 --     WHEN 'v' THEN obstacle_x = m.to_tile.x AND obstacle_y BETWEEN m.from_tile.y AND m.to_tile.y
--                 --     WHEN '<' THEN obstacle_y = m.to_tile.y AND obstacle_x BETWEEN m.to_tile.x AND m.from_tile.x
--                 -- END,
--                 previous_tiles,
--                 loop, done,
--             WHERE NOT m.exit OR obstacle_hit
--         )

--     FROM loops
-- );
-- #endregion



CREATE OR REPLACE VIEW results AS (
    SELECT
        part1: (FROM visited_tiles SELECT count(distinct (y, x))),
        -- part1: NULL,
        part2: (FROM loops SELECT count(*) WHERE loop),
        -- part2: NULL,
);


CREATE OR REPLACE VIEW solution AS (
    FROM results
    SELECT 
        part: 'Part 1',
        result: part1,
        expected: if(getvariable('mode') = 'example', getvariable('exampleSolution1'), getvariable('solution1')),
        correct: result = expected,
    UNION
    FROM results
    SELECT 
        part: 'Part 2',
        result: part2,
        expected: if(getvariable('mode') = 'example', getvariable('exampleSolution2'), getvariable('solution2')),
        correct: result = expected,
    ORDER BY part
);
FROM solution;
