SET VARIABLE example = '
    2333133121414131402
';
--                                             0
--     2-3--3--3--13--3--12-14---14---13--14---2-
-- IN: 00...111...2...333.44.5555.6666.777.888899
-- P1: 0099811188827773336446555566..............
-- P2: 00992111777.44.333....5555.6666.....8888..
SET VARIABLE exampleSolution1 = 1928;
SET VARIABLE exampleSolution2 = 2858;

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

CREATE OR REPLACE TABLE input AS
FROM read_text('input') SELECT regexp_split_to_table(trim(content, E'\n '), '\n\s*') as line;
SET VARIABLE solution1 = 6435922584968;
SET VARIABLE solution2 = 6469636832766;

.maxrows 75
SET VARIABLE mode = 'example';
-- SET VARIABLE mode = 'input';

CREATE OR REPLACE VIEW disk_map AS (
    FROM (
        FROM query_table(getvariable('mode'))
        SELECT sizes: string_split(line, '')::INTEGER[],
    )
    SELECT
        chunk_id: generate_subscripts(sizes, 1),
            size: unnest(sizes),
);

CREATE OR REPLACE VIEW chunks AS (
    FROM disk_map
    SELECT
        chunk_id,
            size,
        is_empty: chunk_id % 2 = 0,
         file_id: if(is_empty, NULL, row_number() OVER (PARTITION BY is_empty ORDER BY chunk_id ASC) - 1),
    -- ORDER BY
    --     chunk_id ASC
);

CREATE OR REPLACE VIEW blocks AS (
    FROM          c: chunks
    CROSS JOIN dups: generate_series(1, c.size)
    SELECT
        c.chunk_id,
        c.is_empty,
         c.file_id,
          block_id: dups.generate_series,
    -- ORDER BY
    --     chunk_id,
    --     block_id
);

CREATE OR REPLACE VIEW fragmented_blocks AS (
    WITH
        file_blocks AS (
            FROM blocks WHERE NOT is_empty ORDER BY chunk_id DESC, block_id DESC
        ),
        empty_blocks AS (
            FROM blocks WHERE is_empty ORDER BY chunk_id ASC, block_id ASC
        )

    FROM            f: file_blocks
    POSITIONAL JOIN e: empty_blocks
    SELECT
        -- FIXME: block_id should be continous to make "folding" into empty blocks easier
        *
        ;
        
);

-- Do stuff

CREATE OR REPLACE VIEW results AS (
    SELECT
        -- part1: (FROM fragmented_blocks SELECT sum(block * file_id)),
        part1: NULL,
        -- part2: (FROM defragmented_blocks SELECT sum(block * file_id)),
        part2: NULL
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
