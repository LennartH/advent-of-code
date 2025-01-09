SET VARIABLE example = '
    3   4
    4   3
    2   5
    1   3
    3   9
    3   3
';
CREATE OR REPLACE VIEW example AS SELECT regexp_split_to_table(trim(getvariable('example'), e'\n '), '\n\s*') as line;
SET VARIABLE exampleSolution1 = 11;
SET VARIABLE exampleSolution2 = 31;

CREATE OR REPLACE TABLE input AS
SELECT regexp_split_to_table(trim(content, e'\n '), '\n\s*') as line FROM read_text('input') input;
SET VARIABLE solution1 = 1873376;
SET VARIABLE solution2 = 18997088;

.maxrows 75
-- SET VARIABLE mode = 'example';
SET VARIABLE mode = 'input';

CREATE OR REPLACE TABLE locations AS (
    SELECT
        split_part(line, '   ', 1)::INTEGER as l,
        split_part(line, '   ', 2)::INTEGER as r,
    FROM query_table(getvariable('mode'))
);

CREATE OR REPLACE TABLE results AS (
    WITH
        distance AS (
            SELECT abs(l - r) as d
            FROM (SELECT l FROM locations ORDER BY l) "left"
            POSITIONAL JOIN (SELECT r FROM locations ORDER BY r) "right"
        ),
        location_counts AS (
            SELECT
                r as l,
                count() as count,
            FROM locations
            GROUP BY r
        ),
        similarity AS (
            SELECT
                l,
                count,
                l * count as score,
            FROM locations
            JOIN location_counts USING (l)
        )

    SELECT
        (SELECT sum(d) as total_distance FROM distance) as part1,
        (SELECT sum(score) as total_score FROM similarity) as part2,
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
