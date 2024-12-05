SET VARIABLE example = '
    47|53
    97|13
    97|61
    97|47
    75|29
    61|13
    75|53
    29|13
    97|29
    53|29
    61|53
    97|53
    61|29
    47|13
    75|47
    97|75
    47|61
    75|61
    47|29
    75|13
    53|13

    75,47,61,53,29
    97,61,53,29,13
    75,29,13
    75,97,47,61,53
    61,13,29
    97,13,75,29,47
';
CREATE TABLE example AS SELECT regexp_split_to_table(trim(getvariable('example'), E'\n '), '\n\s*') as line;
SET VARIABLE exampleSolution1 = 143;
SET VARIABLE exampleSolution2 = NULL;

CREATE TABLE input AS
SELECT regexp_split_to_table(trim(content, E'\n '), '\n') as line FROM read_text('input');
SET VARIABLE solution1 = 5588;
SET VARIABLE solution2 = NULL;

SET VARIABLE mode = 'input'; -- example or input
SET VARIABLE expected1 = if(getvariable('mode') = 'example', getvariable('exampleSolution1'), getvariable('solution1'));
SET VARIABLE expected2 = if(getvariable('mode') = 'example', getvariable('exampleSolution2'), getvariable('solution2'));


SELECT * FROM query_table(getvariable('mode'));

.timer on
WITH
    rules AS (
        SELECT
            unnest(regexp_extract(line, '(\d+)\|(\d+)', ['before', 'after'])::STRUCT(before INTEGER, after INTEGER))
        FROM query_table(getvariable('mode'))
        WHERE '|' IN line
    ),
    jobs AS (
        SELECT
            row_number() OVER () as idx,
            string_split(line, ',')::INTEGER[] as pages,
            pages[len(pages) // 2 + 1] as middle,
        FROM query_table(getvariable('mode'))
        WHERE ',' IN line
    ),
    pages AS (
        SELECT 
            * EXCLUDE (after),
            unnest(after) as after,
        FROM (
            SELECT
                idx,
                generate_subscripts(pages, 1) as pos,
                unnest(pages) as before,
                pages[pos+1:] as after,
            FROM jobs
        )
    ),
    valid_jobs AS (
        SELECT * FROM jobs
        WHERE idx NOT IN (
            SELECT
                DISTINCT idx
            FROM pages
            ANTI JOIN rules USING (before, after)
        )
    ),
    solution AS (
        SELECT
            (SELECT sum(middle) FROM valid_jobs) as part1,
            NULL as part2
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