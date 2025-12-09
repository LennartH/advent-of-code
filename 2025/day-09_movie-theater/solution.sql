SET VARIABLE example = '
    7,1
    11,1
    11,7
    9,7
    9,5
    2,5
    2,3
    7,3
';
SET VARIABLE exampleSolution1 = 50;
SET VARIABLE exampleSolution2 = NULL;
CREATE OR REPLACE VIEW example AS SELECT regexp_split_to_table(trim(getvariable('example'), E'\n '), '\n\s*') as line;

CREATE OR REPLACE TABLE input AS
FROM read_text('input') SELECT regexp_split_to_table(trim(content, E'\n '), '\n\s*') as line;
SET VARIABLE solution1 = 4750297200;
SET VARIABLE solution2 = NULL;

.maxrows 75
SET VARIABLE mode = 'example';
-- SET VARIABLE mode = 'input';

CREATE OR REPLACE TABLE red_tiles AS (
    FROM query_table(getvariable('mode'))
    SELECT
                 id: row_number() OVER (),
        coordinates: string_split(line, ',')::BIGINT[],
);

CREATE OR REPLACE TABLE rectangles AS (
    FROM red_tiles t1
    JOIN red_tiles t2 ON t1.id != t2.id
    SELECT
        t1_id: t1.id,
        t2_id: t2.id,
        area: (abs(t1.coordinates[1] - t2.coordinates[1]) + 1) * (abs(t1.coordinates[2] - t2.coordinates[2]) + 1)
);

CREATE OR REPLACE VIEW results AS (
    SELECT
        part1: (FROM rectangles SELECT max(area)),
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
