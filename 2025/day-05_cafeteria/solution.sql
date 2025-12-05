SET VARIABLE example = '
    3-5
    10-14
    16-20
    12-18

    1
    5
    8
    11
    17
    32
';
SET VARIABLE exampleSolution1 = 3;
SET VARIABLE exampleSolution2 = 14;

-- SET VARIABLE example = '
--     3-10
--     12-15

--     18-25
--     22-28

--     31-35
--     30-40

--     45-49
--     42-47

--     51-60
--     51-60

--     1
--     5
--     33
-- ';
-- SET VARIABLE exampleSolution1 = 2;
-- SET VARIABLE exampleSolution2 = 52;

CREATE OR REPLACE VIEW example AS SELECT regexp_split_to_table(trim(getvariable('example'), E'\n '), '\n\s*') as line;

CREATE OR REPLACE TABLE input AS
FROM read_text('input') SELECT regexp_split_to_table(trim(content, E'\n '), '\n\s*') as line;
SET VARIABLE solution1 = 828;
SET VARIABLE solution2 = 352681648086146;

.maxrows 75
SET VARIABLE mode = 'example';
-- SET VARIABLE mode = 'input';

CREATE OR REPLACE TABLE parser AS (
    FROM query_table(getvariable('mode'))
    SELECT
         parts: string_split(line, '-')::BIGINT[],
);

CREATE OR REPLACE TABLE ranges AS (
    FROM parser
    SELECT DISTINCT ON (lower, upper)  -- eliminate duplicates in input
           id: row_number() OVER (),
        lower: parts[1],
        upper: parts[2],
    WHERE length(parts) = 2
);

CREATE OR REPLACE TABLE ingredients AS (
    FROM parser
    SELECT
        id: parts[1],
    WHERE length(parts) = 1
);

CREATE OR REPLACE TABLE fresh_ingredients AS (
    FROM ingredients i
    JOIN ranges r ON i.id BETWEEN r.lower AND r.upper
    SELECT DISTINCT ON (i.id) i.id
);

CREATE OR REPLACE TABLE ranges_without_overlaps AS (
    WITH
        eliminate_contained AS (
            FROM ranges r
            ANTI JOIN ranges rr ON r.id != rr.id
                AND r.upper BETWEEN rr.lower AND rr.upper
                AND r.lower BETWEEN rr.lower AND rr.upper
            SELECT r.*
        ),
        with_overlaps AS (
            FROM eliminate_contained r
            LEFT JOIN eliminate_contained rr ON r.id != rr.id AND r.upper BETWEEN rr.lower AND rr.upper
            SELECT
                r.*,
                other_lower: min(rr.lower),
            GROUP BY ALL
        ),
        eliminate_overlaps AS (
            FROM with_overlaps
            SELECT
                id,
                lower,
                upper: coalesce(other_lower - 1, upper),
        )

    FROM eliminate_overlaps
);

CREATE OR REPLACE VIEW results AS (
    SELECT
        part1: (FROM fresh_ingredients SELECT count(*)),
        part2: (FROM ranges_without_overlaps SELECT sum(upper - lower + 1)),
);


CREATE OR REPLACE VIEW solution AS (
    FROM results
    SELECT 
            part: 'Part 1',
          result: part1,
        expected: if(getvariable('mode') = 'example', getvariable('exampleSolution1'), getvariable('solution1')),
         correct: result = expected,
    UNION
    FROM results
    SELECT 
            part: 'Part 2',
          result: part2,
        expected: if(getvariable('mode') = 'example', getvariable('exampleSolution2'), getvariable('solution2')),
         correct: result = expected,
    ORDER BY part
);
FROM solution;
