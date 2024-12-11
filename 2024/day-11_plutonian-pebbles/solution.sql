SET VARIABLE example = '
    1 2024 1 0 9 9 2021976
';
CREATE OR REPLACE VIEW example AS SELECT regexp_split_to_table(trim(getvariable('example'), chr(10) || ' '), '\n\s*') as line;
SET VARIABLE exampleSolution1 = 55312;
SET VARIABLE exampleSolution2 = NULL;

CREATE OR REPLACE TABLE input AS
SELECT regexp_split_to_table(trim(content, chr(10) || ' '), '\n') as line FROM read_text('input');
SET VARIABLE solution1 = NULL;
SET VARIABLE solution2 = NULL;

SET VARIABLE mode = 'example';
-- SET VARIABLE mode = 'input';

CREATE OR REPLACE VIEW pebbles AS (
    SELECT
        unnest(generate_series(1, len(values))) as idx,
        unnest(values) as value,
    FROM (
        SELECT
            cast(regexp_split_to_array(line, ' ') as INTEGER[]) as values
        FROM query_table(getvariable('mode'))
    )
);

CREATE OR REPLACE VIEW blinks AS (
    WITH RECURSIVE
        blinks AS (
            SELECT
                0 as blink,
                idx,
                value,
            FROM pebbles
            UNION ALL
            SELECT
                blink + 1 as blink,
                idx,
                CASE
                    WHEN value = 0 THEN 1
                    WHEN len(value::str) % 2 = 0 THEN unnest([value::varchar[:len(value::varchar) / 2]::int, value::varchar[(len(value::varchar) / 2) + 1:]::int])
                    ELSE value * 2024
                END as value,
            FROM blinks
            WHERE blink < 1
        )
FROM blinks
);

CREATE OR REPLACE VIEW solution AS (
    SELECT
        NULL as part1,
        NULL as part2
);


SELECT 
    'Part 1' as part,
    part1 as result,
    if(getvariable('mode') = 'example', getvariable('exampleSolution1'), getvariable('solution1')) as expected,
    result = expected as correct
FROM solution
UNION
SELECT 
    'Part 2' as part,
    part2 as result,
    if(getvariable('mode') = 'example', getvariable('exampleSolution2'), getvariable('solution2')) as expected,
    result = expected as correct
FROM solution
ORDER BY part;