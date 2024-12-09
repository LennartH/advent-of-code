SET VARIABLE example = '
    2333133121414131402
';
--                                             0
--     2-3--3--3--13--3--12-14---14---13--14---2-
-- IN: 00...111...2...333.44.5555.6666.777.888899
-- P1: 0099811188827773336446555566..............
-- P2: 00992111777.44.333....5555.6666.....8888..

-- -- Move to larger space
-- SET VARIABLE example = '
--     13412
-- ';
-- --      13--4---12-
-- -- IN:  0...1111.22
-- -- P1:  0221111....
-- -- P2:  022.1111...

-- -- Multiple moves in same space
-- SET VARIABLE example = '
--     151211111111612
-- ';
-- --      15----12-111111116-----12-
-- -- IN:  0.....1..2.3.4.5.666666.77
-- -- P1:  07766616626345............
-- -- P2:  07754312.........666666...

-- -- Multiple moves in same space, but evil
-- SET VARIABLE example = '
--     15121111211111612
-- ';
-- --     15----12-11112-111116-----12-
-- -- IN: 0.....1..2.3.44.5.6.777777.88
-- -- P1: 0887771772736445.............
-- -- P2: 0886531442..........777777...

CREATE OR REPLACE VIEW example AS SELECT regexp_split_to_table(trim(getvariable('example'), E'\n '), '\n\s*') as line;
SET VARIABLE exampleSolution1 = 1928;
SET VARIABLE exampleSolution2 = 2858;

CREATE OR REPLACE TABLE input AS
SELECT regexp_split_to_table(trim(content, E'\n '), '\n') as line FROM read_text('input');
SET VARIABLE solution1 = 6435922584968;
SET VARIABLE solution2 = NULL;

SET VARIABLE mode = 'input'; -- example or input

CREATE OR REPLACE TABLE disk_map AS (
    SELECT
        generate_subscripts(sizes, 1) as pos,
        unnest(sizes) as size,
    FROM (
        SELECT
            cast(regexp_split_to_array(line, '') as INTEGER[]) as sizes
        FROM query_table(getvariable('mode'))
    )
);

CREATE OR REPLACE TABLE chunks AS (
    SELECT
        pos,
        (row_number() OVER () - 1) as id,
        size,
    FROM disk_map
    WHERE pos % 2 = 1
    UNION ALL
    SELECT
        pos,
        NULL as id,
        size,
    FROM disk_map
    WHERE pos % 2 = 0
    -- delete me
    -- ORDER BY pos
);

CREATE OR REPLACE TABLE blocks AS (
    SELECT
        pos,
        row_number() OVER (ORDER BY pos) - 1 as block,
        id,
    FROM (
        SELECT
            pos,
            unnest(list_resize([]::INTEGER[], size, id)) as id,
        FROM chunks
    )
    -- delete me
    -- ORDER BY pos, block
);

CREATE OR REPLACE TABLE fragmented_blocks AS (
WITH
    file_blocks AS (
        FROM blocks
        WHERE id NOT NULL
        ORDER BY block desc
    ),
    empty_blocks AS (
        FROM blocks
        WHERE id IS NULL
        ORDER BY block
    )
SELECT
    f.pos,
    if(e.block < f.block, e.block, f.block) as block,
    f.id,
FROM file_blocks f
POSITIONAL JOIN empty_blocks e
-- delete me
-- ORDER BY block
);


