SET VARIABLE example = '
    3   4
    4   3
    2   5
    1   3
    3   9
    3   3
';
CREATE OR REPLACE VIEW example AS SELECT regexp_split_to_table(trim(getvariable('example'), E'\n '), '\n\s*') as line;
SET VARIABLE exampleSolution1 = 11;
SET VARIABLE exampleSolution2 = 31;

CREATE OR REPLACE TABLE input AS
SELECT regexp_split_to_table(trim(content, E'\n '), '\n\s*') as line FROM read_text('input');
SET VARIABLE solution1 = 1873376;
SET VARIABLE solution2 = 18997088;

.maxrows 75
-- SET VARIABLE mode = 'example';
SET VARIABLE mode = 'input';

CREATE OR REPLACE TABLE locations AS (
    FROM query_table(getvariable('mode'))
    SELECT
        split_part(line, '   ', 1)::INTEGER as l,
        split_part(line, '   ', 2)::INTEGER as r,
);

CREATE OR REPLACE TABLE results AS (
    WITH
        distance AS (
            FROM (FROM locations SELECT l ORDER BY l)
            POSITIONAL JOIN (FROM locations SELECT r ORDER BY r)
            SELECT abs(l - r) as d
        ),
        location_counts AS (
            FROM locations
            SELECT
                r as l,
                count() as count,
            GROUP BY r
        ),
        similarity AS (
            FROM locations
            JOIN location_counts USING (l)
            SELECT
                l,
                count,
                l * count as score,
        )

    SELECT
        (FROM distance SELECT sum(d)) as part1,
        (FROM similarity SELECT sum(score)) as part2,
);


CREATE OR REPLACE VIEW solution AS (
    SELECT 
        'Part 1' as part,
        part1 as result,
        if(getvariable('mode') = 'example', getvariable('exampleSolution1'), getvariable('solution1')) as expected,
        result = expected as correct
    FROM results
    UNION
    SELECT 
        'Part 2' as part,
        part2 as result,
        if(getvariable('mode') = 'example', getvariable('exampleSolution2'), getvariable('solution2')) as expected,
        result = expected as correct
    FROM results
    ORDER BY part
);
FROM solution;
