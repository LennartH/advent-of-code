SET VARIABLE example = '
    125 17
';
CREATE OR REPLACE VIEW example AS SELECT regexp_split_to_table(trim(getvariable('example'), chr(10) || ' '), '\n\s*') as line;
SET VARIABLE exampleSolution1 = 55312;
SET VARIABLE exampleSolution2 = NULL;

CREATE OR REPLACE TABLE input AS
SELECT regexp_split_to_table(trim(content, chr(10) || ' '), '\n') as line FROM read_text('input');
SET VARIABLE solution1 = 224529;
SET VARIABLE solution2 = NULL;

SET VARIABLE mode = 'example';
-- SET VARIABLE mode = 'input';

CREATE OR REPLACE VIEW pebbles AS (
    SELECT
        unnest(generate_series(1, len(values))) as idx,
        unnest(values) as value,
    FROM (
        SELECT
            cast(regexp_split_to_array(line, ' ') as BIGINT[]) as values
        FROM query_table(getvariable('mode'))
    )
);

CREATE OR REPLACE TABLE blink_seed AS (
    FROM (VALUES
        (1::BIGINT, 1, [2024]::BIGINT[], false),
        (1, 2, [20, 24], false),
        (1, 3, [2, 0, 2, 4], true),
        (2, 1, [4048], false),
        (2, 2, [40, 48], false),
        (2, 3, [4, 0, 4, 8], true),
        (3, 1, [6072], false),
        (3, 2, [60, 72], false),
        (3, 3, [6, 0, 7, 2], true),
        (4, 1, [8096], false),
        (4, 2, [80, 96], false),
        (4, 3, [8, 0, 9, 6], true),
        (5, 1, [10120], false),
        (5, 2, [20482880], false),
        (5, 3, [2048, 2880], false),
        (5, 4, [20, 48, 28, 80], false),
        (5, 5, [2, 0, 4, 8, 2, 8, 8, 0], true),
        (6, 1, [12144], false),
        (6, 2, [24579456], false),
        (6, 3, [2457, 9456], false),
        (6, 4, [24, 57, 94, 56], false),
        (6, 5, [2, 4, 5, 7, 9, 4, 5, 6], true),
        (7, 1, [14168], false),
        (7, 2, [28676032], false),
        (7, 3, [2867, 6032], false),
        (7, 4, [28, 67, 60, 32], false),
        (7, 5, [2, 8, 6, 7, 6, 0, 3, 2], true),
        (8, 1, [16192], false),
        (8, 2, [32772608], false),
        (8, 3, [3277, 2608], false),
        (8, 4, [32, 77, 26, 8], false),
        (8, 5, [3, 2, 7, 7, 2, 6, 16192], true),
        (9, 1, [18216], false),
        (9, 2, [36869184], false),
        (9, 3, [3686, 9184], false),
        (9, 4, [36, 86, 91, 84], false),
        (9, 5, [3, 6, 8, 6, 9, 1, 8, 4], true)
    ) c(value, blinks, pebbles, last)
);

