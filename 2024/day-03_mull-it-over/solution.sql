SET VARIABLE example = '
    xmul(2,4)%&mul[3,7]!@^do_not_mul(5,5)+mul(32,64]then(mul(11,8)mul(8,5))
';
CREATE TABLE example AS SELECT regexp_split_to_table(trim(getvariable('example'), E'\n '), '\n\s*') as line;
SET VARIABLE exampleSolution1 = NULL;
SET VARIABLE exampleSolution2 = NULL;

CREATE TABLE input AS
SELECT regexp_split_to_table(trim(content, E'\n '), '\n') as line FROM read_text('input');
SET VARIABLE solution1 = NULL;
SET VARIABLE solution2 = NULL;

SET VARIABLE mode = 'example'; -- example or input
SET VARIABLE expected1 = if(getvariable('mode') = 'example', getvariable('exampleSolution1'), getvariable('solution1'));
SET VARIABLE expected2 = if(getvariable('mode') = 'example', getvariable('exampleSolution2'), getvariable('solution2'));


SELECT * FROM query_table(getvariable('mode'));

.timer on
WITH
    matches AS (
        SELECT
            row_number() OVER () as idx,
            regexp_extract_all(line, '(mul\(\d{1,3},\d{1,3}\))') as parts
            -- cast(regexp_split_to_array(line, ' ') as INTEGER[]) as values
        FROM query_table(getvariable('mode'))
    ),
    solution AS (
        SELECT
            NULL as part1,
            NULL as part2
    )

SELECT * FROM matches;


SELECT 
    'Part 1' as part,
    part1 as solution,
    getvariable('expected1') as expected,
    solution = expected as correct
FROM solution
UNION
SELECT 
    'Part 2' as part,
    part2 as solution,
    getvariable('expected2') as expected,
    solution = expected as correct
FROM solution;