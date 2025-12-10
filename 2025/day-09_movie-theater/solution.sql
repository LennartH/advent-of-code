SET VARIABLE example = '
    7,1
    11,1
    11,7
    9,7
    9,5
    2,5
    2,3
    7,3
';
SET VARIABLE exampleSolution1 = 50;
SET VARIABLE exampleSolution2 = 24;
CREATE OR REPLACE VIEW example AS SELECT regexp_split_to_table(trim(getvariable('example'), E'\n '), '\n\s*') as line;

CREATE OR REPLACE TABLE input AS
FROM read_text('input') SELECT regexp_split_to_table(trim(content, E'\n '), '\n\s*') as line;
SET VARIABLE solution1 = 4750297200;
SET VARIABLE solution2 = NULL;  -- too high 4616521504

.maxrows 75
-- SET VARIABLE mode = 'example';
SET VARIABLE mode = 'input';

CREATE OR REPLACE TABLE red_tiles AS (
    FROM query_table(getvariable('mode'))
    SELECT
        id: row_number() OVER (),
         p: {'x': split_part(line, ',', 1)::BIGINT, 'y': split_part(line, ',', 2)::BIGINT},
);

CREATE OR REPLACE TABLE rectangles AS (
    FROM red_tiles t1
    JOIN red_tiles t2 ON t1.id < t2.id
    SELECT
        id1: t1.id,
        id2: t2.id,
        c1: t1.p,
        c2: {'x': t2.p.x, 'y': t1.p.y},
        c3: t2.p,
        c4: {'x': t1.p.x, 'y': t2.p.y},
        area: (abs(t1.p.x - t2.p.x) + 1) * (abs(t1.p.y - t2.p.y) + 1)
);

CREATE OR REPLACE TABLE polygon_edges AS (
    FROM red_tiles t1
    JOIN red_tiles t2 ON t1.id + 1 = t2.id
    SELECT
        id1: t1.id,
        id2: t2.id,
        p1: t1.p,
        p2: t2.p,
    UNION ALL
    FROM (FROM red_tiles WHERE id = (FROM red_tiles SELECT max(id))) t1,
         (FROM red_tiles WHERE id = 1) t2
    SELECT
        id1: t1.id,
        id2: t2.id,
        p1: t1.p,
        p2: t2.p,
);

    -- FROM rectangles r
    -- WHERE (FROM polygon_edges e SELECT count(*) WHERE r.c2.y BETWEEN least(e.p1.y, e.p2.y) AND greatest(e.p1.y, e.p2.y) AND r.c2.x >= greatest(e.p1.x, e.p2.x)) % 2 = 1
    --   AND (FROM polygon_edges e SELECT count(*) WHERE r.c4.y BETWEEN least(e.p1.y, e.p2.y) AND greatest(e.p1.y, e.p2.y) AND r.c4.x >= greatest(e.p1.x, e.p2.x)) % 2 = 1

