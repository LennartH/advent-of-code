SET VARIABLE example = '
    AAAA
    BBCD
    BBCC
    EEEC
';
SET VARIABLE exampleSolution1 = 140;
SET VARIABLE exampleSolution2 = 80;

SET VARIABLE example = '
    OOOOO
    OXOXO
    OOOOO
    OXOXO
    OOOOO
';
SET VARIABLE exampleSolution1 = 772;
SET VARIABLE exampleSolution2 = 436;

-- FIXME multiple disconnected points touching region edge are not considered
SET VARIABLE example = '
    EEEEE
    EXXXX
    EEEEE
    EXXXX
    EEEEE
';
SET VARIABLE exampleSolution1 = NULL;
SET VARIABLE exampleSolution2 = 236;

-- FIXME counting edges inside doesn't work
SET VARIABLE example = '
    AAAAAA
    AAABBA
    AAABBA
    ABBAAA
    ABBAAA
    AAAAAA
';
SET VARIABLE exampleSolution1 = NULL;
SET VARIABLE exampleSolution2 = 368;

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
-- SET VARIABLE exampleSolution2 = 1206;

CREATE OR REPLACE VIEW example AS SELECT regexp_split_to_table(trim(getvariable('example'), chr(10) || ' '), '\n\s*') as line;

CREATE OR REPLACE TABLE input AS
SELECT regexp_split_to_table(trim(content, chr(10) || ' '), '\n') as line FROM read_text('input');
SET VARIABLE solution1 = 1446042;
SET VARIABLE solution2 = NULL;

SET VARIABLE mode = 'example';
-- SET VARIABLE mode = 'input';

CREATE OR REPLACE VIEW region AS (
    SELECT 
        row_number() OVER () as id,
        * 
    FROM (
        SELECT
            row_number() OVER () as idy,
            unnest(generate_series(1, len(line))) as idx,
            unnest(regexp_split_to_array(line, '')) as plant,
        FROM query_table(getvariable('mode'))
    )
);
SET VARIABLE width = (SELECT max(idx) FROM region);
SET VARIABLE height = (SELECT max(idy) FROM region);

CREATE OR REPLACE VIEW edges AS (
    SELECT
        r1.id v,
        r2.id w,
    FROM region r1
    JOIN region r2 ON r1.plant = r2.plant AND
                      abs(r1.idx - r2.idx) + abs(r1.idy - r2.idy) = 1
);


-- TODO DFS by iterating over nodes one by one (see de2bc3d5c18b133f510ebec01c4a2c3e61c020f9)
-- TODO Recursive scan line approach (see de2bc3d5c18b133f510ebec01c4a2c3e61c020f9)


