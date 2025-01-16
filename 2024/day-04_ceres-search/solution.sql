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

CREATE OR REPLACE VIEW x_mas_count AS (
    WITH
        -- -- ~1.25s
        -- corners_join AS (
        --     FROM tokens t, tokens c1, tokens c2, tokens c3, tokens c4
        --     SELECT t.token -- DISTINCT t.idx, t.idy
        --     WHERE t.token = 'A'
        --       AND c1.idx - t.idx = -1 AND c1.idy - t.idy = -1 AND (c1.token = 'S' OR c1.token = 'M')
        --       AND c2.idx - t.idx =  1 AND c2.idy - t.idy = -1 AND (c2.token = 'S' OR c2.token = 'M')
        --       AND c3.idx - t.idx =  1 AND c3.idy - t.idy =  1 AND (c3.token = 'S' OR c3.token = 'M')
        --       AND c4.idx - t.idx = -1 AND c4.idy - t.idy =  1 AND (c4.token = 'S' OR c4.token = 'M')
        --       AND c1.token != c3.token AND c2.token != c4.token
        -- )

        -- -- ~5s
        -- corners_subquery AS (
        --     FROM tokens t
        --     SELECT
        --         (FROM tokens c1 SELECT c1.token WHERE c1.idx - t.idx = -1 AND c1.idy - t.idy = -1) as c1,
        --         (FROM tokens c2 SELECT c2.token WHERE c2.idx - t.idx =  1 AND c2.idy - t.idy = -1) as c2,
        --         (FROM tokens c3 SELECT c3.token WHERE c3.idx - t.idx =  1 AND c3.idy - t.idy =  1) as c3,
        --         (FROM tokens c4 SELECT c4.token WHERE c4.idx - t.idx = -1 AND c4.idy - t.idy =  1) as c4,
        --     WHERE t.token = 'A' AND c1 != c3 AND c2 != c4
        --       AND (c1 = 'S' OR c1 = 'M') AND (c2 = 'S' OR c2 = 'M')
        --       AND (c3 = 'S' OR c3 = 'M') AND (c4 = 'S' OR c4 = 'M')
        -- )

        corners_groupby AS (
            FROM tokens t
            JOIN tokens n ON abs(t.idx - n.idx) = 1 AND abs(t.idy - n.idy) = 1
            SELECT
                t.idx, t.idy,
                list(n.token ORDER BY n.idy ASC, n.idx ASC) as corners,
            WHERE t.token = 'A'
            GROUP BY t.idx, t.idy
            HAVING corners[1] != corners[3] AND corners[2] != corners[4] AND
                   list_sort(corners) = ['M', 'M', 'S', 'S']
        )
    
    SELECT count() as count
    -- FROM a_corners
    FROM corners_groupby
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
