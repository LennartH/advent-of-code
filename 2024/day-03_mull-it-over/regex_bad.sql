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


SELECT * FROM query_table(getvariable('mode'));

.timer on
WITH
    symbols AS (
        SELECT
            idx,
            generate_subscripts(chars, 1) as pos,
            unnest(chars) as c
        FROM (
            SELECT
                row_number() OVER () as idx,
                string_to_array(line || repeat('x', 8), '') as chars,
            FROM query_table(getvariable('mode'))
        )
    ),
    slices AS (
        SELECT
            idx,
            pos,
            c,
            string_agg(c, '') OVER (ROWS 11 PRECEDING) as slice
        FROM symbols
        QUALIFY idx > 1 OR pos > 11
    ),
    operations AS (
        SELECT
            *,
            lag(control, 1, true IGNORE NULLS) OVER (ORDER BY idx, pos) as enabled
        FROM (
            SELECT
                idx,
                pos,
                slice,
                NULL as result,
                true as control
            FROM slices
            WHERE slice ^@ 'do()'
            UNION ALL
            SELECT
                idx,
                pos,
                slice,
                NULL,
                false
            FROM slices
            WHERE slice ^@ 'don''t()'
            UNION ALL
            SELECT 
                DISTINCT ON(slice)
                idx,
                pos,
                slice,
                a::INTEGER * b::INTEGER,
                NULL
            FROM (
                SELECT
                    idx,
                    pos,
                    slice,
                    position(',' IN slice) as comma,
                    position(')' IN slice) as close,
                    slice[5:comma-1] as a,
                    slice[comma+1:close-1] as b
                FROM slices
                WHERE slice ^@ 'mul(' AND comma > 5 AND close > 7 AND close - comma > 1
                  AND a IN cast(range(1, 1000) AS varchar[]) AND b IN cast(range(1, 1000) AS varchar[])
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