-- CREATE OR REPLACE TABLE blink_cache AS (
--     WITH RECURSIVE
--         blinks AS (
--             SELECT
--                 -- unnest([1, 2, 3, 4, 5, 6, 7, 8, 9]) as origin,
--                 -- 1 as blink,
--                 -- unnest([1, 2, 3, 4, 5, 6, 7, 8, 9]) * 2024 as value
--                 0 as origin,
--                 1 as blink,
--                 0 as old,
--                 1 as value
--             UNION ALL
--             SELECT
--                 origin,
--                 -- b.blink + coalesce(c.blinks, 1) as blink,
--                 b.blink + 1 as blink,
--                 b.value as old,
--                 unnest(CASE
--                     -- WHEN c.value IS NOT NULL THEN c.pebbles
--                     WHEN b.value = 0 THEN [1]
--                     WHEN len(b.value::varchar) % 2 = 0 THEN [
--                         left(b.value::varchar, len(b.value::varchar) // 2)::BIGINT,
--                         right(b.value::varchar, len(b.value::varchar) // 2)::BIGINT
--                     ]
--                     ELSE [b.value * 2024]
--                 END) as value,
--             FROM blinks b
--             -- LEFT JOIN blink_seed c ON b.value = c.value AND (b.blink + c.blinks = 30 OR (b.blink + c.blinks < 30 AND c.last))
--             WHERE blink < 50
--         )
--     FROM blinks
--     ORDER BY origin, blink
--     ;

--     SELECT
--         origin as value,
--         blink as blinks,
--         list(value) as pebbles,
--         blink = 30 as last,
--     FROM blinks
--     -- delete me
--     GROUP BY origin, blink
--     ORDER BY origin, blink
-- );

CREATE OR REPLACE TABLE blink_edges AS (
    WITH RECURSIVE
        blinks AS (
            SELECT
                unnest([1, 2, 3, 4, 5, 6, 7, 8, 9]) as origin,
                1 as blink,
                unnest([1, 2, 3, 4, 5, 6, 7, 8, 9]) as old,
                unnest([1, 2, 3, 4, 5, 6, 7, 8, 9]) * 2024 as value,
            UNION ALL
            SELECT
                b.origin,
                b.blink + 1 as blink,
                b.value as old,
                unnest(CASE
                    WHEN b.value = 0 THEN [1]
                    WHEN len(b.value::varchar) % 2 = 0 THEN [
                        left(b.value::varchar, len(b.value::varchar) // 2)::BIGINT,
                        right(b.value::varchar, len(b.value::varchar) // 2)::BIGINT
                    ]
                    ELSE [b.value * 2024]
                END) as value,
            FROM blinks b
            WHERE b.value > 10
        )

    SELECT
        origin as node1,
        blink as weight,
        value as node2,
    FROM blinks
    WHERE value < 10
    -- delete me
    ORDER BY node1, node2
);



WITH RECURSIVE
    paths AS (
        SELECT
            node1 as start_node,
            node2 as end_node,
            [node1, node2] as path,
            weight as cost,
        FROM blink_edges
        WHERE start_node = 4
        UNION ALL
        SELECT
            p.start_node as start_node,
            e.node2 as end_node,
            list_append(p.path, e.node2) as path,
            p.cost + e.weight as cost
        FROM paths p
        JOIN blink_edges e ON p.end_node = e.node1
        -- WHERE p.end_node != 4 AND p.cost + e.weight < 25
        -- WHERE list_position(p.path, e.node2) IS NULL
        WHERE NOT EXISTS (
            FROM paths pp WHERE list_contains(pp.path, e.node2)
        )
    )

    FROM paths
    ORDER BY len(path), path
;




CREATE OR REPLACE VIEW blinks AS (
    WITH RECURSIVE
        blinks AS (
            SELECT
                p.idx,
                0 as blink,
                p.value,
            FROM pebbles p
            UNION ALL
            SELECT
                b.idx,
                b.blink + coalesce(c.blinks, 1) as blink,
                unnest(CASE
                    WHEN c.value IS NOT NULL THEN c.pebbles
                    WHEN b.value = 0 THEN [1]
                    WHEN len(b.value::varchar) % 2 = 0 THEN [
                        left(b.value::varchar, len(b.value::varchar) // 2)::BIGINT,
                        right(b.value::varchar, len(b.value::varchar) // 2)::BIGINT
                    ]
                    ELSE [b.value * 2024]
                END) as value,
            FROM blinks b
            -- LEFT JOIN blink_cache c ON b.value = c.value AND (b.blink + c.blinks = 75 OR (b.blink + c.blinks < 75 AND c.last))
            -- WHERE b.blink < 75
            LEFT JOIN blink_cache c ON b.value = c.value AND (b.blink + c.blinks = 50 OR (b.blink + c.blinks < 50 AND c.last))
            WHERE b.blink < 50
            -- LEFT JOIN blink_cache c ON b.value = c.value AND (b.blink + c.blinks = 25 OR (b.blink + c.blinks < 25 AND c.last))
            -- WHERE b.blink < 25
            -- LEFT JOIN blink_cache c ON b.value = c.value AND (b.blink + c.blinks = 10 OR (b.blink + c.blinks < 10 AND c.last))
            -- WHERE b.blink < 10
        )
    FROM blinks
);

SELECT count() FROM blinks WHERE blink = 50;

CREATE OR REPLACE VIEW solution AS (
    SELECT
        (SELECT count() FROM blinks WHERE blink = 25) as part1,
        (SELECT count() FROM blinks WHERE blink = 75) as part2
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
PREPARE print_blinks AS
SELECT
    blink,
    string_agg(value, ' ') as pebbles,
FROM blinks
WHERE $1 IS NULL OR $1 = 0 OR blink <= $1
GROUP BY blink
ORDER BY blink;
-- endregion