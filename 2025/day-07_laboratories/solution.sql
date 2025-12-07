SET VARIABLE example = '
    .......S.......
    ...............
    .......^.......
    ...............
    ......^.^......
    ...............
    .....^.^.^.....
    ...............
    ....^.^...^....
    ...............
    ...^.^...^.^...
    ...............
    ..^...^.....^..
    ...............
    .^.^.^.^.^...^.
    ...............
';
SET VARIABLE exampleSolution1 = 21;
SET VARIABLE exampleSolution2 = 40;
CREATE OR REPLACE VIEW example AS SELECT regexp_split_to_table(trim(getvariable('example'), E'\n '), '\n\s*') as line;

CREATE OR REPLACE TABLE input AS
FROM read_text('input') SELECT regexp_split_to_table(trim(content, E'\n '), '\n\s*') as line;
SET VARIABLE solution1 = 1537;
SET VARIABLE solution2 = 18818811755665;

.maxrows 75
SET VARIABLE mode = 'example';
-- SET VARIABLE mode = 'input';

CREATE OR REPLACE TABLE grid AS (
    FROM query_table(getvariable('mode'))
    SELECT
             y: row_number() OVER (),
             x: generate_subscripts(split(line, ''), 1),
        symbol: unnest(split(line, '')),
);

CREATE OR REPLACE TABLE splitter_edges AS (
    WITH
        splitters AS (
            FROM grid WHERE symbol = '^'
        ),
        valid_edge_ends AS (
            FROM splitters
            UNION ALL
            FROM grid
            WHERE y = (FROM grid SELECT max(y))
        ),
        splitter_edges AS (
            FROM splitters s1
            JOIN valid_edge_ends s2 ON s1.y < s2.y AND abs(s1.x - s2.x) = 1
            SELECT
                 from_y: s1.y,
                 from_x: s1.x,
                   to_y: s2.y,
                   to_x: s2.x,
                is_exit: s2.symbol = '.'
            QUALIFY
                row_number() OVER (PARTITION BY from_y, from_x, to_x ORDER BY to_y) = 1
        )

    FROM splitter_edges
);

CREATE OR REPLACE TABLE timelines AS (
    WITH RECURSIVE
        paths AS (
            FROM grid
            SELECT
                      y,
                      x,
                 weight: 1::BIGINT,
                is_exit: false,
            WHERE
                symbol = '^' AND y = 3
            UNION ALL
            FROM paths p
            JOIN splitter_edges e ON p.y = e.from_y AND p.x = e.from_x
            SELECT
                      y: e.to_y,
                      x: e.to_x,
                 weight: sum(p.weight),
                is_exit: any_value(e.is_exit),
            WHERE
                NOT p.is_exit
            GROUP BY
                e.to_y, e.to_x
        )

    FROM paths
    WHERE is_exit
);

CREATE OR REPLACE VIEW results AS (
    SELECT
        part1: (FROM splitter_edges SELECT count(DISTINCT (to_y, to_x)) + 1 WHERE NOT is_exit),
        part2: (FROM timelines SELECT sum(weight)),
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
