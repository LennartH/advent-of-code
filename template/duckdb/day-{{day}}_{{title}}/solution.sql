SET VARIABLE example = '

';
SET VARIABLE exampleSolution1 = NULL;
SET VARIABLE exampleSolution2 = NULL;
CREATE OR REPLACE VIEW example AS SELECT regexp_split_to_table(trim(getvariable('example'), E'\n '), '\n\s*') as line;

CREATE OR REPLACE TABLE input AS
FROM read_text('input') SELECT regexp_split_to_table(trim(content, E'\n '), '\n\s*') as line;
SET VARIABLE solution1 = NULL;
SET VARIABLE solution2 = NULL;

.maxrows 75
SET VARIABLE mode = 'example';
-- SET VARIABLE mode = 'input';

CREATE OR REPLACE TABLE parser AS (
    FROM query_table(getvariable('mode'))
    SELECT
           idx: row_number() OVER (),
         parts: string_split(line, ' '),
        values: cast(string_split(line, ' ') as INTEGER[]),
);

-- Do stuff

CREATE OR REPLACE VIEW results AS (
    SELECT
        part1: NULL,
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
