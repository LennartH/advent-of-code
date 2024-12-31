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
-- SET VARIABLE exampleSolution1 = 595;
-- SET VARIABLE exampleSolution2 = 1106;

CREATE OR REPLACE VIEW example AS SELECT regexp_split_to_table(trim(getvariable('example'), E'\n '), '\n\s*') as line;
SET VARIABLE exampleSolution1 = 1928;
SET VARIABLE exampleSolution2 = 2858;

CREATE OR REPLACE TABLE input AS
SELECT regexp_split_to_table(trim(content, E'\n '), '\n') as line FROM read_text('input');
SET VARIABLE solution1 = 6435922584968;
SET VARIABLE solution2 = 6469636832766;

-- SET VARIABLE mode = 'example';
SET VARIABLE mode = 'input';

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
POSITIONAL JOIN empty_blocks e);

-- TODO use priority queue by file size: look for reddit post
-- TODO iterate over gaps with free space instead of the next file
CREATE OR REPLACE MACRO add_size(history, pos, size) AS 
CASE
    WHEN map_contains(history, pos) THEN
        map_from_entries(
            list_transform(
                map_entries(history),
                x -> if(x.key != pos, x, {'key': x.key, 'value': x.value + size})
            )
        )
    ELSE
        map_from_entries(list_append(
            map_entries(history),
            {'key': pos, 'value': size}
        ))
END;
CREATE OR REPLACE MACRO used_size(history, pos) AS coalesce(history[pos][1], 0);
CREATE OR REPLACE TABLE defragmented_chunks AS (
WITH RECURSIVE
    file_chunks AS (FROM chunks WHERE id NOT NULL),
    empty_chunks AS (FROM chunks WHERE id IS NULL),
    file_stepper AS (
        SELECT
            (SELECT max(id) FROM file_chunks) as cursor,
            NULL as id,
            NULL as from_pos,
            NULL as to_pos,
            NULL as chunk_size,
            map()::MAP(BIGINT, INTEGER) as history,
        UNION ALL
        FROM (
            SELECT
                cursor - 1 as cursor,
                c.id as id,
                c.pos as from_pos,
                e.pos as to_pos,
                c.size as chunk_size,
                if(e.pos IS NULL, history, add_size(history, e.pos, c.size)) as history
            FROM file_stepper s
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
        FROM file_stepper
        WHERE from_pos NOT NULL
        UNION ALL
        SELECT
            from_pos as pos,
            cursor,
            NULL as id,
            chunk_size as size
        FROM file_stepper
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
WHERE size != 0);

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
);

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
FROM solution
ORDER BY part;

-- region Troubleshooting Utils
PREPARE print_blocks AS
SELECT string_agg(blocks, '' ORDER BY pos) as blocks FROM (
SELECT
    pos,
    repeat(coalesce(id::VARCHAR, '.'), size) as blocks
FROM query_table(?)
ORDER BY pos);
-- endregion