CREATE OR REPLACE TABLE red_green_rectangles AS (
    WITH
        without_lines AS (
            FROM rectangles r
            WHERE r.c1.x != r.c3.x AND r.c1.y != r.c3.y
        ),
        edges AS MATERIALIZED (
            FROM polygon_edges
            SELECT
                id1, id2,
                p1, p2,
                low: {'x': least(p1.x, p2.x), 'y': least(p1.y, p2.y)},
                high: {'x': greatest(p1.x, p2.x), 'y': greatest(p1.y, p2.y)},
                horizontal: p1.y = p2.y,
                -- base: if(horizontal, p1.y, p1.x),
                -- low: if(horizontal, least(p1.x, p2.x), least(p1.y, p2.y)),
                -- high: if(horizontal, greatest(p1.x, p2.x), greatest(p1.y, p2.y)),
        ),
        corners_inside AS (
            FROM without_lines r
            WHERE -- c1 and c3 are inside polygon by definition
                ( -- checking c2
                    -- is corner
                    EXISTS (FROM red_tiles t WHERE r.c2 = t.p)
                    -- is on edge
                 OR EXISTS (FROM edges e WHERE r.c2.x BETWEEN e.low.x AND e.high.x AND r.c2.y BETWEEN e.low.y AND e.high.y)
                    -- satisfies even-odd rule
                 OR (FROM edges e SELECT count(*) WHERE r.c2.x > e.high.x AND r.c2.y BETWEEN e.low.y AND e.high.y) % 2 = 1
                )
                AND
                ( -- checking c4
                    -- is corner
                    EXISTS (FROM red_tiles t WHERE r.c4 = t.p)
                    -- is on edge
                 OR EXISTS (FROM edges e WHERE r.c4.x BETWEEN e.low.x AND e.high.x AND r.c4.y BETWEEN e.low.y AND e.high.y)
                    -- satisfies even-odd rule
                 OR (FROM edges e SELECT count(*) WHERE r.c4.x > e.high.x AND r.c4.y BETWEEN e.low.y AND e.high.y) % 2 = 1
                )
        ),
        with_bounds AS (
            FROM corners_inside r
            SELECT
                id1, id2, area,
                c1_to_c2: {
                    'low': {'x': least(c1.x, c2.x) + 1, 'y': c1.y},
                    'high': {'x': greatest(c1.x, c2.x) - 1, 'y': c1.y},
                },
                c2_to_c3: {
                    'low': {'x': c2.x, 'y': least(c2.y, c3.y) + 1},
                    'high': {'x': c2.x, 'y': greatest(c2.y, c3.y) - 1},
                },
                c3_to_c4: {
                    'low': {'x': least(c3.x, c4.x) + 1, 'y': c3.y},
                    'high': {'x': greatest(c3.x, c4.x) - 1, 'y': c3.y},
                },
                c4_to_c1: {
                    'low': {'x': c4.x, 'y': least(c4.y, c1.y) + 1},
                    'high': {'x': c4.x, 'y': greatest(c4.y, c1.y) - 1},
                },
        ),
        -- bounds_inside AS (
        --     FROM with_bounds r
        --     SELECT
        --         id1, id2, area
        --     -- rectangle bounds mustn't cross any edge with opposite orientation
        --     WHERE NOT EXISTS (FROM edges e WHERE NOT e.horizontal AND c1_to_c2.low.y BETWEEN e.low.y AND e.high.y AND e.low.x BETWEEN c1_to_c2.low.x AND c1_to_c2.high.x)
        --       AND NOT EXISTS (FROM edges e WHERE e.horizontal     AND c2_to_c3.low.x BETWEEN e.low.x AND e.high.x AND e.low.y BETWEEN c2_to_c3.low.y AND c2_to_c3.high.y)
        --       AND NOT EXISTS (FROM edges e WHERE NOT e.horizontal AND c3_to_c4.low.y BETWEEN e.low.y AND e.high.y AND e.low.x BETWEEN c3_to_c4.low.x AND c3_to_c4.high.x)
        --       AND NOT EXISTS (FROM edges e WHERE e.horizontal     AND c4_to_c1.low.x BETWEEN e.low.x AND e.high.x AND e.low.y BETWEEN c4_to_c1.low.y AND c4_to_c1.high.y)
        -- )
        bounds_inside AS (
            FROM with_bounds r
            SELECT
                id1, id2, area,
                c3_to_c4,
                c1_to_c2_inside: NOT EXISTS (FROM edges e WHERE e.id1 NOT IN (r.id1 - 1, r.id1 + 1, r.id2 - 1, r.id2 + 1) AND e.id2 NOT IN (r.id1 - 1, r.id1 + 1, r.id2 - 1, r.id2 + 1) AND NOT e.horizontal AND c1_to_c2.low.y BETWEEN e.low.y AND e.high.y AND e.low.x BETWEEN c1_to_c2.low.x AND c1_to_c2.high.x),
                c2_to_c3_inside: NOT EXISTS (FROM edges e WHERE e.id1 NOT IN (r.id1 - 1, r.id1 + 1, r.id2 - 1, r.id2 + 1) AND e.id2 NOT IN (r.id1 - 1, r.id1 + 1, r.id2 - 1, r.id2 + 1) AND e.horizontal     AND c2_to_c3.low.x BETWEEN e.low.x AND e.high.x AND e.low.y BETWEEN c2_to_c3.low.y AND c2_to_c3.high.y),
                c3_to_c4_inside: NOT EXISTS (FROM edges e WHERE e.id1 NOT IN (r.id1 - 1, r.id1 + 1, r.id2 - 1, r.id2 + 1) AND e.id2 NOT IN (r.id1 - 1, r.id1 + 1, r.id2 - 1, r.id2 + 1) AND NOT e.horizontal AND c3_to_c4.low.y BETWEEN e.low.y AND e.high.y AND e.low.x BETWEEN c3_to_c4.low.x AND c3_to_c4.high.x),
                c4_to_c1_inside: NOT EXISTS (FROM edges e WHERE e.id1 NOT IN (r.id1 - 1, r.id1 + 1, r.id2 - 1, r.id2 + 1) AND e.id2 NOT IN (r.id1 - 1, r.id1 + 1, r.id2 - 1, r.id2 + 1) AND e.horizontal     AND c4_to_c1.low.x BETWEEN e.low.x AND e.high.x AND e.low.y BETWEEN c4_to_c1.low.y AND c4_to_c1.high.y),
        )

        

    FROM bounds_inside
    -- ORDER BY area DESC
    -- ;

);

CREATE OR REPLACE VIEW results AS (
    SELECT
        part1: (FROM rectangles SELECT max(area)),
        part2: (FROM red_green_rectangles SELECT max(area)),
        -- part2: NULL,
);


CREATE OR REPLACE VIEW solution AS (
    FROM results
    SELECT 
            part: 'Part 1',
          result: part1,
        expected: if(getvariable('mode') = 'example', getvariable('exampleSolution1'), getvariable('solution1')),
         correct: result = expected,
    UNION
    FROM results
    SELECT 
            part: 'Part 2',
          result: part2,
        expected: if(getvariable('mode') = 'example', getvariable('exampleSolution2'), getvariable('solution2')),
         correct: result = expected,
    ORDER BY part
);
FROM solution;
