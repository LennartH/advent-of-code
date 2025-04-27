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
CREATE OR REPLACE VIEW example AS SELECT regexp_split_to_table(trim(getvariable('example'), E'\n '), '\n\s*') as line;
SET VARIABLE exampleSolution1 = 41;
SET VARIABLE exampleSolution2 = 6;

CREATE OR REPLACE TABLE input AS
FROM read_text('input') SELECT regexp_split_to_table(trim(content, E'\n '), '\n\s*') as line;
SET VARIABLE solution1 = 4433;
SET VARIABLE solution2 = 1516;

.maxrows 75
-- SET VARIABLE mode = 'example';
SET VARIABLE mode = 'input';

CREATE OR REPLACE TABLE tiles AS (
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
    FROM (VALUES 
        ('^', '>', '<',  0, -1, NULL, 1),
        ('>', 'v', '^',  1,  0, (SELECT max(x) FROM tiles), NULL),
        ('v', '<', '>',  0,  1, NULL, (SELECT max(y) FROM tiles)),
        ('<', '^', 'v', -1,  0, 1, NULL)
    ) directions(dir, next_dir, prev_dir, dx, dy, edge_x, edge_y)
);

-- #region Part 1 - Naive Solution
-- CREATE OR REPLACE TABLE visited_tiles AS (  -- 3.764 +- 0.105 seconds time elapsed  (+- 2.78%)
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
CREATE OR REPLACE TABLE visited_tiles AS (
    WITH RECURSIVE
        -- Materialized CTE significantly improves performance
        --    ASOF: 0.88820 -> 0.56572 (-37%)
        --    CASE: 0.20916 -> 0.16511 (-20%)
        --   mathy: 0.25766 -> 0.22011 (-15%)
        steps AS MATERIALIZED (
            FROM tiles t
            JOIN directions d ON d.dir = symbol
            SELECT
                step_index: 0,
                prev_x: NULL,
                prev_y: NULL,
                prev_dir: NULL::STRING,
                x, y, dir,
            UNION ALL
            FROM closest_wall w
            JOIN directions d USING (dir)
            SELECT
                step_index + 1,
                prev_x: w.x,
                prev_y: w.y,
                prev_dir: w.dir,
                x: w.wall_x - d.dx,
                y: w.wall_y - d.dy,
                dir: d.next_dir,
        ),

        -- -- TODO is this the best way to use ASOF joins here?
        -- --     Materialized: 0.56572 +- 0.000959 seconds time elapsed  (+- 0.17%)
        -- -- Not Materialized: 0.88820 +- 0.00596 seconds time elapsed  (+- 0.67%)
        -- closest_wall AS (
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

        --     Materialized: 0.16511 +- 0.00119 seconds time elapsed  (+- 0.72%)
        -- Not Materialized: 0.20916 +- 0.00379 seconds time elapsed  (+- 1.81%)
        closest_wall AS (
            FROM steps s
            INNER JOIN tiles w ON w.symbol = '#' AND CASE dir
                WHEN '^' THEN s.x = w.x AND s.y > w.y
                WHEN '>' THEN s.y = w.y AND s.x < w.x
                WHEN 'v' THEN s.x = w.x AND s.y < w.y
                WHEN '<' THEN s.y = w.y AND s.x > w.x
            END
            SELECT s.*, w.x as wall_x, w.y as wall_y
            ORDER BY abs(s.x - w.x) + abs(s.y - w.y) ASC
            LIMIT 1
        ),

        -- --     Materialized: 0.22011 +- 0.00153 seconds time elapsed  (+- 0.70%)
        -- -- Not Materialized: 0.25766 +- 0.00381 seconds time elapsed  (+- 1.48%)
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
                prev_x: x,
                prev_y: y,
                prev_dir: dir,
                x: coalesce(d.edge_x, x),
                y: coalesce(d.edge_y, y),
                dir: next_dir,
            ORDER BY step_index DESC
            LIMIT 1
        ),
        visited_tiles AS (
            FROM (FROM steps UNION ALL FROM final_step) s
            JOIN directions d ON d.dir = s.prev_dir
            SELECT
                x: if(dx = 0, prev_x, unnest(generate_series(prev_x, x, dx))),
                y: if(dy = 0, prev_y, unnest(generate_series(prev_y, y, dy))),
                dir: s.prev_dir,
            WHERE step_index != 0
        )

    FROM visited_tiles
);
-- #endregion

-- Do stuff

CREATE OR REPLACE VIEW results AS (
    SELECT
        part1: (FROM visited_tiles SELECT count(distinct (x, y))),
        NULL as part2
);


CREATE OR REPLACE VIEW solution AS (
    FROM results
    SELECT 
        'Part 1' as part,
        part1 as result,
        if(getvariable('mode') = 'example', getvariable('exampleSolution1'), getvariable('solution1')) as expected,
        result = expected as correct
    UNION
    FROM results
    SELECT 
        'Part 2' as part,
        part2 as result,
        if(getvariable('mode') = 'example', getvariable('exampleSolution2'), getvariable('solution2')) as expected,
        result = expected as correct
    ORDER BY part
);
FROM solution;
