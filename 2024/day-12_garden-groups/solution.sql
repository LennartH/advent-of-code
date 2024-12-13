-- SET VARIABLE example = '
--     AAAA
--     BBCD
--     BBCC
--     EEEC
-- ';
-- SET VARIABLE exampleSolution1 = 140;

-- SET VARIABLE example = '
--     OOOOO
--     OXOXO
--     OOOOO
--     OXOXO
--     OOOOO
-- ';
-- SET VARIABLE exampleSolution1 = 772;

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
    SELECT
        row_number() OVER () as idy,
        unnest(generate_series(1, len(line))) as idx,
        unnest(regexp_split_to_array(line, '')) as plant,
    FROM query_table(getvariable('mode'))
);


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
                list_sort([(r1.idy, r1.idx), (r2.idy, r2.idx)])::STRUCT(x BIGINT, y BIGINT)[] as plot,
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