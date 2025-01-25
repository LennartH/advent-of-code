SET VARIABLE example = '
    MMMSXXMASM
    MSAMXMSMSA
    AMXSXMAAMM
    MSAMASMSMX
    XMASAMXAMM
    XXAMMXXAMA
    SMSMSASXSS
    SAXAMASAAA
    MAMMMXMMMM
    MXMXAXMASX
';
CREATE OR REPLACE VIEW example AS SELECT regexp_split_to_table(trim(getvariable('example'), E'\n '), '\n\s*') as line;
SET VARIABLE exampleSolution1 = 18;
SET VARIABLE exampleSolution2 = 9;

CREATE OR REPLACE TABLE input AS
FROM read_text('input') SELECT regexp_split_to_table(trim(content, E'\n '), '\n\s*') as line;
SET VARIABLE solution1 = 2633;
SET VARIABLE solution2 = 1936;

.maxrows 75
-- SET VARIABLE mode = 'example';
SET VARIABLE mode = 'input';

CREATE OR REPLACE TABLE tokens AS (
    SELECT
        generate_subscripts(tokens, 1) as x,
        y,
        (y - 1)*length(tokens) + x as pos,
        unnest(tokens) as token,
        x - y as d1, 
        x + y as d2
    FROM (
        SELECT
            row_number() OVER () as y,
            string_split(line, '') as tokens,
        FROM query_table(getvariable('mode'))
    )
);

CREATE OR REPLACE TABLE xmas_count AS (
    WITH
        slices AS (
            FROM tokens SELECT string_agg(token, '') OVER (PARTITION BY y ORDER BY x asc ROWS 3 PRECEDING) as slice
            UNION ALL
            FROM tokens SELECT string_agg(token, '') OVER (PARTITION BY y ORDER BY x desc ROWS 3 PRECEDING) as slice
            UNION ALL
            FROM tokens SELECT string_agg(token, '') OVER (PARTITION BY x ORDER BY y asc ROWS 3 PRECEDING) as slice
            UNION ALL
            FROM tokens SELECT string_agg(token, '') OVER (PARTITION BY x ORDER BY y desc ROWS 3 PRECEDING) as slice
            UNION ALL
            FROM tokens SELECT string_agg(token, '') OVER (PARTITION BY d1 ORDER BY pos asc ROWS 3 PRECEDING) as slice
            UNION ALL
            FROM tokens SELECT string_agg(token, '') OVER (PARTITION BY d1 ORDER BY pos desc ROWS 3 PRECEDING) as slice
            UNION ALL
            FROM tokens SELECT string_agg(token, '') OVER (PARTITION BY d2 ORDER BY pos asc ROWS 3 PRECEDING) as slice
            UNION ALL
            FROM tokens SELECT string_agg(token, '') OVER (PARTITION BY d2 ORDER BY pos desc ROWS 3 PRECEDING) as slice
        )

    FROM slices
    SELECT count() as count
    WHERE slice = 'XMAS'
);

CREATE OR REPLACE TABLE x_mas_count AS (
    WITH
        corners_window AS (
            FROM tokens
            SELECT
                token,
                lag(token)  OVER diagonal1 as c1,
                lag(token)  OVER diagonal2 as c2,
                lead(token) OVER diagonal1 as c3,
                lead(token) OVER diagonal2 as c4
            WINDOW 
                diagonal1 AS (PARTITION BY d1 ORDER BY pos),
                diagonal2 AS (PARTITION BY d2 ORDER BY pos)
            QUALIFY token = 'A' AND c1 != c3 AND c2 != c4
                AND (c1 = 'S' OR c1 = 'M') AND (c2 = 'S' OR c2 = 'M')
                AND (c3 = 'S' OR c3 = 'M') AND (c4 = 'S' OR c4 = 'M')
        )
    
    SELECT count() as count
    FROM corners_window
);

CREATE OR REPLACE TABLE results AS (
    SELECT
        (SELECT count FROM xmas_count) as part1,
        (SELECT count FROM x_mas_count) as part2,
);


CREATE OR REPLACE VIEW solution AS (
    FROM results
    SELECT 
        'Part 1' as part,
        part1 as result,
        if(getvariable('mode') = 'example', getvariable('exampleSolution1'), getvariable('solution1')) as expected,
        result = expected as correct
    UNION
    FROM results
    SELECT 
        'Part 2' as part,
        part2 as result,
        if(getvariable('mode') = 'example', getvariable('exampleSolution2'), getvariable('solution2')) as expected,
        result = expected as correct
    ORDER BY part
);
FROM solution;
