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

-- Attempt at using simple graph contraction


CREATE OR REPLACE TABLE vertices AS (
    SELECT unnest(generate_series(1, 10)) as id
);

CREATE OR REPLACE TABLE edges AS FROM (VALUES
    (1, 5),
    (1, 10),
    (2, 4),
    (2, 9),
    (3, 8),
    (3, 10),
    (4, 9),
    (5, 6),
    (5, 7),
    (6, 10),
) e(v, w);

CREATE OR REPLACE TABLE closed_neighbourhoods AS (
    SELECT
        r.id as id,
        list_sort(list_distinct(list_prepend(r.id, list_concat(list(e.v), list(e.w))))) as n,
    FROM vertices r
    JOIN edges e ON r.id = e.v OR r.id = e.w
    GROUP BY r.id
);


WITH RECURSIVE
    -- edges AS (
    --     SELECT
    --         edge[1] as v,
    --         edge[2] as w,
    --     FROM (
    --         SELECT DISTINCT list_sort([r1.id, r2.id]) as edge,
    --         FROM region r1
    --         JOIN region r2 ON r1.plant = r2.plant AND abs(r1.idx - r2.idx) + abs(r1.idy - r2.idy) = 1
    --     )
    -- ),
    vertices AS (
        SELECT unnest(generate_series(1, 10)) as id
    ),
    edges AS (
        FROM (VALUES
            (1, 5),
            (1, 10),
            (2, 4),
            (2, 9),
            (3, 8),
            (3, 10),
            (4, 9),
            (5, 6),
            (5, 7),
            (6, 10),
        ) e(v, w)
    ),
    closed_neighbourhoods AS (
        SELECT
            r.id as x,
            list_prepend(r.id, list(e.w)) as n,
        FROM vertices r
        JOIN edges e ON r.id = e.v OR r.id = e.w
        GROUP BY r.id
    )

-- FROM edges
-- ORDER BY v
-- ;

FROM closed_neighbourhoods
ORDER BY x
;


-- -- Attempt at DFS but how is it possible to track all visited positions?
-- CREATE OR REPLACE SEQUENCE seq_idc;
-- WITH RECURSIVE
--     plots AS (
--         SELECT
--             0 as it,
--             nextval('seq_idc') as idc,
--             idy,
--             idx,
--             plant,
--             [id] as visited,
--         FROM region
--         WHERE idy = 1 AND idx = 1
--         UNION ALL
--         SELECT
--             -- if(p.plant = r.plant, p.it + 1, 0) as it,
--             p.it + 1 as it,
--             -- if(p.plant = r.plant, p.idc, nextval('seq_idc')) as idc,
--             if(EXISTS (FROM plots pp WHERE r.id IN pp.visited), p.idc, nextval('seq_idc')) as idc,
--             r.idy as idy,
--             r.idx as idx,
--             r.plant,
--             -- if(p.plant = r.plant, list_prepend(r.id, visited), [r.id]) as visited,
--             list_prepend(r.id, visited) as visited,
--         FROM plots p
--         -- JOIN region r ON p.plant = r.plant AND abs(p.idx - r.idx) + abs(p.idy - r.idy) = 1
--         JOIN region r ON abs(p.idx - r.idx) + abs(p.idy - r.idy) = 1
--         WHERE it < 10
--           AND NOT EXISTS (FROM plots pp WHERE r.id IN pp.visited)
--         --   AND r.id NOT IN p.visited
--     )

-- FROM plots
-- -- ORDER BY it, idy, idx
-- ORDER BY idc
-- ;




WITH
    marked_points AS (
        SELECT
            id, idy, idx, plant,
            -- lag(wdw4 IGNORE NULLS) OVER (PARTITION BY idy ORDER BY idx) as wdw5,
            coalesce(component, lag(component IGNORE NULLS) OVER (PARTITION BY idy ORDER BY idx)) as component,
        FROM (
            SELECT
                *,
                -- nullif(wdw2, true) as wdw3,
                if(same, NULL, row_number() OVER (PARTITION BY idy, same ORDER BY idx)) as component,
            FROM (
                SELECT
                    *,
                    -- row_number() OVER (PARTITION BY idy, plant ORDER BY idx) as wdw,
                    -- rank() OVER (PARTITION BY plant ORDER BY idx) as wdw2,
                    -- dense_rank() OVER (PARTITION BY plant ORDER BY idx) as wdw3,
                    -- lag(plant) OVER (PARTITION BY idy ORDER BY idx) as wdw,
                    coalesce(plant = lag(plant) OVER (PARTITION BY idy ORDER BY idx), false) as same,
                FROM region
            )
        )
        -- WHERE idy < 3
        ORDER BY idy, idx
    ),
    hlines AS (
        SELECT
            any_value(plant) as plant,
            idy,
            component,
            list(id ORDER BY idx) as points,
        FROM marked_points
        GROUP BY idy, component
        -- ORDER BY plant, idy
    ),
    marked_hlines AS (
        SELECT 
            (idx, idy) as id,
            idx, idy, plant,
            coalesce(component, lag(component IGNORE NULLS) OVER (PARTITION BY idx ORDER BY idy)) as component,
        FROM (
            SELECT
                *,
                if(same, NULL, row_number() OVER (PARTITION BY idx, same ORDER BY idy)) as component,
            FROM (
                SELECT
                    *,
                    coalesce(plant = lag(plant) OVER (PARTITION BY idx ORDER BY idy), false) as same,
                FROM (
                    SELECT
                        plant,
                        component as idx,
                        idy,
                    FROM hlines
                )
            )
        )
    ),
    vlines AS (
        SELECT
            any_value(plant) as plant,
            idx,
            component,
            list(id ORDER BY idy) as points,
        FROM marked_hlines
        GROUP BY idx, component
        -- ORDER BY plant, idy
    )

