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
SET VARIABLE exampleSolution2 = NULL;
CREATE OR REPLACE VIEW example AS SELECT regexp_split_to_table(trim(getvariable('example'), E'\n '), '\n\s*') as line;

CREATE OR REPLACE TABLE input AS
FROM read_text('input') SELECT regexp_split_to_table(trim(content, E'\n '), '\n\s*') as line;
SET VARIABLE solution1 = 1537;
SET VARIABLE solution2 = NULL;

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
        )
    
    FROM splitters s1
    JOIN splitters s2 ON s1.y < s2.y AND abs(s1.x - s2.x) = 1
    SELECT
        s1_y: s1.y,
        s1_x: s1.x,
        s2_y: s2.y,
        s2_x: s2.x,
    QUALIFY
        row_number() OVER (PARTITION BY s1_y, s1_x, s2_x ORDER BY s2_y) = 1
);

CREATE OR REPLACE VIEW results AS (
    SELECT
        part1: (FROM splitter_edges SELECT count(DISTINCT (s2_y, s2_x)) + 1),
        part2: NULL,
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
