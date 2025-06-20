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

-- -- Loop when placing obstacle on visited cell
-- SET VARIABLE example = '
--     .#............
--     .............#
--     .^...........#
--     .....#........
--     ............#.
-- ';
-- -- Loop between 2 points
-- SET VARIABLE example = '
--    ......
--    .#..#.
--    .....#
--    .^#...
--    ....#.
-- ';
-- -- Loop outside of original path
-- SET VARIABLE example = '
--    ............
--    ......#.....
--    .........#..
--    .....#......
--    ........#...
--    ..^.........
--    ............
-- ';

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
-- v1.2.2 7c039464e4: 4.3820 +- 0.1090 seconds (+- 2.50%)
--    ASOF: 0.68808 +- 0.00510 seconds (+- 0.74%)
--    CASE: 0.17569 +- 0.00397 seconds (+- 2.26%)
--   mathy: 0.24673 +- 0.00552 seconds (+- 2.24%)
-- v1.3.1 2063dda3e6: 4.5222 +- 0.0780 seconds (+- 1.72%)
--    ASOF: 0.30670 +- 0.01700 seconds (+- 5.54%)
--    CASE: 0.19088 +- 0.00316 seconds (+- 1.65%)
--   mathy: 0.23788 +- 0.00743 seconds (+- 3.13%)

-- CREATE OR REPLACE TABLE visited_tiles AS (
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
--                 prev_x: NULL,
--                 prev_y: NULL,
--                 prev_dir: NULL::STRING,
--                 x, y, dir,
--             UNION ALL
--             FROM closest_wall w
--             JOIN directions d USING (dir)
--             SELECT
--                 step_index + 1,
--                 prev_x: w.x,
--                 prev_y: w.y,
--                 prev_dir: w.dir,
--                 x: w.wall_x - d.dx,
--                 y: w.wall_y - d.dy,
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
--             SELECT s.*, w.x as wall_x, w.y as wall_y
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
--                 prev_x: x,
--                 prev_y: y,
--                 prev_dir: dir,
--                 x: coalesce(d.edge_x, x),
--                 y: coalesce(d.edge_y, y),
--                 dir: next_dir,
--             ORDER BY step_index DESC
--             LIMIT 1
--         ),
--         visited_tiles AS (
--             FROM (FROM steps UNION ALL FROM final_step) s
--             JOIN directions d ON d.dir = s.prev_dir
--             SELECT
--                 x: if(dx = 0, prev_x, unnest(generate_series(prev_x, x, dx))),
--                 y: if(dy = 0, prev_y, unnest(generate_series(prev_y, y, dy))),
--                 dir: s.prev_dir,
--             WHERE step_index != 0
--         )

--     FROM visited_tiles
-- );
-- #endregion

-- #region Part 1 - Path Collapse
-- v1.2.2 7c039464e4: recursive CTE with USING KEY not supported
-- v1.3.1 2063dda3e6: 0.27661 +- 0.00385 seconds (+- 1.39%)

