-- SET VARIABLE example = '
--     AAAA
--     BBCD
--     BBCC
--     EEEC
-- ';
-- SET VARIABLE exampleSolution1 = 140;
-- SET VARIABLE exampleSolution2 = 80;

-- SET VARIABLE example = '
--     OOOOO
--     OXOXO
--     OOOOO
--     OXOXO
--     OOOOO
-- ';
-- SET VARIABLE exampleSolution1 = 772;
-- SET VARIABLE exampleSolution2 = 436;

-- SET VARIABLE example = '
--     EEEEE
--     EXXXX
--     EEEEE
--     EXXXX
--     EEEEE
-- ';
-- SET VARIABLE exampleSolution1 = 692;
-- SET VARIABLE exampleSolution2 = 236;

-- SET VARIABLE example = '
--     AAAAAA
--     AAABBA
--     AAABBA
--     ABBAAA
--     ABBAAA
--     AAAAAA
-- ';
-- SET VARIABLE exampleSolution1 = 1184;
-- SET VARIABLE exampleSolution2 = 368;

SET VARIABLE example = '
    RRRRIICCFF
    RRRRIICCCF
    VVRRRCCFFF
    VVRCCCJFFF
    VVVVCJJCFE
    VVIVCCJJEE
    VVIIICJJEE
    MIIIIIJJEE
    MIIISIJEEE
    MMMISSJEEE
';
SET VARIABLE exampleSolution1 = 1930;
SET VARIABLE exampleSolution2 = 1206;

CREATE OR REPLACE VIEW example AS SELECT regexp_split_to_table(trim(getvariable('example'), chr(10) || ' '), '\n\s*') as line;

CREATE OR REPLACE TABLE input AS
SELECT regexp_split_to_table(trim(content, chr(10) || ' '), '\n') as line FROM read_text('input');
SET VARIABLE solution1 = 1446042;
SET VARIABLE solution2 = 902742;

-- SET VARIABLE mode = 'example';
SET VARIABLE mode = 'input';

