SET VARIABLE example = '
    7 6 4 2 1
    1 2 7 8 9
    9 7 6 2 1
    1 3 2 4 5
    8 6 4 4 1
    1 3 6 7 9
';
CREATE TABLE example AS SELECT regexp_split_to_table(trim(getvariable('example'), E'\n '), '\n\s*') as line;
SET VARIABLE exampleSolution1 = 2;
SET VARIABLE exampleSolution2 = 4;

CREATE TABLE input AS
SELECT regexp_split_to_table(trim(content, E'\n '), '\n') as line FROM read_text('input');
SET VARIABLE solution1 = 670;
SET VARIABLE solution2 = 700;

SET VARIABLE mode = 'input'; -- example or input
SET VARIABLE expected1 = if(getvariable('mode') = 'example', getvariable('exampleSolution1'), getvariable('solution1'));
SET VARIABLE expected2 = if(getvariable('mode') = 'example', getvariable('exampleSolution2'), getvariable('solution2'));


SELECT * FROM query_table(getvariable('mode'));

WITH
    reports AS (
        SELECT
            row_number() OVER () as idx,
            cast(regexp_split_to_array(line, ' ') as INTEGER[]) as levels
        FROM query_table(getvariable('mode'))
    ),
    levels AS (
        SELECT * FROM (
            SELECT
                idx,
                generate_subscripts(levels, 1) as pos,
                unnest(levels) as value,
                perm
            FROM reports, LATERAL (SELECT unnest(generate_series(list_count(levels))) as perm)
        )
        WHERE perm != pos
    ),
    diffs AS (
        SELECT * FROM (
            SELECT
                *,
                value - lag(value) OVER (PARTITION BY idx, perm ORDER BY pos asc) as diff
            FROM levels
        )
        WHERE diff IS NOT NULL
    ),
    report_safety AS (
        SELECT
            idx,
            perm,
            count(DISTINCT sign(diff)) = 1 as continous,
            bool_and(abs(diff) BETWEEN 1 AND 3) as within_margin,
            continous AND within_margin as safe
        FROM diffs
        GROUP BY idx, perm
    ),
    safe_reports AS (
        SELECT
            idx,
            perm,
            levels
        FROM reports
        JOIN report_safety USING (idx)
        WHERE safe
    )

SELECT 
    'Part 1' as part,
    count() FILTER (perm = 0) as solution,
    getvariable('expected1') as expected,
    solution = expected as correct
FROM safe_reports
UNION
SELECT 
    'Part 2' as part,
    count(DISTINCT idx) as solution,
    getvariable('expected2') as expected,
    solution = expected as correct
FROM safe_reports;