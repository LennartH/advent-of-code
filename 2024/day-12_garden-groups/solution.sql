SET VARIABLE example = '
    AAAA
    BBCD
    BBCC
    EEEC
';
SET VARIABLE exampleSolution1 = 140;


-- SET VARIABLE example = '
--     AAAAABBAAAA
--     AAABBBBBAAA
--     BBBBAAAAAAA
--     BAAAAABBBBB
-- ';



SET VARIABLE example = '
    AAABC
    AAABC
    AAABC
    CCCCC
';




-- SET VARIABLE example = '
--     OOOOO
--     OXOXO
--     OOOOO
--     OXOXO
--     OOOOO
-- ';
-- SET VARIABLE exampleSolution1 = 772;

-- SET VARIABLE example = '
--     RRRRIICCFF
--     RRRRIICCCF
--     VVRRRCCFFF
--     VVRCCCJFFF
--     VVVVCJJCFE
--     VVIVCCJJEE
--     VVIIICJJEE
--     MIIIIIJJEE
--     MIIISIJEEE
--     MMMISSJEEE
-- ';
-- SET VARIABLE exampleSolution1 = 1930;

CREATE OR REPLACE VIEW example AS SELECT regexp_split_to_table(trim(getvariable('example'), chr(10) || ' '), '\n\s*') as line;
SET VARIABLE exampleSolution2 = NULL;

CREATE OR REPLACE TABLE input AS
SELECT regexp_split_to_table(trim(content, chr(10) || ' '), '\n') as line FROM read_text('input');
SET VARIABLE solution1 = NULL;
SET VARIABLE solution2 = NULL;

SET VARIABLE mode = 'example';
-- SET VARIABLE mode = 'input';

CREATE OR REPLACE VIEW region AS (
    -- TODO adjust region schema
    -- SELECT (idy, idx)::STRUCT(y BIGINT, x BIGINT) as id, * FROM (
    -- SELECT (idy, idx) as id, * FROM (
    SELECT row_number() OVER () as id, * FROM (
        SELECT
            row_number() OVER () as idy,
            unnest(generate_series(1, len(line))) as idx,
            unnest(regexp_split_to_array(line, '')) as plant,
        FROM query_table(getvariable('mode'))
    )
);


-- CREATE OR REPLACE TABLE vertices AS (
--     -- SELECT unnest(generate_series(1, 10)) as id
--     SELECT unnest(generate_series(1, 15)) as id
-- );

-- CREATE OR REPLACE TABLE edges AS FROM (
--     WITH 
--         edges AS (
--             FROM (VALUES
--                 (1, 5),
--                 (1, 10),
--                 (2, 4),
--                 (2, 9),
--                 (3, 8),
--                 (3, 10),
--                 (4, 9),
--                 (5, 6),
--                 (5, 7),
--                 (6, 10),

--                 (7, 11),
--                 (7, 12),
--                 (11, 13),
--                 (12, 13),
--                 (12, 14),
--                 (14, 15),
--             ) e(v, w)
--         )
    
--     SELECT v, w FROM edges
--     UNION ALL
--     SELECT w, v FROM edges
-- );


-- TODO DFS by iterating over nodes one by one (see de2bc3d5c18b133f510ebec01c4a2c3e61c020f9)
-- TODO Recursive scan line approach (see de2bc3d5c18b133f510ebec01c4a2c3e61c020f9)


-- Adjusted basic contraction terminating "naturally", vertex substitutions need to be reverted afterwards
CREATE OR REPLACE TABLE components AS (
    WITH RECURSIVE
        substitutions AS (
            -- Recursion state is mapping from vertex to its representative
            -- starting with representatives for initial closed neighbourhoods
            SELECT
                0 as it,
                v,
                least(v, min(w)) as r
            FROM edges
            GROUP BY v
            UNION ALL
            -- Updated subset of representatives
            SELECT
                any_value(it) + 1 as it,
                v,
                least(v, min(w)) as r
            FROM (
                -- Contract graph by building reduced set of edges from representatives
                -- Eliminating duplicates and loop edges eventually terminates recursion
                SELECT DISTINCT
                    v.it as it,
                    v.r as v,
                    w.r as w,
                FROM edges e, substitutions v, substitutions w
                WHERE e.v = v.v AND e.w = w.v AND v.r != w.r
            )
            GROUP BY v
        ),
        -- Second recursive CTE to backtrack representative substitutions
        explode AS (
            FROM substitutions
            WHERE it = 0
            UNION ALL
            SELECT
                r.it as it,
                l.v as v,
                coalesce(r.r, l.r) as r,
            FROM explode l
            JOIN substitutions r ON l.it + 1 = r.it AND l.r = r.v
        )

    SELECT
        max_by(r, it) as component,
        v,
    FROM explode
    GROUP BY v
);

-- -- Basic contraction keeping representatives up to date
-- CREATE OR REPLACE TABLE components AS (
--     WITH RECURSIVE
--         contraction AS (
--             -- Recursion state is mapping from vertex to its representative
--             -- starting with representatives for initial closed neighbourhoods
--             SELECT
--                 v,
--                 least(v, min(w)) as r,
--                 false as terminate,
--             FROM edges
--             GROUP BY v
--             UNION ALL (
--                 WITH
--                     -- Contract graph by building reduced set of edges from representatives
--                     -- Eliminating duplicates and loop edges eventually terminates recursion
--                     reduced_edges AS (
--                         SELECT DISTINCT
--                             v.r as v,
--                             w.r as w,
--                         FROM edges e, contraction v, contraction w
--                         WHERE e.v = v.v AND e.w = w.v AND v.r != w.r
--                     ),
--                     -- Representatives for current iteration
--                     representatives AS (
--                         SELECT
--                             v,
--                             least(v, min(w)) as r
--                         FROM reduced_edges
--                         GROUP BY v
--                     )
--                 -- Update representatives, old values are kept
--                 -- After termination every component will have the same representative
--                 SELECT
--                     l.v as v,
--                     coalesce(r.r, l.r) as r,
--                     (SELECT count() FROM reduced_edges) = 0 as terminate,
--                 FROM contraction l
--                 LEFT OUTER JOIN representatives r ON l.r = r.v
--                 WHERE NOT terminate
--             )
--         )
    
--     SELECT
--         r as component,
--         v,
--     FROM contraction
--     WHERE terminate
-- );

WITH 
    perimeters AS (
        SELECT
            r1.*,
            4 - (SELECT count() FROM region r2 WHERE r1.plant = r2.plant AND abs(r1.idx - r2.idx) + abs(r1.idy - r2.idy) = 1) as perimeter
        FROM region r1
    )
FROM perimeters
;

CREATE OR REPLACE VIEW solution AS (
    SELECT
        (SELECT sum(area * perimeter) FROM plots) + (((SELECT count() FROM region) - (SELECT sum(area) FROM plots)) * 4) as part1,
        NULL as part2
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
FROM solution
ORDER BY part;