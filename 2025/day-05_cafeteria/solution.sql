SET VARIABLE example = '
    3-5
    10-14
    16-20
    12-18

    1
    5
    8
    11
    17
    32
';
SET VARIABLE exampleSolution1 = 3;
SET VARIABLE exampleSolution2 = NULL;
CREATE OR REPLACE VIEW example AS SELECT regexp_split_to_table(trim(getvariable('example'), E'\n '), '\n\s*') as line;

CREATE OR REPLACE TABLE input AS
FROM read_text('input') SELECT regexp_split_to_table(trim(content, E'\n '), '\n\s*') as line;
SET VARIABLE solution1 = 828;
SET VARIABLE solution2 = NULL;

.maxrows 75
SET VARIABLE mode = 'example';
-- SET VARIABLE mode = 'input';

CREATE OR REPLACE TABLE parser AS (
    FROM query_table(getvariable('mode'))
    SELECT
         parts: string_split(line, '-')::BIGINT[],
);

CREATE OR REPLACE TABLE ranges AS (
    FROM parser
    SELECT
        lower: parts[1],
        upper: parts[2],
    WHERE length(parts) = 2
);

CREATE OR REPLACE TABLE ingredients AS (
    FROM parser
    SELECT
        id: parts[1],
    WHERE length(parts) = 1
);

CREATE OR REPLACE TABLE ingredient_freshness AS (
    FROM ingredients i
    LEFT JOIN ranges r ON i.id BETWEEN r.lower AND r.upper
    SELECT DISTINCT ON (i.id)
        i.id,
        is_fresh: r.lower IS NOT NULL,
);

-- Do stuff

CREATE OR REPLACE VIEW results AS (
    SELECT
        part1: (FROM ingredient_freshness SELECT count(*) WHERE is_fresh),
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