---------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------
--- Basic contraction algorithm based on "In-database connected component analysis" ---
--- by Bögeholz, H., Brand, M., & Todor, R. A (https://arxiv.org/pdf/1802.09478)    ---
---------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------

-- TODO Integrate edge reduction in each step (as in the paper) instead of joining all edges

-- Basic contraction keeping representatives up to date
CREATE OR REPLACE VIEW components AS (
    WITH RECURSIVE
        contraction AS (
            -- Recursion state is mapping from vertex to its representative
            -- starting with representatives for initial closed neighbourhoods
            SELECT
                v,
                least(v, min(w)) as r,
                false as terminate,
            FROM edges
            GROUP BY v
            UNION ALL (
                WITH
                    -- Contract graph by building reduced set of edges from representatives
                    -- Eliminating duplicates and loop edges eventually terminates recursion
                    reduced_edges AS (
                        SELECT DISTINCT
                            v.r as v,
                            w.r as w,
                        FROM edges e, contraction v, contraction w
                        WHERE e.v = v.v AND e.w = w.v AND v.r != w.r
                    ),
                    -- Representatives for current iteration
                    representatives AS (
                        SELECT
                            v,
                            least(v, min(w)) as r
                        FROM reduced_edges
                        GROUP BY v
                    )
                -- Update representatives, old values are kept
                -- After termination every component will have the same representative
                SELECT
                    l.v as v,
                    coalesce(r.r, l.r) as r,
                    (SELECT count() FROM reduced_edges) = 0 as terminate,
                FROM contraction l
                LEFT OUTER JOIN representatives r ON l.r = r.v
                WHERE NOT terminate
            )
        )
    
    SELECT
        r as component,
        v as id,
    FROM contraction
    WHERE terminate
);

-- -- Adjusted basic contraction terminating "naturally", vertex substitutions need to be reverted afterwards
-- -- FIXME Doesn't work for large example, but for the other two. Issue with multiple plots for same plant?
-- -- Also slower than the other implementation
-- CREATE OR REPLACE TABLE components AS (
--     WITH RECURSIVE
--         substitutions AS (
--             -- Recursion state is mapping from vertex to its representative
--             -- starting with representatives for initial closed neighbourhoods
--             SELECT
--                 0 as it,
--                 v,
--                 least(v, min(w)) as r
--             FROM edges
--             GROUP BY v
--             UNION ALL
--             -- Updated subset of representatives
--             SELECT
--                 any_value(it) + 1 as it,
--                 v,
--                 least(v, min(w)) as r
--             FROM (
--                 -- Contract graph by building reduced set of edges from representatives
--                 -- Eliminating duplicates and loop edges eventually terminates recursion
--                 SELECT DISTINCT
--                     v.it as it,
--                     v.r as v,
--                     w.r as w,
--                 FROM edges e, substitutions v, substitutions w
--                 WHERE e.v = v.v AND e.w = w.v AND v.r != w.r
--             )
--             GROUP BY v
--         ),
--         -- Second recursive CTE to backtrack representative substitutions
--         explode AS (
--             FROM substitutions
--             WHERE it = 0
--             UNION ALL
--             SELECT
--                 r.it as it,
--                 l.v as v,
--                 coalesce(r.r, l.r) as r,
--             FROM explode l
--             JOIN substitutions r ON l.it + 1 = r.it AND l.r = r.v
--         )

--     SELECT
--         max_by(r, it) as component,
--         v as id,
--     FROM explode
--     GROUP BY v
-- );

---------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------

CREATE OR REPLACE VIEW plots AS (
    WITH
        perimeters AS (
            SELECT
                v as id,
                4 - count() as perimeter,
            FROM edges
            GROUP BY v
        ),
        -- outlines AS (
        --     -- For each plot: all edges from vertices to neighbours with different plant
        --     SELECT
        --         c.component as plot,
        --         r2.idy as idy,
        --         r2.idx as idx,
        --         if(r1.idy = r2.idy, 'h', 'v') as dir,
        --     FROM components c
        --     JOIN region r1 ON r1.id = c.id
        --     JOIN region r2 ON r1.plant != r2.plant AND
        --                       abs(r1.idx - r2.idx) + abs(r1.idy - r2.idy) = 1
        -- ),
        borders AS (
            -- For each plot: all edges from vertices to neighbours with different plant
            SELECT
                c.component as plot,
                -- r1.plant as plant,
                (r1.idy, r1.idx) as inside,
                (r2.idy, r2.idx) as outside,
                CASE
                    WHEN r1.idy = r2.idy THEN 'horizontal'
                    WHEN r1.idx = r2.idx THEN 'vertical'
                    ELSE NULL
                END as dir,
            FROM components c
            JOIN region r1 ON r1.id = c.id
            JOIN region r2 ON r1.plant != r2.plant AND
                            abs(r1.idx - r2.idx) + abs(r1.idy - r2.idy) = 1
        ),
        -- horizontal_crossings AS (
        crossings AS (
            -- Horizontal Crossings
            FROM (
                -- For each plot: all border points in horizontal lines
                SELECT
                    plot,
                    outside[1] as idy,
                    unnest([inside[2], outside[2]]) as idx,
                    'h' as dir,
                FROM borders
                WHERE inside[1] = outside[1]
            )
            -- Walk line from left to right, when entering plot keep outside x,
            -- when exiting plot keep inside x. Consecutive points belong to the same side.
            QUALIFY row_number() OVER (PARTITION BY plot, idy ORDER BY idx) % 2 = 1
            UNION ALL
        -- ),
        -- vertical_crossings AS (
            -- Same as horizontal_crossings but with flipped axes
            FROM (
                SELECT
                    plot,
                    unnest([inside[1], outside[1]]) as idy,
                    outside[2] as idx,
                    'v' as dir,
                FROM borders
                WHERE inside[2] = outside[2]
            )
            QUALIFY row_number() OVER (PARTITION BY plot, idx ORDER BY idy) % 2 = 1
        ),
        sides AS (
            -- Mark first of consecutive points as start of a new side
            SELECT
                plot, idx, idy,
                -- If delta is NULL, it's the first crossing of the line -> mark as start
                -- If delta is greater 1, there's a gap between this and the previous crossing -> mark as start
                if(delta = 1, NULL, true) as side_start,
            FROM (
                SELECT
                    plot, dir, idx, idy,
                    if(dir = 'h', idy, idx) as d1, -- When horizontal track dy, otherwhise dx
                    if(dir = 'h', idx, idy) as d2, -- When horizontal group by dx, otherwhise dy
                    d1 - lag(d1) OVER (PARTITION BY plot, dir, d2 ORDER BY d1) as delta,
                FROM crossings
            )
        ),
        plots AS (
            SELECT
                plot,
                any_value(plant) as plant,
                any_value(area) as area,
                any_value(perimeter) as perimeter,
                count(s.side_start) as crossing_sides,
                any_value(min_y) as min_y,
                any_value(max_y) as max_y,
                any_value(min_x) as min_x,
                any_value(max_x) as max_x,
            FROM (
                SELECT
                    component as plot,
                    any_value(r.plant) as plant,
                    sum(p.perimeter) as perimeter,
                    count() as area,
                    min(r.idy) as min_y,
                    max(r.idy) as max_y,
                    min(r.idx) as min_x,
                    max(r.idx) as max_x,
                FROM components c
                JOIN region r ON c.id = r.id
                JOIN perimeters p ON c.id = p.id
                GROUP BY c.component
            ) p
            JOIN sides s USING (plot)
            GROUP BY plot
        )

    -- FIXME count points touching region edge (except when consecutive...)
    SELECT
        plot, plant, area, perimeter,
        crossing_sides 
            + (min_y = 1)::INTEGER
            + (max_y = getvariable('height'))::INTEGER
            + (min_x = 1)::INTEGER
            + (max_x = getvariable('width'))::INTEGER 
        as sides,
        area * perimeter as score1,
        area * sides as score2,
    FROM plots
    -- delete me
    ORDER BY plot
);

-- FROM borders
-- WHERE plot = 53
-- ORDER BY plot, outside[1], inside[1]

-- FROM vertical_crossings
-- WHERE plot = 53
-- ORDER BY plot, idy, idx

-- SELECT
--     plot,
--     idx,
--     idy,
--     idy - lag(idy) OVER (PARTITION BY plot, dir, idx ORDER BY idy) as dy,
-- FROM outlines
-- WHERE plot = 8 AND dir = 'h'
-- ORDER BY plot, idx, idy

-- SELECT
--     plot, idx, idy,
--     if(dy = 1, NULL, true) as side_start, -- Everything except dy = 1 marks the start of a side
-- FROM (
--     SELECT
--         plot, dir, idx, idy,
--         idy - lag(idy) OVER (PARTITION BY plot, idx ORDER BY idy) as dy,
--     FROM horizontal_crossings
-- )
-- -- delete me
-- WHERE plot = 8
-- ORDER BY plot, idx, idy

-- FROM crossings
-- WHERE plot = 8
-- ORDER BY plot, dir, if(dir = 'h', idx, idy), if(dir = 'h', idy, idx)

-- SELECT
--     plot, idx, idy,
--     if(delta = 1, NULL, true) as side_start, -- Everything except 1 marks the start of a side
-- FROM (
--     SELECT
--         plot, dir, idx, idy,
--         if(dir = 'h', idy, idx) as d1, -- When horizontal track dy, otherwhise dx
--         if(dir = 'h', idx, idy) as d2,
--         d1 - lag(d1) OVER (PARTITION BY plot, dir, d2 ORDER BY d1) as delta,
--     FROM crossings
-- )
-- -- delete me
-- WHERE plot = 8
-- ORDER BY plot, idx, idy
-- ;

-- SELECT
--     outy as idy,
--     idx,
-- FROM (
--     SELECT
--         *,
--         row_number() OVER (PARTITION BY outy ORDER BY idx) % 2 = 1 as pick,
--     FROM (
--         SELECT
--             outy,
--             unnest([outx, inx]) as idx,
--         FROM outline
--         WHERE iny = outy
--     )
-- )
-- WHERE pick
-- ORDER BY idx, idy;


SET VARIABLE remainder = (SELECT
    ((SELECT count() FROM region) - (SELECT sum(area) FROM plots)) * 4
);
CREATE OR REPLACE VIEW solution AS (
    SELECT
        sum(score1) + getvariable('remainder') as part1,
        sum(score2) + getvariable('remainder') as part2,
    FROM plots
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

-- region Troubleshooting Utils
-- TODO add series for idx (with sensible padding)
-- TODO add arguments for the area to print
PREPARE print_plot AS
    -- SELECT
    --     0 as idy,
    --     list_aggregate(generate_series(1, 10), 'string_agg', ' ') as line,
    --     0 as idy,
    -- UNION ALL
    SELECT
        r.idy,
        string_agg(if(c.id, r.plant, '.'), ' ' ORDER BY r.idx) as line,
        -- r.idy::varchar as idy,
    FROM region r
    LEFT JOIN components c ON c.component = $1 AND c.id = r.id
    -- LEFT JOIN components c ON c.component = 53 AND c.id = r.id
    GROUP BY r.idy
    -- UNION ALL
    -- SELECT
    --     11 as idy,
    --     list_aggregate(generate_series(1, 10), 'string_agg', ' ') as line,
    --     11 as idy
    ORDER BY r.idy;

PREPARE print_border AS
    WITH
        borders AS (
            SELECT
                c.component as plot,
                r1.id as inside,
                r2.id as outside,
            FROM components c
            JOIN region r1 ON r1.id = c.id
            JOIN region r2 ON r1.plant != r2.plant AND
                            abs(r1.idx - r2.idx) + abs(r1.idy - r2.idy) = 1
            WHERE plot = $1
        )

    SELECT
        idy,
        string_agg(symbol, ' ' ORDER BY idx) as line,
    FROM (
        SELECT
            any_value(r.idy) as idy,
            any_value(r.idx) as idx,
            any_value(CASE
                WHEN r.id = b.inside THEN 'O'
                WHEN r.id = b.outside THEN 'x'
                ELSE '.'
            END) as symbol,
        FROM region r
        LEFT JOIN borders b ON r.id = b.inside OR r.id = b.outside
        GROUP BY r.id
    )
    GROUP BY idy
    ORDER BY idy NULLS FIRST;
-- endregion