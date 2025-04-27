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
    ) directions(dir, next_dir, previous_dir, dx, dy, edge_x, edge_y)
);

-- #region Part 1 - Naive Solution: 3.764 +- 0.105 seconds time elapsed  (+- 2.78%)
CREATE OR REPLACE TABLE visited_tiles AS (
    WITH RECURSIVE
        steps AS (
            FROM tiles t
            JOIN directions d ON d.dir = symbol
            SELECT
                step_index: 0,
                x, y, dir
            UNION ALL
            FROM steps s
            JOIN directions d USING (dir)
            -- inner join terminates recursion when leaving grid
            INNER JOIN tiles t ON t.x = s.x + d.dx AND t.y = s.y + d.dy
            SELECT
                step_index + 1,
                x: if(t.symbol = '#', s.x, t.x),
                y: if(t.symbol = '#', s.y, t.y),
                dir: if(t.symbol = '#', d.next_dir, d.dir),
        )

    FROM steps
    SELECT x, y, dir
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