CREATE OR REPLACE TABLE edges AS (
-- CREATE OR REPLACE VIEW edges AS (
    WITH
        walls AS (
            FROM tiles WHERE symbol = '#'
        ),
        wall_hits AS (
            FROM walls w, directions d
            SELECT
                from_y: w.y - d.dy,
                from_x: w.x - d.dx,
                from_dir: d.dir,
                next_dir: d.next_dir,
            WHERE from_y > 0 AND from_y <= (FROM tiles SELECT max(y))
              AND from_x > 0 AND from_x <= (FROM tiles SELECT max(x))
              AND (FROM tiles SELECT symbol WHERE y = from_y AND x = from_x) != '#'
        ),
        edges AS (
            FROM wall_hits t1
            LEFT JOIN wall_hits t2 ON t1.next_dir = t2.from_dir AND CASE t1.next_dir
                WHEN '^' THEN t1.from_x = t2.from_x AND t1.from_y >= t2.from_y
                WHEN '>' THEN t1.from_y = t2.from_y AND t1.from_x <= t2.from_x
                WHEN 'v' THEN t1.from_x = t2.from_x AND t1.from_y <= t2.from_y
                WHEN '<' THEN t1.from_y = t2.from_y AND t1.from_x >= t2.from_x
            END
            JOIN directions d ON t1.next_dir = d.dir
            SELECT
                t1.from_y, t1.from_x, t1.from_dir,
                to_y: coalesce(t2.from_y, d.edge_y, t1.from_y),
                to_x: coalesce(t2.from_x, d.edge_x, t1.from_x),
                to_dir: t1.next_dir,
                exit: t2.from_y IS NULL,
        ),
        valid_edges AS (
            FROM edges
            WINDOW
                closest AS (
                    PARTITION BY from_y, from_x, from_dir
                    ORDER BY abs(from_y - to_y) + abs(from_x - to_x) ASC
                )
            QUALIFY row_number() OVER closest = 1
        )

    FROM valid_edges
);

CREATE OR REPLACE TABLE paths AS (
-- CREATE OR REPLACE VIEW paths AS (
    WITH RECURSIVE
        paths USING KEY (start) AS (
            FROM edges
            SELECT
                start: {'y': from_y, 'x': from_x, 'dir': from_dir},
                current: {'y': to_y, 'x': to_x, 'dir': to_dir},
                path: [start, current],
                loop: FALSE,
                final: exit,
            UNION
            FROM paths p1
            JOIN recurring.paths p2 ON p1.current = p2.start
            SELECT
                p1.start,
                p2.current,
                path: p1.path || p2.path[2:],
                loop: list_has_any(p1.path[:-1], p2.path[2:]),
                p2.final,
            WHERE NOT p1.final AND NOT p1.loop
        )

    FROM paths
    SELECT start, path, loop
);

CREATE OR REPLACE TABLE visited_tiles AS (
-- CREATE OR REPLACE VIEW visited_tiles AS (
    WITH
        path AS (
            FROM tiles t
            JOIN paths p ON t.symbol = p.start.dir AND CASE t.symbol
                WHEN '^' THEN t.x = p.start.x AND t.y >= p.start.y
                WHEN '>' THEN t.y = p.start.y AND t.x <= p.start.x
                WHEN 'v' THEN t.x = p.start.x AND t.y <= p.start.y
                WHEN '<' THEN t.y = p.start.y AND t.x >= p.start.x
            END
            SELECT
                path: list_prepend((t.y, t.x, t.symbol), p.path)
            WHERE t.symbol IN ('^', '>', 'v', '<')
            ORDER BY abs(t.y - p.start.y) + abs(t.x - p.start.x) ASC
            LIMIT 1
        ),
        steps AS (
            FROM (
                FROM path p
                SELECT 
                    step_index: generate_subscripts(path, 1),
                    step: unnest(path, recursive := true),
                    path: path[:step_index-1],
            ) s
            SELECT
                step_index,
                from_y: lag(y) OVER step_order,
                from_x: lag(x) OVER step_order,
                to_y: y,
                to_x: x,
                dir,
                path,
            WINDOW
                step_order AS (ORDER BY step_index ASC)
            QUALIFY from_x IS NOT NULL
        ),
        visited_tiles AS (
            FROM steps s
            JOIN directions d USING (dir)
            SELECT
                step_index: step_index - 1,
                tile_index: unnest(generate_series(0, abs(if(dy = 0, from_x - to_x, from_y - to_y)))) + 1,
                y: if(dy = 0, from_y, unnest(generate_series(from_y, to_y, dy))),
                x: if(dx = 0, from_x, unnest(generate_series(from_x, to_x, dx))),
                dir,
                path
        )
        
    FROM visited_tiles
    SELECT
        index: row_number() OVER (ORDER BY step_index, tile_index),
        * EXCLUDE (step_index, tile_index),
);
-- #endregion

-- #region Part 2 - Path Collapse
CREATE OR REPLACE TABLE loops AS (
-- CREATE OR REPLACE VIEW loops AS (
    WITH
        guard_paths AS (
            FROM paths p
            SELECT
                p.*,
                guard: p.start IN (FROM visited_tiles SELECT position: {'y': y, 'x': x, 'dir': dir}),
        ),
        obstacles AS (
            FROM visited_tiles v
            JOIN directions d USING (dir)
            SELECT
                index,
                y, x, dir,
                obstacle_y: y + d.dy,
                obstacle_x: x + d.dx,
                d.next_dir,
                path_before: path,
            WHERE obstacle_y > 0 AND obstacle_y <= (FROM tiles SELECT max(y))
              AND obstacle_x > 0 AND obstacle_x <= (FROM tiles SELECT max(x))
              AND '#' != (FROM tiles SELECT symbol WHERE y = obstacle_y AND x = obstacle_x)
            QUALIFY
                row_number() OVER (PARTITION BY obstacle_y, obstacle_x ORDER BY index) = 1
        ),
        obstacle_paths AS (
            FROM obstacles o
            JOIN guard_paths p ON p.start.dir = o.next_dir AND CASE o.next_dir
                WHEN '^' THEN o.x = p.start.x AND o.y >= p.start.y
                WHEN '>' THEN o.y = p.start.y AND o.x <= p.start.x
                WHEN 'v' THEN o.x = p.start.x AND o.y <= p.start.y
                WHEN '<' THEN o.y = p.start.y AND o.x >= p.start.x
            END
            SELECT
                index,
                obstacle: {'y': obstacle_y, 'x': obstacle_x},
                position: {'y': y, 'x': x, 'dir': next_dir},
                path_before,
                p.*
            QUALIFY
                row_number() OVER (PARTITION BY index ORDER BY abs(y - p.start.y) + abs(x - p.start.x)) = 1
        ),
        loops AS (
            FROM obstacle_paths
            SELECT
                index, obstacle, position,
                -- previous_step: path_before[-1],
                -- path_index: list_position(path, previous_step),
                path_before,
                obstacle_path: path,
                obstacle_loop: list_has_any(path_before, path),
                loop: obstacle_loop or loop,
        )

    FROM loops
    WHERE loop
);
-- #endregion

CREATE OR REPLACE VIEW results AS (
    SELECT
        part1: (FROM visited_tiles SELECT count(distinct (x, y))),
        part2: (FROM loops SELECT count(*))
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
