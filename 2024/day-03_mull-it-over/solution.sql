SET VARIABLE example = '
    xmul(2,4)%&mul[3,7]!@^do_not_mul(5,5)+mul(32,64]then(mul(11,8)mul(8,5))
';
CREATE TABLE example AS SELECT regexp_split_to_table(trim(getvariable('example'), E'\n '), '\n\s*') as line;
SET VARIABLE exampleSolution1 = 161;
SET VARIABLE exampleSolution2 = NULL;

CREATE TABLE input AS
SELECT regexp_split_to_table(trim(content, E'\n '), '\n') as line FROM read_text('input');
SET VARIABLE solution1 = 173785482;
SET VARIABLE solution2 = NULL;

SET VARIABLE mode = 'input'; -- example or input
SET VARIABLE expected1 = if(getvariable('mode') = 'example', getvariable('exampleSolution1'), getvariable('solution1'));
SET VARIABLE expected2 = if(getvariable('mode') = 'example', getvariable('exampleSolution2'), getvariable('solution2'));


SELECT * FROM query_table(getvariable('mode'));

.timer on
WITH
    matches AS (
        SELECT
            row_number() OVER () as idx,
            regexp_extract_all(line, '(mul\(\d{1,3},\d{1,3}\))') as parts
        FROM query_table(getvariable('mode'))
    ),
    multiplications AS (
        SELECT
            *,
            a * b as result
        FROM (
            SELECT
                *,
                unnest(regexp_extract(op, '(\d+),(\d+)', ['a', 'b'])::STRUCT(a INTEGER, b INTEGER))
            FROM (
                SELECT
                    idx,
                    generate_subscripts(parts, 1) as pos,
                    unnest(parts) as op,
                FROM matches
            )
        )
    ),
    solution AS (
        SELECT
            sum(result)::INTEGER as part1,
            NULL as part2
        FROM multiplications
    )

SELECT 
    'Part 1' as part,
    part1 as result,
    getvariable('expected1') as expected,
    result = expected as correct
FROM solution
UNION
SELECT 
    'Part 2' as part,
    part2 as result,
    getvariable('expected2') as expected,
    result = expected as correct
FROM solution;