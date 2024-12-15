SET VARIABLE example = '
    p=0,4 v=3,-3
    p=6,3 v=-1,-3
    p=10,3 v=-1,2
    p=2,0 v=2,-1
    p=0,0 v=1,3
    p=3,0 v=-2,-2
    p=7,6 v=-1,-3
    p=3,0 v=-1,-2
    p=9,3 v=2,3
    p=7,3 v=-1,2
    p=2,4 v=2,-3
    p=9,5 v=-3,-3
';
CREATE OR REPLACE VIEW example AS SELECT regexp_split_to_table(trim(getvariable('example'), chr(10) || ' '), '\n\s*') as line;
SET VARIABLE exampleSolution1 = 12;
SET VARIABLE exampleSolution2 = NULL;

CREATE OR REPLACE TABLE input AS
SELECT regexp_split_to_table(trim(content, chr(10) || ' '), '\n') as line FROM read_text('input');
SET VARIABLE solution1 = 221616000;
SET VARIABLE solution2 = NULL;

-- SET VARIABLE mode = 'example';
SET VARIABLE mode = 'input';

CREATE OR REPLACE VIEW robots AS (
    WITH
        parts AS (
            SELECT
                row_number() OVER () as idx,
                regexp_split_to_array(line, '[ ,]') as parts,
            FROM query_table(getvariable('mode'))
        )
    
    SELECT
        idx,
        parts[1][3:]::INTEGER as px,
        parts[2]::INTEGER as py,
        parts[3][3:]::INTEGER as dx,
        parts[4]::INTEGER as dy,
        if(getvariable('mode') = 'example', 11, 101) as max_x,
        if(getvariable('mode') = 'example', 7, 103) as max_y,
    FROM parts
);

CREATE OR REPLACE VIEW simulations AS (
    WITH RECURSIVE
        movements AS (
            SELECT
                0 as it,
                * EXCLUDE (px, py),
                px,
                py
            FROM robots
            UNION ALL
            SELECT
                it + 1 as it,
                idx,
                dx,
                dy,
                max_x,
                max_y,
                px + dx as px,
                py + dy as py,
            FROM movements
            WHERE it < 100
        )

    SELECT
        idx,
        fmod(px, max_x)::INTEGER as px,
        fmod(py, max_y)::INTEGER as py,
        dx, dy,
        max_x, max_y,
    FROM movements
    WHERE it = 100
);

CREATE OR REPLACE VIEW results AS (
    WITH
        quadrants AS (
            SELECT
                *,
                px - (max_x - 1) // 2 as norm_x,
                py - (max_y - 1) // 2 as norm_y,
                CASE
                    WHEN norm_x > 0 AND norm_y < 0 THEN 'I'
                    WHEN norm_x < 0 AND norm_y < 0 THEN 'II'
                    WHEN norm_x < 0 AND norm_y > 0 THEN 'III'
                    WHEN norm_x > 0 AND norm_y > 0 THEN 'VI'
                    ELSE NULL
                END as quadrant,
            FROM simulations
            WHERE quadrant IS NOT NULL
        )

    SELECT
        (SELECT product(c)::BIGINT FROM (SELECT count() as c FROM quadrants GROUP BY quadrant)) as part1,
        NULL as part2
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
