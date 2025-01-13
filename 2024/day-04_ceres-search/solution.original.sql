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
CREATE TABLE example AS SELECT regexp_split_to_table(trim(getvariable('example'), E'\n '), '\n\s*') as line;
SET VARIABLE exampleSolution1 = 18;
SET VARIABLE exampleSolution2 = 9;

CREATE TABLE input AS
SELECT regexp_split_to_table(trim(content, E'\n '), '\n') as line FROM read_text('input');
SET VARIABLE solution1 = 2633;
SET VARIABLE solution2 = 1936;

SET VARIABLE mode = 'input'; -- example or input
SET VARIABLE expected1 = if(getvariable('mode') = 'example', getvariable('exampleSolution1'), getvariable('solution1'));
SET VARIABLE expected2 = if(getvariable('mode') = 'example', getvariable('exampleSolution2'), getvariable('solution2'));


WITH
    tokens AS (
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
    ),
    slices AS (
        SELECT
            idx,
            idy,
            unnest([
                -- horizontal & vertical
                string_agg(token, '') OVER (PARTITION BY idy ORDER BY idx asc ROWS 3 PRECEDING),
                string_agg(token, '') OVER (PARTITION BY idy ORDER BY idx desc ROWS 3 PRECEDING),
                string_agg(token, '') OVER (PARTITION BY idx ORDER BY idy asc ROWS 3 PRECEDING),
                string_agg(token, '') OVER (PARTITION BY idx ORDER BY idy desc ROWS 3 PRECEDING),
                -- diagonal
                string_agg(token, '') OVER (PARTITION BY d1 ORDER BY pos asc ROWS 3 PRECEDING),
                string_agg(token, '') OVER (PARTITION BY d1 ORDER BY pos desc ROWS 3 PRECEDING),
                string_agg(token, '') OVER (PARTITION BY d2 ORDER BY pos asc ROWS 3 PRECEDING),
                string_agg(token, '') OVER (PARTITION BY d2 ORDER BY pos desc ROWS 3 PRECEDING)
            ]) as slice
        FROM tokens
    ),
    boxes AS (
        SELECT
            idx,
            idy,
            string_agg(slice, '') OVER (PARTITION BY idx ORDER BY idy asc ROWS 2 PRECEDING) as box
        FROM (
            SELECT
                idx,
                idy,
                string_agg(token, '') OVER (PARTITION BY idy ORDER BY idx asc ROWS 2 PRECEDING) as slice
            FROM tokens
        )
    ),
    solution AS (
        SELECT
            (SELECT count() FILTER (slice = 'XMAS') FROM slices) as part1,
            (SELECT count() FILTER (box SIMILAR TO 'M.M.A.S.S|M.S.A.M.S|S.S.A.M.M|S.M.A.S.M') FROM boxes) as part2
    )

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