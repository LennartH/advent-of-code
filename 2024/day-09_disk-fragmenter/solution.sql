SET VARIABLE example = '
    2333133121414131402
';
CREATE OR REPLACE VIEW example AS SELECT regexp_split_to_table(trim(getvariable('example'), E'\n '), '\n\s*') as line;
SET VARIABLE exampleSolution1 = 1928;
SET VARIABLE exampleSolution2 = NULL;

CREATE OR REPLACE TABLE input AS
SELECT regexp_split_to_table(trim(content, E'\n '), '\n') as line FROM read_text('input');
SET VARIABLE solution1 = 6435922584968;
SET VARIABLE solution2 = NULL;

SET VARIABLE mode = 'input'; -- example or input

CREATE OR REPLACE VIEW disk_map AS (
    SELECT
        generate_subscripts(sizes, 1) as pos,
        unnest(sizes) as size,
    FROM (
        SELECT
            cast(regexp_split_to_array(line, '') as INTEGER[]) as sizes
        FROM query_table(getvariable('mode'))
    )
);

CREATE OR REPLACE VIEW blocks AS (
    SELECT
        pos,
        row_number() OVER (ORDER BY pos) - 1 as block,
        id,
    FROM (
        SELECT
            pos,
            unnest(list_resize(
                []::INTEGER[], size, 
                (row_number() OVER () - 1)::INTEGER
            )) as id,
        FROM disk_map
        WHERE pos % 2 = 1
        UNION ALL
        SELECT
            pos,
            unnest(list_resize(
                []::INTEGER[], size, 
                NULL
            )) as id,
        FROM disk_map
        WHERE pos % 2 = 0
    )
);

CREATE OR REPLACE VIEW fragmented AS (
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

CREATE OR REPLACE VIEW solution AS (
    SELECT
        (SELECT sum(block * id) FROM fragmented) as part1,
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
FROM solution;