FROM vlines
ORDER BY plant, idx
;


CREATE OR REPLACE VIEW plots AS (
    WITH
        hlines AS (
            SELECT 
                r1.plant,
                r1.idy,
                -- list(DISTINCT (r1.idy, coalesce(r2.idx, r1.idx))) as points, -- bad
                list(DISTINCT (r1.idy, r2.idx)) as points, -- also bad, but less
            FROM region r1 
            LEFT JOIN region r2 ON r1.plant = r2.plant AND r1.idy = r2.idy AND abs(r1.idx - r2.idx) = 1
            GROUP BY r1.plant, r1.idy
            -- delete me
            ORDER BY r1.plant, r1.idy
        ),
        plots AS (
            SELECT
                h1.plant,
                -- flatten(list(h2.points)) as plot,
                h1.points,
                h2.points,
            FROM hlines h1
            JOIN hlines h2 ON h1.plant = h2.plant AND abs(h1.idy - h2.idy) = 1
            -- GROUP BY h1.plant
        )
    FROM plots
    ORDER BY plant
);


-- CREATE OR REPLACE VIEW plots AS (
--     WITH
--         hlines AS (
--             SELECT
--                 plant,
--                 list((idy, idx)) as points,
--             FROM region
--             GROUP BY plant, idy
--         ),
--         vlines AS (
--             SELECT
--                 plant,
--                 list((idy, idx)) as points,
--             FROM region
--             GROUP BY plant, idx
--         )

--     FROM hlines

--     -- SELECT
--     --     h.*,
--     --     (SELECT flatten(list(v.points)) FROM vlines v WHERE list_has_any(h.points, v.points)) as foo
--     -- FROM hlines h
--     -- ORDER BY plant

--     -- SELECT
--     --     r.plant,
--     --     r.idy,
--     --     r.idx,
--     --     (SELECT points FROM hlines WHERE (r.idy, r.idx) IN points)
--     -- FROM region r
-- )



-- SELECT
--     *,
--     rank - lag(rank, 1, 0) OVER (PARTITION BY idy ORDER BY idx) as prev,
--     plant = lag(plant, 1) OVER (PARTITION BY idy ORDER BY idx) as same,
-- FROM (
--     SELECT
--         plant,
--         idy,
--         idx,
--         dense_rank() OVER (PARTITION BY plant ORDER BY idx) as rank,
--     FROM region
--     WHERE idy = 5
-- )
-- ORDER BY idy, idx
-- ;




CREATE OR REPLACE TABLE plots AS (
    WITH RECURSIVE
        -- TODO adjust perimeters schema
        perimeters AS (
            SELECT
                r1.*,
                4 - (SELECT count() FROM region r2 WHERE r1.plant = r2.plant AND abs(r1.idx - r2.idx) + abs(r1.idy - r2.idy) = 1) as perimeter
            FROM region r1
        ),
        plots AS (
            SELECT
                DISTINCT ON (plot)
                0 as it,
                r1.plant as plant,
                -- list_sort([(r1.idy, r1.idx), (r2.idy, r2.idx)])::STRUCT(x BIGINT, y BIGINT)[] as plot,
                list_sort([(r1.idy, r1.idx), (r2.idy, r2.idx)]) as plot,
            FROM region r1
            JOIN region r2 ON r1.plant = r2.plant AND abs(r1.idx - r2.idx) + abs(r1.idy - r2.idy) = 1
            UNION ALL
            SELECT DISTINCT ON (plot) * FROM (
                SELECT
                    any_value(it) as it,
                    any_value(plant) as plant,
                    list_sort(list_distinct(flatten(list(plot)))) as plot,
                FROM (
                    SELECT
                        it + 1 as it,
                        p.plant as plant,
                        (r.idy, r.idx) as pos,
                        p.plot as plot,
                    FROM plots p
                    JOIN region r ON (r.idy, r.idx) IN p.plot
                )
                GROUP BY pos
                HAVING count() > 1
            )
        )

    FROM plots;

    SELECT
        *,
        len(plot) as area,
        (SELECT sum(perimeter) FROM perimeters WHERE (perimeters.idy, perimeters.idx) IN plot) as perimeter,
    FROM plots p
    WHERE NOT EXISTS (FROM plots pp WHERE pp.it > p.it AND list_has_any(p.plot, pp.plot))
    -- delete me
    -- ORDER BY plant, it
);

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