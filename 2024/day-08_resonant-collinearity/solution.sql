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
CREATE OR REPLACE VIEW example AS SELECT regexp_split_to_table(trim(getvariable('example'), E'\n '), '\n\s*') as line;
SET VARIABLE exampleSolution1 = 14;
SET VARIABLE exampleSolution2 = 34;

CREATE OR REPLACE TABLE input AS
SELECT regexp_split_to_table(trim(content, E'\n '), '\n') as line FROM read_text('input');
SET VARIABLE solution1 = 256;
SET VARIABLE solution2 = 1005;

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
        WHERE a1x != a2x OR a1y != a2y
    ),
    rays AS (
        SELECT
            frequency,
            a2x, a2y,
            a1x, a1y,
            dx, dy,
            generate_series(a1x, if(dx > 0, getvariable('max_x'), 1), dx) as ray_x,
            generate_series(a1y, if(dy > 0, getvariable('max_y'), 1), dy) as ray_y,
        FROM pairs
    ),
    ray_points AS (
        SELECT
            frequency,
            a2x, a2y,
            a1x, a1y,
            dx, dy,
            generate_subscripts(if(len(ray_x) > len(ray_y), ray_x, ray_y), 1) as pos,
            unnest(ray_x) as idx,
            unnest(ray_y) as idy,
        FROM rays
    )
FROM ray_points
WHERE idx NOT NULL AND idy NOT NULL);

CREATE OR REPLACE VIEW solution AS (
    SELECT
        count(DISTINCT (idx, idy)) FILTER (pos = 2) as part1,
        count(DISTINCT (idx, idy)) as part2
    FROM antinodes
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
FROM solution;

-- region Troubleshooting Utils
PREPARE print_antinodes AS
WITH
    distinct_antinodes AS (
        SELECT DISTINCT idx, idy FROM antinodes WHERE $1 != 'part1' OR pos = 2
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