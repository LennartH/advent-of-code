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
SET VARIABLE mode = 'example';
-- SET VARIABLE mode = 'input';

CREATE OR REPLACE VIEW tokens AS (
    SELECT
        generate_subscripts(tokens, 1) as idx,
        idy,
        (idy - 1)*length(tokens) + idx as pos,
        unnest(tokens) as token,
        idx - idy as d1, 
        idx + idy as d2
    FROM (
        SELECT
            row_number() OVER () as idy,
            string_split(line, '') as tokens,
        FROM query_table(getvariable('mode'))
    )
);

-- CREATE OR REPLACE VIEW xmas_count AS (
--     WITH
--         slices AS (
--             SELECT
--                 idx,
--                 idy,
--                 unnest([
--                     -- horizontal & vertical
--                     string_agg(token, '') OVER (PARTITION BY idy ORDER BY idx asc ROWS 3 PRECEDING),
--                     string_agg(token, '') OVER (PARTITION BY idy ORDER BY idx desc ROWS 3 PRECEDING),
--                     string_agg(token, '') OVER (PARTITION BY idx ORDER BY idy asc ROWS 3 PRECEDING),
--                     string_agg(token, '') OVER (PARTITION BY idx ORDER BY idy desc ROWS 3 PRECEDING),
--                     -- diagonal
--                     string_agg(token, '') OVER (PARTITION BY d1 ORDER BY pos asc ROWS 3 PRECEDING),
--                     string_agg(token, '') OVER (PARTITION BY d1 ORDER BY pos desc ROWS 3 PRECEDING),
--                     string_agg(token, '') OVER (PARTITION BY d2 ORDER BY pos asc ROWS 3 PRECEDING),
--                     string_agg(token, '') OVER (PARTITION BY d2 ORDER BY pos desc ROWS 3 PRECEDING)
--                 ]) as slice
--             FROM tokens
--             WHERE token = 'X'
--         )

--     SELECT count() as count
--     FROM slices
--     WHERE slice = 'XMAS'
-- );

CREATE OR REPLACE TABLE x_mas_count AS (
    WITH
        a_corners AS (
            FROM tokens t
            LEFT JOIN tokens n ON abs(t.idx - n.idx) = 1 AND abs(t.idy - n.idy) = 1
            SELECT
                n.token as corner,
                n.idx as x,
                n.idy as y,
            -- TODO opposite corners have to be different
            WHERE t.token = 'A' --AND n.token IN ('M', 'S') 
            -- GROUP BY t.idx, t.idy, t.token -- TODO use single id instead
            -- HAVING count() FILTER (n.token = 'M') = 2 AND count() FILTER (n.token = 'S') = 2
        )
    
    SELECT count() as count
    FROM boxes
    WHERE box SIMILAR TO 'M.M.A.S.S|M.S.A.M.S|S.S.A.M.M|S.M.A.S.M'
);

CREATE OR REPLACE VIEW results AS (
    SELECT
        -- (SELECT count FROM xmas_count) as part1,
        NULL as part1,
        -- NULL as part2,
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