CREATE OR REPLACE TABLE region AS (
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
-- Variables "break" interactive mode (changing example)
SET VARIABLE width = (SELECT max(idx) FROM region);
SET VARIABLE height = (SELECT max(idy) FROM region);

CREATE OR REPLACE TABLE edges AS (
    SELECT
        r1.id v,
        r2.id w,
    FROM region r1
    JOIN region r2 ON r1.plant = r2.plant AND
                      abs(r1.idx - r2.idx) + abs(r1.idy - r2.idy) = 1
);


-- TODO DFS by iterating over nodes one by one (see de2bc3d5c18b133f510ebec01c4a2c3e61c020f9)
--      Other implementation: https://github.com/WilliamLP/AdventOfCode/blob/master/2024/day12.sql

-- TODO Recursive scan line approach (see de2bc3d5c18b133f510ebec01c4a2c3e61c020f9)


---------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------
--- Basic contraction algorithm based on "In-database connected component analysis" ---
--- by Bögeholz, H., Brand, M., & Todor, R. A (https://arxiv.org/pdf/1802.09478)    ---
---------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------

-- TODO Integrate edge reduction in each step (as in the paper) instead of joining all edges
-- TODO Implement randomized contraction

-- Basic contraction keeping representatives up to date
CREATE OR REPLACE TABLE components AS (
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

-- TODO Implement "naturally" terminating contraction (see ecca97646939c879e3d54b904a22884a23c60428)

---------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------

CREATE OR REPLACE TABLE plots AS (
    WITH
        borders AS (
            SELECT
                *,
                CASE
                    WHEN inside[1] = outside[1] THEN 'h'
                    WHEN inside[2] = outside[2] THEN 'v'
                    ELSE NULL
                END as dir,
            FROM (
                -- For each plot: all edges from vertices to neighbours with different plant
                SELECT
                    c.component as plot,
                    (r1.idy, r1.idx) as inside,
                    (r2.idy, r2.idx) as outside,
                FROM components c
                JOIN region r1 ON r1.id = c.id
                JOIN region r2 ON r1.plant != r2.plant AND
                                abs(r1.idx - r2.idx) + abs(r1.idy - r2.idy) = 1
                UNION ALL
                -- Additional "synthetic" edges from vertices to out of bounds
                SELECT
                    c.component as plot,
                    (r.idy, r.idx) as inside,
                    unnest([
                        if(r.idy = 1, (0, r.idx), NULL),
                        if(r.idy = getvariable('height'), (getvariable('height') + 1, r.idx), NULL),
                        if(r.idx = 1, (r.idy, 0), NULL),
                        if(r.idx = getvariable('width'), (r.idy, getvariable('width') + 1), NULL),
                    ]) as outside,
                FROM components c
                JOIN region r ON r.id = c.id
                WHERE (r.idy = 1 OR r.idy = getvariable('height') OR
                       r.idx = 1 OR r.idx = getvariable('width'))
            )
            WHERE outside IS NOT NULL
        ),
        crossings AS (
            -- Horizontal Crossings
            FROM (
                -- For each plot: all border points in horizontal lines
                SELECT
                    plot,
                    outside[1] as idy,
                    unnest([inside[2], outside[2]]) as idx,
                    unnest(['in', 'out']) as side,
                    dir,
                FROM borders
                WHERE inside[1] = outside[1]
            )
            -- Walk line from left to right, when entering plot keep outside x,
            -- when exiting plot keep inside x. Consecutive points belong to the same side.
            QUALIFY row_number() OVER (PARTITION BY plot, idy ORDER BY idx) % 2 = 1
            UNION ALL
            -- Same as horizontal_crossings but with flipped axes
            FROM (
                SELECT
                    plot,
                    unnest([inside[1], outside[1]]) as idy,
                    outside[2] as idx,
                    unnest(['in', 'out']) as side,
                    dir,
                FROM borders
                WHERE inside[2] = outside[2]
            )
            QUALIFY row_number() OVER (PARTITION BY plot, idx ORDER BY idy) % 2 = 1
        ),
        sides AS (
            -- Mark first of consecutive points as start of a new side
            SELECT
                plot, dir, idx, idy,
                -- If delta is NULL, it's the first crossing of the line -> mark as start
                -- If delta is greater 1, there's a gap between this and the previous crossing -> mark as start
                if(delta = 1, NULL, true) as side_start,
            FROM (
                SELECT
                    plot, dir, idx, idy,
                    if(dir = 'h', idy, idx) as d1, -- When horizontal track dy, otherwhise dx
                    if(dir = 'h', idx, idy) as d2, -- When horizontal group by dx, otherwhise dy
                    -- Adding in-/outside to partition prevents sides bleeding into another
                    d1 - lag(d1) OVER (PARTITION BY plot, dir, d2, side ORDER BY d1) as delta,
                FROM crossings
            )
        ),
        plots AS (
            SELECT
                plot,
                any_value(plant) as plant,
                any_value(area) as area,
                count() as perimeter,
                count(s.side_start) as sides,
            FROM (
                SELECT
                    component as plot,
                    any_value(r.plant) as plant,
                    count() as area,
                FROM components c
                JOIN region r ON c.id = r.id
                GROUP BY c.component
            ) p
            JOIN sides s USING (plot)
            GROUP BY plot
        )

    SELECT
        plot, plant, area, perimeter, sides,
        area * perimeter as score1,
        area * sides as score2,
    FROM plots
);

CREATE OR REPLACE TABLE results AS (
    WITH
        single_plants AS (
            SELECT singles * 4 as score FROM (
                SELECT count() - (SELECT sum(area) FROM plots) as singles
                FROM region
            )
        )

    SELECT
        sum(score1) + (SELECT score FROM single_plants) as part1,
        sum(score2) + (SELECT score FROM single_plants) as part2,
    FROM plots
);


CREATE OR REPLACE VIEW solution AS (
    SELECT 
        'Part 1' as part,
        part1 as result,
        if(getvariable('mode') = 'example', getvariable('exampleSolution1'), getvariable('solution1')) as expected,
        result = expected as correct
    FROM results
    UNION
    SELECT 
        'Part 2' as part,
        part2 as result,
        if(getvariable('mode') = 'example', getvariable('exampleSolution2'), getvariable('solution2')) as expected,
        result = expected as correct
    FROM results
    ORDER BY part
);
FROM solution;

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