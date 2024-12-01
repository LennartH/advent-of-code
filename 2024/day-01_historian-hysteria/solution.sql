SET VARIABLE example = '
    3   4
    4   3
    2   5
    1   3
    3   9
    3   3
';
CREATE TABLE example AS SELECT regexp_split_to_table(trim(getvariable('example'), E'\n '), '\n\s*') as line;
SET VARIABLE exampleSolution1 = 11;
SET VARIABLE exampleSolution2 = NULL;

CREATE TABLE input AS
SELECT regexp_split_to_table(trim(content, E'\n '), '\n') as line
FROM read_text('input');
SET VARIABLE solution1 = 1873376;
SET VARIABLE solution2 = NULL;

SET VARIABLE mode = 'input'; -- example or input
SET VARIABLE expected1 = if(getvariable('mode') = 'example', getvariable('exampleSolution1'), getvariable('solution1'));
SET VARIABLE expected2 = if(getvariable('mode') = 'example', getvariable('exampleSolution2'), getvariable('solution2'));


SELECT * FROM query_table(getvariable('mode'));

WITH
    location_ids AS (
        SELECT
            cast(split_part(line, '   ', 1) AS INTEGER) as location_id_a,
            cast(split_part(line, '   ', 2) AS INTEGER) as location_id_b
        FROM query_table(getvariable('mode'))
    ),
    ordered_location_ids_a AS (
        SELECT 
            row_number() OVER (ORDER BY location_id_a asc) as idx,
            location_id_a
        FROM location_ids
    ),
    ordered_location_ids_b AS (
        SELECT 
            row_number() OVER (ORDER BY location_id_b asc) as idx,
            location_id_b 
        FROM location_ids
    ),
    location_id_distance AS (
        SELECT 
            *,
            @(location_id_a - location_id_b) as distance 
        FROM ordered_location_ids_a 
        JOIN ordered_location_ids_b USING (idx)
        ORDER BY idx
    )

SELECT 
    'Part 1' as part,
    sum(distance) as solution,
    getvariable('expected1') as expected,
    solution = expected as correct
FROM location_id_distance
UNION
SELECT 
    'Part 2' as part,
    NULL as solution,
    getvariable('expected2') as expected,
    solution = expected as correct
FROM location_id_distance;