CREATE OR REPLACE MACRO used_size(history, pos) AS 
coalesce(
    list_sum(
        list_transform(
            list_filter(history, x -> x.pos = pos),
            x -> x.size
        )
    ),
    0
);
CREATE OR REPLACE TABLE defragmented_chunks AS (
WITH RECURSIVE
    file_chunks AS MATERIALIZED (FROM chunks WHERE id NOT NULL ORDER BY pos desc),
    empty_chunks AS MATERIALIZED (FROM chunks WHERE id IS NULL ORDER BY pos),
    stepper AS MATERIALIZED (
        SELECT
            (SELECT max(id) FROM file_chunks) as cursor,
            NULL as id,
            NULL as from_pos,
            NULL as to_pos,
            NULL as chunk_size,
            -- NULL as empty_size,
            []::STRUCT(pos INTEGER, size INTEGER)[] as history,
        UNION ALL
        FROM (
            SELECT
                cursor - 1 as cursor,
                c.id as id,
                c.pos as from_pos,
                e.pos as to_pos,
                c.size as chunk_size,
                -- e.size as empty_size,
                if(
                    e.pos NOT NULL,
                    list_append(s.history, (e.pos::INTEGER, c.size)),
                    s.history
                ) as history,
            FROM stepper s
            JOIN file_chunks c ON c.id = cursor
            LEFT JOIN empty_chunks e ON e.pos < c.pos AND e.size >= c.size + used_size(history, e.pos)
            LIMIT 1
        ) s
    ),
    moved_chunks AS (
        SELECT
            coalesce(to_pos, from_pos) as pos,
            cursor,
            id,
            chunk_size as size,
        FROM stepper
        WHERE from_pos NOT NULL
        UNION ALL
        SELECT
            from_pos as pos,
            cursor,
            NULL as id,
            chunk_size as size
        FROM stepper
        WHERE to_pos NOT NULL
    ),
    merged_chunks AS (
        SELECT
            *
        FROM moved_chunks
        UNION ALL
        SELECT
            pos,
            NULL as cursor,
            id,
            size
        FROM empty_chunks
    ),
    defragmented_chunks AS (
        SELECT
            pos, cursor, id,
            size - if(id NOT NULL, 0, coalesce(total_size, 0)) as size,
        FROM (
            SELECT
                *,
                sum(size) OVER (PARTITION BY pos ORDER BY cursor desc ROWS UNBOUNDED PRECEDING EXCLUDE CURRENT ROW) as total_size,
            FROM merged_chunks
        ) c
    )

FROM defragmented_chunks
WHERE size != 0
-- delete me
-- ORDER BY pos, cursor desc
);

CREATE OR REPLACE TABLE defragmented_blocks AS (
    SELECT
        pos,
        row_number() OVER (ORDER BY pos, cursor desc) - 1 as block,
        id,
    FROM (
        SELECT
            pos,
            cursor,
            unnest(list_resize([]::INTEGER[], size, id)) as id,
        FROM defragmented_chunks
    )
    -- delete me
    -- ORDER BY pos, block
);


-- WITH
--     empty_chunks AS (FROM chunks WHERE id IS NULL ORDER BY pos),
--     stepper AS (FROM defragmented),
--     moved_chunks AS (
--         SELECT
--             coalesce(to_pos, from_pos) as pos,
--             cursor,
--             id,
--             chunk_size as size,
--         FROM stepper
--         UNION ALL
--         SELECT
--             from_pos as pos,
--             cursor,
--             NULL as id,
--             chunk_size as size
--         FROM stepper
--         WHERE to_pos NOT NULL
--     ),
--     merged_chunks AS (
--         SELECT
--             *
--         FROM moved_chunks
--         UNION ALL
--         SELECT
--             pos,
--             NULL as cursor,
--             id,
--             size
--         FROM empty_chunks
--     ),
--     defragmented_chunks AS (
--         SELECT
--             pos, cursor, id,
--             size - if(id NOT NULL, 0, coalesce(total_size, 0)) as size,
--         FROM (
--             SELECT
--                 *,
--                 sum(size) OVER (PARTITION BY pos ORDER BY cursor desc ROWS UNBOUNDED PRECEDING EXCLUDE CURRENT ROW) as total_size,
--             FROM merged_chunks
--         ) c
--     )

-- FROM defragmented_chunks
-- -- delete me
-- ORDER BY pos, cursor desc
-- ;


-- CREATE OR REPLACE VIEW merge_chunks AS (
-- WITH
--     after_move AS (
--         FROM (
--             SELECT
--                 unnest([
--                     {'pos': to_pos, 'frag': 0, 'id': id, 'size': chunk_size, 'from_pos': from_pos},
--                     if(
--                         chunk_size = empty_size, NULL,
--                         {'pos': to_pos, 'frag': 1, 'id': NULL, 'size': empty_size - chunk_size, 'from_pos': NULL}
--                     ),
--                     {'pos': from_pos, 'frag': 0, 'id': NULL, 'size': chunk_size, 'from_pos': to_pos}
--                 ], recursive := true)
--             FROM defragmented
--             WHERE to_pos NOT NULL
--         )
--         WHERE size NOT NULL
--     ),
--     defrag_chunks AS (
--         SELECT
--             pos,
--             frag,
--             if(m.pos, m.id, c.id) as id,
--             coalesce(m.size, c.size) as size,
--             from_pos,
--         FROM after_move m
--         RIGHT JOIN chunks c USING (pos)
--         ORDER BY pos, frag
--     ),
--     file_chunks AS (
--         SELECT DISTINCT ON (id) *
--         FROM defrag_chunks
--         WHERE id NOT NULL
--         ORDER BY pos, frag
--     )

-- FROM file_chunks
-- UNION ALL
-- FROM defrag_chunks WHERE id IS NULL
-- -- delete me
-- ORDER BY pos, frag
-- );





