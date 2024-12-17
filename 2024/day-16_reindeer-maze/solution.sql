SET VARIABLE example = '
    ###############
    #.......#....E#
    #.#.###.#.###.#
    #.....#.#...#.#
    #.###.#####.#.#
    #.#.#.......#.#
    #.#.#####.###.#
    #...........#.#
    ###.#.#####.#.#
    #...#.....#.#.#
    #.#.#.###.#.#.#
    #.....#...#.#.#
    #.###.#.#.#.#.#
    #S..#.....#...#
    ###############
';
SET VARIABLE exampleSolution1 = 7036;
SET VARIABLE exampleSolution2 = NULL;

SET VARIABLE example = '
    #################
    #...#...#...#..E#
    #.#.#.#.#.#.#.#.#
    #.#.#.#...#...#.#
    #.#.#.#.###.#.#.#
    #...#.#.#.....#.#
    #.#.#.#.#.#####.#
    #.#...#.#.#.....#
    #.#.#####.#.###.#
    #.#.#.......#...#
    #.#.###.#####.###
    #.#.#...#.....#.#
    #.#.#.#####.###.#
    #.#.#.........#.#
    #.#.#.#########.#
    #S#.............#
    #################
';
SET VARIABLE exampleSolution1 = 11048;
SET VARIABLE exampleSolution2 = NULL;

CREATE OR REPLACE VIEW example AS SELECT regexp_split_to_table(trim(getvariable('example'), chr(10) || ' '), '\n\s*') as line;

CREATE OR REPLACE TABLE input AS
SELECT regexp_split_to_table(trim(content, chr(10) || ' '), '\n') as line FROM read_text('input');
SET VARIABLE solution1 = NULL;
SET VARIABLE solution2 = NULL;

SET VARIABLE mode = 'example';
-- SET VARIABLE mode = 'input';

CREATE OR REPLACE VIEW map AS (
    WITH
        map AS (
            SELECT
                y,
                generate_subscripts(symbols, 1) as x,
                unnest(symbols) as symbol,
            FROM (
                SELECT
                    row_number() OVER () as y,
                    regexp_split_to_array(line, '') as symbols,
                FROM query_table(getvariable('mode'))
            )
        )
    
    SELECT
        y, x,
        if(symbol = 'S', '>', symbol) as symbol
    FROM map
);

CREATE OR REPLACE TABLE directions AS (
    FROM (VALUES 
        ('^',  0, -1),
        ('>',  1,  0),
        ('v',  0,  1),
        ('<', -1,  0)
    ) directions(dir, dx, dy)
);

-- Do stuff

CREATE OR REPLACE VIEW results AS (
    SELECT
        NULL as part1,
        NULL as part2
);


CREATE OR REPLACE VIEW solution AS (
    SELECT 
        'Part 1' as part,
        part1 as result,
        if(getvariable('mode') = 'example', getvariable('exampleSolution1'), getvariable('solution1')) as expected,
        result = expected as correct
    FROM results
    UNION
    SELECT 
        'Part 2' as part,
        part2 as result,
        if(getvariable('mode') = 'example', getvariable('exampleSolution2'), getvariable('solution2')) as expected,
        result = expected as correct
    FROM results
    ORDER BY part
);
FROM solution;

-- region Troubleshooting Utils
CREATE OR REPLACE MACRO print_map() AS TABLE (
    SELECT
        y,
        string_agg(symbol, ' ' ORDER BY x) as line,
    FROM map
    GROUP BY y
    ORDER BY y
);
-- endregion
