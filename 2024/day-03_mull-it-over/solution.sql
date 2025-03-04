SET VARIABLE example = '
    xmul(2,4)&mul[3,7]!^don''t()_mul(5,5)+mul(32,64](mul(11,8)undo()?mul(8,5))
';
CREATE TABLE example AS SELECT regexp_split_to_table(trim(getvariable('example'), E'\n '), '\n\s*') as line;
SET VARIABLE exampleSolution1 = 161;
SET VARIABLE exampleSolution2 = 48;

CREATE TABLE input AS
SELECT regexp_split_to_table(trim(content, E'\n '), '\n') as line FROM read_text('input');
SET VARIABLE solution1 = 173785482;
SET VARIABLE solution2 = 83158140;

SET VARIABLE mode = 'input'; -- example or input
SET VARIABLE expected1 = if(getvariable('mode') = 'example', getvariable('exampleSolution1'), getvariable('solution1'));
SET VARIABLE expected2 = if(getvariable('mode') = 'example', getvariable('exampleSolution2'), getvariable('solution2'));


WITH
    matches AS (
        SELECT
            row_number() OVER () as idx,
            regexp_extract_all(line, '(mul\(\d{1,3},\d{1,3}\)|do(n''t)?\(\))') as parts
        FROM query_table(getvariable('mode'))
    ),
    operations AS (
        SELECT
            *,
            lag(control, 1, true IGNORE NULLS) OVER (ORDER BY idx, pos) as enabled
        FROM (
            SELECT
                *,
                nullif(a, '')::INTEGER * nullif(b, '')::INTEGER as result,
                CASE WHEN op ^@ 'mul' THEN NULL ELSE op = 'do()' END as control
            FROM (
                SELECT
                    *,
                    unnest(regexp_extract(op, '(\d+),(\d+)', ['a', 'b']))
                FROM (
                    SELECT
                        idx,
                        generate_subscripts(parts, 1) as pos,
                        unnest(parts) as op,
                    FROM matches
                )
            )
        )
    ),
    solution AS (
        SELECT
            sum(result) as part1,
            sum(result) FILTER (enabled) as part2
        FROM operations
    )


SELECT 
    'Part 1' as part,
    part1::INTEGER as result,
    getvariable('expected1') as expected,
    result = expected as correct
FROM solution
UNION
SELECT 
    'Part 2' as part,
    part2::INTEGER as result,
    getvariable('expected2') as expected,
    result = expected as correct
FROM solution;