-- CREATE OR REPLACE VIEW defragmented AS (
-- WITH RECURSIVE
--     file_chunks AS MATERIALIZED (FROM chunks WHERE id NOT NULL ORDER BY pos desc),
--     empty_chunks AS MATERIALIZED (FROM chunks WHERE id IS NULL),
--     defragmented AS (
--         SELECT
--             0 as step,
--             id,
--             pos as from_pos,
--             NULL as to_pos,
--             size as chunk_size,
--             NULL as empty_size,
--         FROM file_chunks
--         UNION ALL
--         FROM (
--             SELECT
--                 step + 1 as step,
--                 c.id,
--                 from_pos as from_pos,
--                 e.pos as to_pos,
--                 chunk_size,
--                 e.size as empty_size,
--             FROM defragmented c
--             JOIN empty_chunks e ON e.pos < c.from_pos AND e.size >= c.chunk_size
--             WHERE from_pos >= 19 - (step * 2)
--             -- LIMIT 1
--         )
--         WHERE step < 3
--     )
-- FROM defragmented
-- -- delete me
-- ORDER BY step, to_pos, from_pos desc
-- );


-- CREATE OR REPLACE VIEW moves AS (
-- WITH
--     file_chunks AS (
--         SELECT
--             *,
--             row_number() OVER (ORDER BY id desc NULLS LAST) as prio,
--         FROM chunks
--         WHERE id NOT NULL
--     ),
--     empty_chunks AS (FROM chunks WHERE id IS NULL),
--     possible_moves AS (
--         SELECT
--             c.id,
--             c.pos as from_pos,
--             e.pos as to_pos,
--             c.size as chunk_size,
--             e.size as empty_size,
--             prio,
--         FROM file_chunks c
--         JOIN empty_chunks e ON e.pos < c.pos AND e.size >= c.size
--     )
-- FROM possible_moves
-- );

-- SELECT
--     *,
--     sum(chunk_size) OVER (PARTITION BY to_pos ORDER BY chunk_size, prio) as fill,
--     -- row_number() OVER (PARTITION BY from_pos ORDER BY prio) as rank2,
--     -- row_number() OVER (PARTITION BY from_pos ORDER BY from_pos desc) as prio,
--     fill <= empty_size as move,

-- from moves
-- order by to_pos, from_pos desc
-- -- order by from_pos desc, to_pos
-- ;


-- CREATE OR REPLACE VIEW defragmented AS (
-- WITH
--     file_chunks AS (FROM chunks WHERE id NOT NULL),
--     empty_chunks AS (FROM chunks WHERE id IS NULL),
--     possible_moves AS (
--         SELECT
--             c.id,
--             c.pos as from_pos,
--             e.pos as to_pos,
--             c.size as chunk_size,
--             e.size as empty_size,
--         FROM file_chunks c
--         JOIN empty_chunks e ON e.pos < c.pos AND e.size >= c.size
--     ),
--     ranked_moves AS (
--         SELECT
--             *,
--             row_number() OVER (PARTITION BY from_pos ORDER BY from_pos desc) as rank,
--             row_number() OVER (PARTITION BY to_pos ORDER BY from_pos desc) as prio,
--         FROM possible_moves
--     ),
--     moves AS (FROM ranked_moves WHERE rank = prio),
--     after_move AS (
--         FROM (SELECT
--             unnest([
--                 {'pos': to_pos, 'frag': 0, 'id': id, 'size': chunk_size, 'from_pos': from_pos},
--                 if(
--                     chunk_size = empty_size, NULL,
--                     {'pos': to_pos, 'frag': 1, 'id': NULL, 'size': empty_size - chunk_size, 'from_pos': NULL}
--                 ),
--                 {'pos': from_pos, 'frag': 0, 'id': NULL, 'size': chunk_size, 'from_pos': to_pos}
--             ], recursive := true)
--         FROM moves)
--         WHERE size NOT NULL
--     )

-- FROM after_move
-- -- delete me
-- ORDER BY pos, frag
-- );




CREATE OR REPLACE VIEW solution AS (
    SELECT
        (SELECT sum(block * id) FROM fragmented_blocks) as part1,
        (SELECT sum(block * id) FROM defragmented_blocks) as part2
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
FROM solution;

-- region Troubleshooting Utils
PREPARE print_blocks AS
SELECT string_agg(blocks, '' ORDER BY pos) as blocks FROM (
SELECT
    pos,
    repeat(coalesce(id::VARCHAR, '.'), size) as blocks
FROM query_table(?)
-- FROM mawp
ORDER BY pos);
-- endregion
