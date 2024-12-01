SET VARIABLE example = '

';
CREATE TABLE example AS SELECT regexp_split_to_table(trim(getvariable('example'), E'\n '), '\n\s*') as line;
SET VARIABLE exampleSolution1 = NULL;
SET VARIABLE exampleSolution2 = NULL;

CREATE TABLE input AS
SELECT regexp_split_to_table(trim(content, E'\n '), '\n') as line
FROM read_text('input');
SET VARIABLE solution1 = NULL;
SET VARIABLE solution2 = NULL;

SET VARIABLE mode = 'example'; -- example or input
SET VARIABLE expected1 = if(getvariable('mode') = 'example', getvariable('exampleSolution1'), getvariable('solution1'));
SET VARIABLE expected2 = if(getvariable('mode') = 'example', getvariable('exampleSolution2'), getvariable('solution2'));


SELECT * FROM query_table(getvariable('mode'));

WITH
    parser AS (
        SELECT
            'TODO' as prop
        FROM query_table(getvariable('mode'))
    )


SELECT 
    'Part 1' as part,
    NULL as solution,
    getvariable('expected1') as expected,
    solution = expected as correct
FROM parser
UNION
SELECT 
    'Part 2' as part,
    NULL as solution,
    getvariable('expected2') as expected,
    solution = expected as correct
FROM parser;