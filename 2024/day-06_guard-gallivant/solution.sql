SET VARIABLE example = '
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
';
SET VARIABLE exampleSolution1 = 41;
SET VARIABLE exampleSolution2 = 6;

-- -- Example with multiple obstacles in same line
-- SET VARIABLE example = '
--     .#.......
--     ....#..#.
--     .........
--     ....#....
--     ...#....#
--     .........
--     ....^....
--     #........
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
--    ............
--    ..x...#.....
--    .........#..
--    .....#......
--    ........#...
--    ..^.........
--    ............
-- ';
-- SET VARIABLE exampleSolution1 = 6;
-- SET VARIABLE exampleSolution2 = 1;

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

CREATE OR REPLACE TABLE ray_steps AS ( -- ~0.140 s
-- CREATE OR REPLACE VIEW ray_steps AS (
    WITH RECURSIVE
        -- Materialized CTE significantly improves performance
        -- v1.2.2 7c039464e4
        --    ASOF: 1.06263 -> 0.68808 (-54%)
        --    CASE: 0.23304 -> 0.17569 (-32%)
        --   mathy: 0.28054 -> 0.24673 (-13%)
        -- v1.3.1 2063dda3e6
        --    ASOF: 0.30670 -> 0.73319 (+139%)
        --    CASE: 0.22260 -> 0.19088 (-16%)
        --   mathy: 0.28820 -> 0.23788 (-21%)
        steps AS MATERIALIZED (
            FROM tiles t
            JOIN directions d ON d.dir = symbol
            SELECT
                step_index: 0,
                prev_y: NULL,
                prev_x: NULL,
                prev_dir: NULL::STRING,
                y, x, dir,
            UNION ALL
            FROM closest_wall w
            JOIN directions d USING (dir)
            SELECT
                step_index + 1,
                prev_y: w.y,
                prev_x: w.x,
                prev_dir: w.dir,
                y: w.wall_y - d.dy,
                x: w.wall_x - d.dx,
                dir: d.next_dir,
        ),

        -- -- ASOF
        -- -- v1.2.2 7c039464e4
        -- --   Not Materialized: 1.06263 +- 0.00580 seconds (+- 0.55%)
        -- --       Materialized: 0.68808 +- 0.00510 seconds (+- 0.74%)
        -- -- v1.3.1 2063dda3e6
        -- --   Not Materialized: 0.30670 +- 0.01700 seconds (+- 5.54%)
        -- --       Materialized: 0.73319 +- 0.00650 seconds (+- 0.89%)
        -- closest_wall AS (
        --     -- TODO is this the best way to use ASOF joins here?
        --     FROM steps s
        --     ASOF INNER JOIN tiles w ON w.symbol = '#' AND w.x = s.x AND w.y < s.y
        --     SELECT s.*, w.x as wall_x, w.y as wall_y
        --     WHERE s.dir = '^'

        --     UNION ALL

        --     FROM steps s
        --     ASOF INNER JOIN tiles w ON w.symbol = '#' AND w.y = s.y AND w.x > s.x
        --     SELECT s.*, w.x as wall_x, w.y as wall_y
        --     WHERE s.dir = '>'

        --     UNION ALL

        --     FROM steps s
        --     ASOF INNER JOIN tiles w ON w.symbol = '#' AND w.x = s.x AND w.y > s.y
        --     SELECT s.*, w.x as wall_x, w.y as wall_y
        --     WHERE s.dir = 'v'

        --     UNION ALL

        --     FROM steps s
        --     ASOF INNER JOIN tiles w ON w.symbol = '#' AND w.y = s.y AND w.x < s.x
        --     SELECT s.*, w.x as wall_x, w.y as wall_y
        --     WHERE s.dir = '<'
        -- ),

        -- CASE
        -- v1.2.2 7c039464e4
        --   Not Materialized: 0.23304 +- 0.00968 seconds (+- 4.15%)
        --       Materialized: 0.17569 +- 0.00397 seconds (+- 2.26%)
        -- v1.3.1 2063dda3e6
        --   Not Materialized: 0.22260 +- 0.01500 seconds (+- 6.75%)
        --       Materialized: 0.19088 +- 0.00316 seconds (+- 1.65%)
        closest_wall AS (
            FROM steps s
            INNER JOIN tiles w ON w.symbol = '#' AND CASE dir
                WHEN '^' THEN s.x = w.x AND s.y > w.y
                WHEN '>' THEN s.y = w.y AND s.x < w.x
                WHEN 'v' THEN s.x = w.x AND s.y < w.y
                WHEN '<' THEN s.y = w.y AND s.x > w.x
            END
            SELECT 
                s.*, 
                wall_x: w.x,
                wall_y: w.y,
            ORDER BY abs(s.x - w.x) + abs(s.y - w.y) ASC
            LIMIT 1
        ),

        -- -- mathy
        -- -- v1.2.2 7c039464e4
        -- --   Not Materialized: 0.28054 +- 0.00902 seconds (+- 3.22%)
        -- --       Materialized: 0.24673 +- 0.00552 seconds (+- 2.24%)
        -- -- v1.3.1 2063dda3e6
        -- --   Not Materialized: 0.28820 +- 0.02280 seconds (+- 7.91%)
        -- --       Materialized: 0.23788 +- 0.00743 seconds (+- 3.13%)
        -- closest_wall AS (
        --     FROM steps s
        --     JOIN directions d USING (dir)
        --     INNER JOIN tiles w 
        --             ON w.symbol = '#'
        --            -- in line with current direction (either x-x/y-y is 0 or dy/dx is 0)
        --            AND (w.y - s.y) * d.dx + (w.x - s.x) * d.dy = 0
        --            -- is after current position in current direction
        --            AND (w.y * d.dy > s.y * d.dy OR w.x * d.dx > s.x * d.dx)
        --     SELECT s.*, w.x as wall_x, w.y as wall_y
        --     ORDER BY abs(s.x - w.x) + abs(s.y - w.y) ASC
        --     LIMIT 1
        -- ),

        final_step AS (
            FROM steps s
            JOIN directions d USING (dir)
            SELECT
                step_index: step_index + 1,
                prev_y: y,
                prev_x: x,
                prev_dir: dir,
                y: coalesce(d.edge_y, y),
                x: coalesce(d.edge_x, x),
                dir,
            ORDER BY step_index DESC
            LIMIT 1
        )

    FROM steps
    UNION ALL
    FROM final_step
    ORDER BY step_index
);

CREATE OR REPLACE TABLE visited_tiles AS (
-- CREATE OR REPLACE ViEW visited_tiles AS (
    WITH
        visited_tiles AS (
            FROM ray_steps s
            JOIN directions d ON d.dir = s.prev_dir
            SELECT
                step_index,
                tile_index: unnest(generate_series(0, abs(if(dy = 0, prev_x - x, prev_y - y)))) + 1,
                y: if(dy = 0, prev_y, unnest(generate_series(prev_y, y, dy))),
                x: if(dx = 0, prev_x, unnest(generate_series(prev_x, x, dx))),
                dir: s.prev_dir,
            WHERE step_index != 0
        )

    FROM visited_tiles
    SELECT
        index: row_number() OVER (ORDER BY step_index, tile_index),
        *,
);
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
--   early pathfinding termination: 2.13506 +- 0.00755 seconds time elapsed  ( +-  0.35% )
--    ^-- only walls and obstacles: 1.96146 +- 0.00943 seconds time elapsed  ( +-  0.48% )

CREATE OR REPLACE TABLE loops AS (
-- CREATE OR REPLACE VIEW loops AS (
    WITH RECURSIVE
        visited_tiles_with_path AS (
            FROM visited_tiles
            SELECT
                *,
                path: (FROM ray_steps SELECT list({'y': y, 'x': x, 'dir': dir} ORDER BY step_index)),
        ),
        obstacles AS MATERIALIZED (
            FROM visited_tiles_with_path t
            JOIN directions d USING (dir)
            SELECT
                index, step_index, tile_index,
                y, x, dir,
                obstacle_y: y + dy,
                obstacle_x: x + dx,
                next_dir,
                path_before: path[:step_index],
                path_after: path[step_index+1:],
            WHERE '#' != (FROM tiles SELECT symbol WHERE y = obstacle_y AND x = obstacle_x)
            QUALIFY
                row_number() OVER (PARTITION BY obstacle_y, obstacle_x ORDER BY index) = 1
            -- QUALIFY row_number() OVER (PARTITION BY obstacle_y, obstacle_x ORDER BY index) = 1
            --     AND row_number() OVER (PARTITION BY step_index ORDER BY tile_index DESC) != 1
        ),
        obstacle_path_after_unnested AS (
            FROM (
                FROM obstacles
                SELECT
                    index, obstacle_y, obstacle_x,
                    path_index: generate_subscripts(path_after, 1),
                    path_step: unnest(path_after),
            )
            SELECT
                *,
                previous_step: lag(path_step) OVER (PARTITION BY index ORDER BY path_index),
            QUALIFY previous_step IS NOT NULL
        ),
        obstacle_path_after_subsequent_hits AS (
            FROM obstacle_path_after_unnested
            SELECT
                *,
                distance_step_obstacle: abs(path_step.y - obstacle_y) + abs(path_step.x - obstacle_x),
                distance_obstacle_prev: abs(obstacle_y - previous_step.y) + abs(obstacle_x - previous_step.x),
                distance_step_prev: abs(path_step.y - previous_step.y) + abs(path_step.x - previous_step.x),
                obstacle_hit: distance_step_obstacle + distance_obstacle_prev = distance_step_prev,
            WHERE obstacle_hit
            QUALIFY
                row_number() OVER (PARTITION BY index ORDER BY path_index DESC) = 1
        ),
        obstacles_with_path_after_hit AS (
            FROM obstacles o
            LEFT JOIN obstacle_path_after_subsequent_hits h USING (index)
            SELECT
                o.* EXCLUDE (path_after),
                path_after: if(h.path_index IS NULL, o.path_after, o.path_after[h.path_index+1:]),
        ),
        walls_and_obstacles AS MATERIALIZED (
            FROM tiles t
            LEFT JOIN obstacles o ON o.obstacle_y = t.y AND o.obstacle_x = t.x
            SELECT
                t.y, t.x, t.symbol,
                obstacle_index: o.index,
            WHERE symbol = '#' OR o.index IS NOT NULL
        ),
        loops AS (
            FROM obstacles_with_path_after_hit
            SELECT
                it: 0,
                index,
                obstacle_y, obstacle_x,
                obstacle_dir: dir,
                y, x,
                dir: next_dir,
                original_path: path_after,
                path: list_append(path_before, {'y': y, 'x': x, 'dir': next_dir}),
                loop: false,
                done: false,
            UNION
            FROM loops l
            JOIN directions d USING (dir)
            JOIN walls_and_obstacles w ON (w.obstacle_index IS NULL OR w.obstacle_index = l.index) AND CASE l.dir
                WHEN '^' THEN l.x = w.x AND l.y > w.y
                WHEN '>' THEN l.y = w.y AND l.x < w.x
                WHEN 'v' THEN l.x = w.x AND l.y < w.y
                WHEN '<' THEN l.y = w.y AND l.x > w.x
            END
            SELECT
                it: it + 1,
                index,
                obstacle_y, obstacle_x, obstacle_dir,
                y: w.y - d.dy,
                x: w.x - d.dx,
                dir: d.next_dir,
                original_path,
                path: list_append(path, {'y': w.y - d.dy, 'x': w.x - d.dx, 'dir': d.next_dir}),
                loop: list_contains(path, {'y': w.y - d.dy, 'x': w.x - d.dx, 'dir': d.next_dir}),
                done: list_contains(original_path, {'y': w.y - d.dy, 'x': w.x - d.dx, 'dir': d.next_dir}),
            WHERE NOT l.loop AND NOT l.done
            QUALIFY
                -- TODO: expensive, ORDER BY ... LIMIT 1?
                row_number() OVER (PARTITION BY index ORDER BY abs(l.y - w.y) + abs(l.x - w.x)) = 1
        )
    
    FROM loops
);
-- #endregion

-- #region Part 1 - Raywalking (Precalculated Steps)
-- v1.2.2 7c039464e4: 0.2064 +- 0.0148 seconds time elapsed  ( +-  7.18% )
-- v1.3.1 2063dda3e6: 0.19261 +- 0.00192 seconds time elapsed  ( +-  1.00% )

-- CREATE OR REPLACE TABLE wall_steps AS (
-- -- CREATE OR REPLACE VIEW wall_steps AS (
--     WITH
--         walls AS (
--             FROM tiles WHERE symbol = '#'
--         ),
--         wall_hits AS (
--             FROM walls w, directions d
--             SELECT
--                 from_y: w.y - d.dy,
--                 from_x: w.x - d.dx,
--                 from_dir: d.dir,
--                 next_dir: d.next_dir,
--             WHERE from_y > 0 AND from_y <= (FROM tiles SELECT max(y))
--               AND from_x > 0 AND from_x <= (FROM tiles SELECT max(x))
--               AND (FROM tiles SELECT symbol WHERE y = from_y AND x = from_x) != '#'
--         ),
--         steps AS (
--             FROM (
--                 FROM wall_hits
--                 UNION ALL
--                 FROM tiles
--                 SELECT
--                     from_y: y,
--                     from_x: x,
--                     from_dir: symbol,
--                     next_dir: symbol,
--                 WHERE symbol IN ('^', '>', 'v', '<')
--             ) t1
--             JOIN wall_hits t2 ON t1.next_dir = t2.from_dir AND CASE t1.next_dir
--                 WHEN '^' THEN t1.from_x = t2.from_x AND t1.from_y >= t2.from_y
--                 WHEN '>' THEN t1.from_y = t2.from_y AND t1.from_x <= t2.from_x
--                 WHEN 'v' THEN t1.from_x = t2.from_x AND t1.from_y <= t2.from_y
--                 WHEN '<' THEN t1.from_y = t2.from_y AND t1.from_x >= t2.from_x
--             END
--             SELECT
--                 t1.from_y, t1.from_x, t1.from_dir,
--                 to_y: t2.from_y,
--                 to_x: t2.from_x,
--                 to_dir: t1.next_dir,
--         )

--     FROM steps
--     QUALIFY
--         row_number() OVER (
--             PARTITION BY from_y, from_x, from_dir
--             ORDER BY abs(from_y - to_y) + abs(from_x - to_x)
--         ) = 1
-- );

-- CREATE OR REPLACE TABLE guard_path AS ( -- ~0.080 s
-- -- CREATE OR REPLACE VIEW guard_path AS (
--     WITH RECURSIVE
--         path AS (
--             FROM tiles
--             SELECT
--                 step_index: 0,
--                 from_y: NULL,
--                 from_x: NULL,
--                 from_dir: NULL::STRING,
--                 to_y: y,
--                 to_x: x,
--                 to_dir: symbol,
--             WHERE symbol IN ('^', '>', 'v', '<')
--             UNION ALL
--             FROM path p
--             JOIN wall_steps w ON w.from_y = p.to_y AND w.from_x = p.to_x AND w.from_dir = p.to_dir
--             SELECT
--                 step_index: step_index + 1,
--                 from_y: w.from_y,
--                 from_x: w.from_x,
--                 from_dir: w.from_dir,
--                 to_y: w.to_y,
--                 to_x: w.to_x,
--                 to_dir: w.to_dir,
--         ),
--         exit_step AS (
--             FROM (FROM path ORDER BY step_index DESC LIMIT 1)
--             JOIN directions ON prev_dir = to_dir
--             SELECT
--                 step_index: step_index + 1,
--                 from_y: to_y,
--                 from_x: to_x,
--                 from_dir: to_dir,
--                 to_y: coalesce(edge_y, to_y),
--                 to_x: coalesce(edge_x, to_x),
--                 to_dir: dir,
--         )

--     FROM path
--     UNION ALL
--     FROM exit_step
--     ORDER BY step_index
-- );

-- CREATE OR REPLACE TABLE visited_tiles AS (
-- -- CREATE OR REPLACE ViEW visited_tiles AS (
--     WITH
--         visited_tiles AS (
--             FROM guard_path
--             JOIN directions ON dir = to_dir
--             SELECT
--                 step_index,
--                 tile_index: unnest(generate_series(0, abs(from_y - to_y) + abs(from_x - to_x))) + 1,
--                 y: if(dy = 0, from_y, unnest(generate_series(from_y, to_y, dy))),
--                 x: if(dx = 0, from_x, unnest(generate_series(from_x, to_x, dx))),
--                 dir: to_dir,
--             WHERE step_index != 0
--         )

--     FROM visited_tiles
--     SELECT
--         index: row_number() OVER (ORDER BY step_index, tile_index),
--         *,
-- );
-- #endregion

-- #region Part 2 - Raywalking (Precalculated Steps)

-- CREATE OR REPLACE TABLE edges AS (
-- -- CREATE OR REPLACE VIEW edges AS (
--     WITH
--         obstacles AS (
--             FROM visited_tiles t
--             JOIN directions d USING (dir)
--             SELECT
--                 index, step_index, tile_index,
--                 y, x, dir,
--                 obstacle_y: y + dy,
--                 obstacle_x: x + dx,
--                 next_dir,
--             WHERE '#' != (FROM tiles SELECT symbol WHERE y = obstacle_y AND x = obstacle_x)
--             QUALIFY
--                 row_number() OVER (PARTITION BY obstacle_y, obstacle_x ORDER BY index) = 1
--         ),
--         walls_and_obstacles AS (
--             FROM tiles t
--             LEFT JOIN obstacles o ON o.obstacle_y = t.y AND o.obstacle_x = t.x
--             SELECT
--                 t.y, t.x, t.symbol,
--                 obstacle_index: o.index,
--             WHERE symbol = '#' OR o.index IS NOT NULL
--         ),
--         wall_and_obstacle_hits AS (
--             FROM walls_and_obstacles w, directions d
--             SELECT
--                 w.obstacle_index,
--                 from_y: w.y - d.dy,
--                 from_x: w.x - d.dx,
--                 from_dir: d.dir,
--                 next_dir: d.next_dir,
--             WHERE from_y > 0 AND from_y <= (FROM tiles SELECT max(y))
--               AND from_x > 0 AND from_x <= (FROM tiles SELECT max(x))
--               AND (FROM tiles SELECT symbol WHERE y = from_y AND x = from_x) != '#'
--         ),
--         all_edges AS (
--             FROM wall_and_obstacle_hits t1
--             -- LEFT JOIN wall_and_obstacle_hits t2
--             JOIN wall_and_obstacle_hits t2
--                  ON t1.next_dir = t2.from_dir
--                 AND (t1.obstacle_index IS NULL OR t2.obstacle_index IS NULL)
--                 AND CASE t1.next_dir
--                     WHEN '^' THEN t1.from_x = t2.from_x AND t1.from_y >= t2.from_y
--                     WHEN '>' THEN t1.from_y = t2.from_y AND t1.from_x <= t2.from_x
--                     WHEN 'v' THEN t1.from_x = t2.from_x AND t1.from_y <= t2.from_y
--                     WHEN '<' THEN t1.from_y = t2.from_y AND t1.from_x >= t2.from_x
--                 END
--             SELECT
--                 from_obstacle_index: t1.obstacle_index,
--                 t1.from_y, t1.from_x, t1.from_dir,
--                 to_obstacle_index: t2.obstacle_index,
--                 to_y: t2.from_y,
--                 to_x: t2.from_x,
--                 to_dir: t1.next_dir,
--                 -- exit: t2.from_y IS NULL,
--                 distance: abs(t1.from_y - to_y) + abs(t1.from_x - to_x),
--                 distance_to_first_wall:
--                     min(distance)
--                     FILTER (WHERE to_obstacle_index IS NULL)
--                     OVER (PARTITION BY t1.from_y, t1.from_x, t1.from_dir),
--         ),
--         valid_edges AS (
--             FROM all_edges
--             SELECT * EXCLUDE(distance, distance_to_first_wall)
--             WHERE (from_obstacle_index IS NOT NULL AND distance = distance_to_first_wall)
--                OR (from_obstacle_index IS NULL AND distance <= distance_to_first_wall)
--             --    OR exit
--         )

--     FROM valid_edges
-- );

-- CREATE OR REPLACE TABLE loops AS (
--     WITH RECURSIVE
--         visited_tiles_with_path AS (
--             FROM visited_tiles
--             SELECT
--                 *,
--                 path: (FROM ray_steps SELECT list({'y': y, 'x': x, 'dir': coalesce(prev_dir, dir)} ORDER BY step_index)),
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
--         loops AS (
--             FROM obstacles_with_path_after_hit
--             SELECT
--                 it: 0,
--                 index,
--                 obstacle_y, obstacle_x,
--                 obstacle_dir: dir,
--                 y, x, dir,
--                 original_path: path_after,
--                 path: list_append(path_before, {'y': y, 'x': x, 'dir': dir}),
--                 loop: false,
--                 done: false,
--             UNION
--             FROM loops l
--             JOIN edges e ON 
--                     (e.from_obstacle_index IS NULL OR e.from_obstacle_index = l.index)
--                 AND (e.to_obstacle_index IS NULL OR e.to_obstacle_index = l.index)
--                 AND e.from_y = l.y AND e.from_x = l.x AND e.from_dir = l.dir
--             SELECT
--                 it: it + 1,
--                 index,
--                 obstacle_y, obstacle_x, obstacle_dir,
--                 y: e.to_y,
--                 x: e.to_x,
--                 dir: e.to_dir,
--                 original_path,
--                 path: list_append(path, {'y': e.to_y, 'x': e.to_x, 'dir': e.to_dir}),
--                 loop: list_contains(path, {'y': e.to_y, 'x': e.to_x, 'dir': e.to_dir}),
--                 done: list_contains(original_path, {'y': e.to_y, 'x': e.to_x, 'dir': e.to_dir}),
--             WHERE NOT l.loop AND NOT l.done
--         )

--     FROM loops
-- );
-- #endregion

-- #region Part 2 - Path Joining

-- CREATE OR REPLACE TABLE edges AS (
-- -- CREATE OR REPLACE VIEW edges AS (
--     WITH
--         obstacles AS (
--             FROM visited_tiles t
--             JOIN directions d USING (dir)
--             SELECT
--                 index, step_index, tile_index,
--                 y, x, dir,
--                 obstacle_y: y + dy,
--                 obstacle_x: x + dx,
--                 next_dir,
--             WHERE '#' != (FROM tiles SELECT symbol WHERE y = obstacle_y AND x = obstacle_x)
--             QUALIFY
--                 row_number() OVER (PARTITION BY obstacle_y, obstacle_x ORDER BY index) = 1
--         ),
--         walls_and_obstacles AS (
--             FROM tiles t
--             LEFT JOIN obstacles o ON o.obstacle_y = t.y AND o.obstacle_x = t.x
--             SELECT
--                 t.y, t.x, t.symbol,
--                 obstacle_index: o.index,
--             WHERE symbol = '#' OR o.index IS NOT NULL
--         ),
--         wall_and_obstacle_hits AS (
--             FROM walls_and_obstacles w, directions d
--             SELECT
--                 w.obstacle_index,
--                 from_y: w.y - d.dy,
--                 from_x: w.x - d.dx,
--                 from_dir: d.dir,
--                 next_dir: d.next_dir,
--             WHERE from_y > 0 AND from_y <= (FROM tiles SELECT max(y))
--               AND from_x > 0 AND from_x <= (FROM tiles SELECT max(x))
--               AND (FROM tiles SELECT symbol WHERE y = from_y AND x = from_x) != '#'
--         ),
--         all_edges AS (
--             FROM wall_and_obstacle_hits t1
--             LEFT JOIN wall_and_obstacle_hits t2
--                  ON t1.next_dir = t2.from_dir
--                 AND (t1.obstacle_index IS NULL OR t2.obstacle_index IS NULL)
--                 AND CASE t1.next_dir
--                     WHEN '^' THEN t1.from_x = t2.from_x AND t1.from_y >= t2.from_y
--                     WHEN '>' THEN t1.from_y = t2.from_y AND t1.from_x <= t2.from_x
--                     WHEN 'v' THEN t1.from_x = t2.from_x AND t1.from_y <= t2.from_y
--                     WHEN '<' THEN t1.from_y = t2.from_y AND t1.from_x >= t2.from_x
--                 END
--             SELECT
--                 from_obstacle_index: t1.obstacle_index,
--                 t1.from_y, t1.from_x, t1.from_dir,
--                 to_obstacle_index: t2.obstacle_index,
--                 to_y: t2.from_y,
--                 to_x: t2.from_x,
--                 to_dir: t1.next_dir,
--                 exit: t2.from_y IS NULL,
--                 distance: abs(t1.from_y - to_y) + abs(t1.from_x - to_x),
--                 distance_to_first_wall:
--                     min(distance)
--                     FILTER (WHERE to_obstacle_index IS NULL)
--                     OVER (PARTITION BY t1.from_y, t1.from_x, t1.from_dir),
--         ),
--         valid_edges AS (
--             FROM all_edges
--             SELECT * EXCLUDE(distance, distance_to_first_wall)
--             WHERE (from_obstacle_index IS NOT NULL AND distance = distance_to_first_wall)
--                OR (from_obstacle_index IS NULL AND distance <= distance_to_first_wall)
--                OR exit
--         )

--     FROM valid_edges
-- );
-- #endregion

-- #region Part 1 - Path Collapse
-- v1.2.2 7c039464e4: recursive CTE with USING KEY not supported
-- v1.3.1 2063dda3e6: 0.27661 +- 0.00385 seconds (+- 1.39%)

-- CREATE OR REPLACE TABLE edges AS (
-- -- CREATE OR REPLACE VIEW edges AS (
--     WITH
--         walls AS (
--             FROM tiles WHERE symbol = '#'
--         ),
--         wall_hits AS (
--             FROM walls w, directions d
--             SELECT
--                 from_y: w.y - d.dy,
--                 from_x: w.x - d.dx,
--                 from_dir: d.dir,
--                 next_dir: d.next_dir,
--             WHERE from_y > 0 AND from_y <= (FROM tiles SELECT max(y))
--               AND from_x > 0 AND from_x <= (FROM tiles SELECT max(x))
--               AND (FROM tiles SELECT symbol WHERE y = from_y AND x = from_x) != '#'
--         ),
--         edges AS (
--             FROM wall_hits t1
--             LEFT JOIN wall_hits t2 ON t1.next_dir = t2.from_dir AND CASE t1.next_dir
--                 WHEN '^' THEN t1.from_x = t2.from_x AND t1.from_y >= t2.from_y
--                 WHEN '>' THEN t1.from_y = t2.from_y AND t1.from_x <= t2.from_x
--                 WHEN 'v' THEN t1.from_x = t2.from_x AND t1.from_y <= t2.from_y
--                 WHEN '<' THEN t1.from_y = t2.from_y AND t1.from_x >= t2.from_x
--             END
--             JOIN directions d ON t1.next_dir = d.dir
--             SELECT
--                 t1.from_y, t1.from_x, t1.from_dir,
--                 to_y: coalesce(t2.from_y, d.edge_y, t1.from_y),
--                 to_x: coalesce(t2.from_x, d.edge_x, t1.from_x),
--                 to_dir: t1.next_dir,
--                 exit: t2.from_y IS NULL,
--         ),
--         valid_edges AS (
--             FROM edges
--             WINDOW
--                 closest AS (
--                     PARTITION BY from_y, from_x, from_dir
--                     ORDER BY abs(from_y - to_y) + abs(from_x - to_x) ASC
--                 )
--             QUALIFY row_number() OVER closest = 1
--         )

--     FROM valid_edges
-- );

-- CREATE OR REPLACE TABLE paths AS (
-- -- CREATE OR REPLACE VIEW paths AS (
--     WITH RECURSIVE
--         paths USING KEY (start) AS (
--             FROM edges
--             SELECT
--                 start: {'y': from_y, 'x': from_x, 'dir': from_dir},
--                 current: {'y': to_y, 'x': to_x, 'dir': to_dir},
--                 path: [start, current],
--                 loop: FALSE,
--                 final: exit,
--             UNION
--             FROM paths p1
--             JOIN recurring.paths p2 ON p1.current = p2.start
--             SELECT
--                 p1.start,
--                 p2.current,
--                 path: p1.path || p2.path[2:],
--                 loop: list_has_any(p1.path[:-1], p2.path[2:]),
--                 p2.final,
--             WHERE NOT p1.final AND NOT p1.loop
--         )

--     FROM paths
--     SELECT start, path, loop
-- );

-- CREATE OR REPLACE TABLE visited_tiles AS (
-- -- CREATE OR REPLACE VIEW visited_tiles AS (
--     WITH
--         path AS (
--             FROM tiles t
--             JOIN paths p ON t.symbol = p.start.dir AND CASE t.symbol
--                 WHEN '^' THEN t.x = p.start.x AND t.y >= p.start.y
--                 WHEN '>' THEN t.y = p.start.y AND t.x <= p.start.x
--                 WHEN 'v' THEN t.x = p.start.x AND t.y <= p.start.y
--                 WHEN '<' THEN t.y = p.start.y AND t.x >= p.start.x
--             END
--             SELECT
--                 path: list_prepend((t.y, t.x, t.symbol), p.path)
--             WHERE t.symbol IN ('^', '>', 'v', '<')
--             ORDER BY abs(t.y - p.start.y) + abs(t.x - p.start.x) ASC
--             LIMIT 1
--         ),
--         steps AS (
--             FROM (
--                 FROM path p
--                 SELECT 
--                     step_index: generate_subscripts(path, 1),
--                     step: unnest(path, recursive := true),
--                     path: path[:step_index-1],
--             ) s
--             SELECT
--                 step_index,
--                 from_y: lag(y) OVER step_order,
--                 from_x: lag(x) OVER step_order,
--                 to_y: y,
--                 to_x: x,
--                 dir,
--                 path,
--             WINDOW
--                 step_order AS (ORDER BY step_index ASC)
--             QUALIFY from_x IS NOT NULL
--         ),
--         visited_tiles AS (
--             FROM steps s
--             JOIN directions d USING (dir)
--             SELECT
--                 step_index: step_index - 1,
--                 tile_index: unnest(generate_series(0, abs(if(dy = 0, from_x - to_x, from_y - to_y)))) + 1,
--                 y: if(dy = 0, from_y, unnest(generate_series(from_y, to_y, dy))),
--                 x: if(dx = 0, from_x, unnest(generate_series(from_x, to_x, dx))),
--                 dir,
--                 path
--         )
        
--     FROM visited_tiles
--     SELECT
--         index: row_number() OVER (ORDER BY step_index, tile_index),
--         * EXCLUDE (step_index, tile_index),
-- );
-- #endregion

-- #region Part 2 - Path Collapse
-- FIXME: Doesn't work for paths encountering the obstacle multiple times
-- v1.3.1 2063dda3e6: 2.9660 +- 0.0109 seconds (+- 0.37%)

-- CREATE OR REPLACE TABLE loops AS (
-- -- CREATE OR REPLACE VIEW loops AS (
--     WITH
--         guard_paths AS (
--             FROM paths p
--             SELECT
--                 p.*,
--                 guard: p.start IN (FROM visited_tiles SELECT position: {'y': y, 'x': x, 'dir': dir}),
--         ),
--         obstacles AS (
--             FROM visited_tiles v
--             JOIN directions d USING (dir)
--             SELECT
--                 index,
--                 y, x, dir,
--                 obstacle_y: y + d.dy,
--                 obstacle_x: x + d.dx,
--                 d.next_dir,
--                 path_before: path,
--             WHERE obstacle_y > 0 AND obstacle_y <= (FROM tiles SELECT max(y))
--               AND obstacle_x > 0 AND obstacle_x <= (FROM tiles SELECT max(x))
--               AND '#' != (FROM tiles SELECT symbol WHERE y = obstacle_y AND x = obstacle_x)
--             QUALIFY
--                 row_number() OVER (PARTITION BY obstacle_y, obstacle_x ORDER BY index) = 1
--         ),
--         obstacle_paths AS (
--             FROM obstacles o
--             JOIN guard_paths p ON p.start.dir = o.next_dir AND CASE o.next_dir
--                 WHEN '^' THEN o.x = p.start.x AND o.y >= p.start.y
--                 WHEN '>' THEN o.y = p.start.y AND o.x <= p.start.x
--                 WHEN 'v' THEN o.x = p.start.x AND o.y <= p.start.y
--                 WHEN '<' THEN o.y = p.start.y AND o.x >= p.start.x
--             END
--             SELECT
--                 index,
--                 obstacle: {'y': obstacle_y, 'x': obstacle_x, 'dir': dir},
--                 position: {'y': y, 'x': x, 'dir': next_dir},
--                 path_before,
--                 p.*
--             QUALIFY
--                 row_number() OVER (PARTITION BY index ORDER BY abs(y - p.start.y) + abs(x - p.start.x)) = 1
--         ),
--         partial_loops AS (
--             FROM obstacle_paths
--             SELECT
--                 index, obstacle, position,
--                 -- previous_step: path_before[-1],
--                 -- path_index: list_position(path, previous_step),
--                 path_before,
--                 obstacle_path: path,
--                 backward_loop: list_has_any(path_before, path),
--                 natural_loop: loop,
--         ),
--         obstacle_path_steps AS (
--             WITH
--                 unnest_loops AS (
--                     FROM partial_loops
--                     SELECT
--                         index, obstacle, position,
--                         step_index: generate_subscripts(obstacle_path, 1),
--                         step: unnest(obstacle_path),
--                     WHERE NOT backward_loop AND NOT natural_loop
--                 ),
--                 unnest_loops_steps AS (
--                     FROM unnest_loops
--                     SELECT
--                         index, obstacle, position, step_index, step,
--                         previous_step: lag(step) OVER (PARTITION BY index ORDER BY step_index),
--                     QUALIFY previous_step IS NOT NULL
--                 )

--             FROM unnest_loops_steps
--             SELECT
--                 index, obstacle, position, step_index, step, previous_step,
--                 -- loop: (
--                 --     step.y = previous_step.y AND step.y = obstacle.y AND
--                 --     ((step.x <= obstacle.x AND previous_step.x >= obstacle.x) OR
--                 --     (step.x >= obstacle.x AND previous_step.x <= obstacle.x))
--                 -- ) OR (
--                 --     step.x = previous_step.x AND step.x = obstacle.x AND
--                 --     ((step.y <= obstacle.y AND previous_step.y >= obstacle.y) OR
--                 --     (step.y >= obstacle.y AND previous_step.y <= obstacle.y))
--                 -- ),
--                 distance_stop_obstacle: abs(step.x - obstacle.x) + abs(step.y - obstacle.y),
--                 distance_obstacle_previous_step: abs(obstacle.x - previous_step.x) + abs(obstacle.y - previous_step.y),
--                 distance_previous_step_step: abs(step.x - previous_step.x) + abs(step.y - previous_step.y),
--                 forward_loop: step.dir = obstacle.dir AND distance_stop_obstacle + distance_obstacle_previous_step = distance_previous_step_step,
--         ),
--         loops AS (
--             FROM partial_loops l
--             SELECT
--                 l.*,
--                 forward_loop: true = ANY (FROM obstacle_path_steps s SELECT forward_loop WHERE s.index = l.index),
--         )

--     FROM loops
--     SELECT
--         *,
--         loop: backward_loop OR natural_loop OR forward_loop,
-- );
-- #endregion

CREATE OR REPLACE VIEW results AS (
    SELECT
        part1: (FROM visited_tiles SELECT count(distinct (x, y))),
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
