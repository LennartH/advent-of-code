SET VARIABLE example = '
    ............
    ........0...
    .....0......
    .......0....
    ....0.......
    ......A.....
    ............
    ............
    ........A...
    .........A..
    ............
    ............
';
CREATE OR REPLACE TABLE example AS SELECT regexp_split_to_table(trim(getvariable('example'), E'\n '), '\n\s*') as line;
SET VARIABLE exampleSolution1 = 14;
SET VARIABLE exampleSolution2 = NULL;

CREATE OR REPLACE TABLE input AS
SELECT regexp_split_to_table(trim(content, E'\n '), '\n') as line FROM read_text('input');
SET VARIABLE solution1 = 256;
SET VARIABLE solution2 = NULL;

SET VARIABLE mode = 'input'; -- example or input

CREATE OR REPLACE VIEW grid AS (
WITH
    lines AS (
        SELECT
            row_number() OVER () as idy,
            regexp_split_to_array(line, '') as line,
        FROM query_table(getvariable('mode'))
    ),
    grid AS (
        SELECT
            generate_subscripts(line, 1) as idx,
            idy,
            unnest(line) as symbol,
        FROM lines
    )
FROM grid);

CREATE OR REPLACE VIEW antennas AS (
SELECT
    idx, idy,
    symbol as frequency,
FROM grid
WHERE symbol != '.');

SET VARIABLE max_x = (SELECT max(idx) FROM grid);
SET VARIABLE max_y = (SELECT max(idy) FROM grid);
CREATE OR REPLACE MACRO in_area(x, y) AS
    x BETWEEN 1 AND getvariable('max_x') AND
    y BETWEEN 1 AND getvariable('max_y');

CREATE OR REPLACE VIEW antinodes AS (
WITH
    pairs AS (
        SELECT
            frequency,
            a1.idx as a1x,
            a1.idy as a1y,
            a2.idx as a2x,
            a2.idy as a2y,
            a1x - a2x as dx,
            a1y - a2y as dy,
        FROM antennas a1
        JOIN antennas a2 USING (frequency)
        WHERE a1x != a2x AND a1y != a2y
    )
SELECT
    frequency,
    a1x + dx as idx,
    a1y + dy as idy,
FROM pairs
WHERE in_area(idx, idy));

CREATE OR REPLACE VIEW solution AS (
    SELECT
        (SELECT count(DISTINCT (idx, idy)) FROM antinodes) as part1,
        NULL as part2
);

SET VARIABLE expected1 = if(getvariable('mode') = 'example', getvariable('exampleSolution1'), getvariable('solution1'));
SET VARIABLE expected2 = if(getvariable('mode') = 'example', getvariable('exampleSolution2'), getvariable('solution2'));
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

-- region Troubleshooting Utils
PREPARE print_antinodes AS
WITH
    distinct_antinodes AS (
        SELECT DISTINCT idx, idy FROM antinodes
    ),
    symbols AS (
        SELECT
            idx, idy,
            CASE
                WHEN a.idx NOT NULL AND symbol != '.' THEN '_' || symbol || '_'
                WHEN a.idx NOT NULL THEN ' # '
                ELSE ' ' || symbol || ' '
            END as symbol
        FROM grid c
        LEFT JOIN distinct_antinodes a USING (idx, idy)
    )
SELECT
    idy,
    string_agg(symbol, '' ORDER BY idx) as line
FROM symbols
GROUP BY idy
ORDER BY idy;
-- endregion