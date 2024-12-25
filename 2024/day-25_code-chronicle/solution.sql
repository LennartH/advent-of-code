SET VARIABLE example = '
    #####
    .####
    .####
    .####
    .#.#.
    .#...
    .....

    #####
    ##.##
    .#.##
    ...##
    ...#.
    ...#.
    .....

    .....
    #....
    #....
    #...#
    #.#.#
    #.###
    #####

    .....
    .....
    #.#..
    ###..
    ###.#
    ###.#
    #####

    .....
    .....
    .....
    #....
    #.#..
    #.#.#
    #####
';
CREATE OR REPLACE VIEW example AS SELECT regexp_split_to_table(trim(getvariable('example'), chr(10) || ' '), '\n\n\s*') as line;
SET VARIABLE exampleSolution1 = 3;
SET VARIABLE exampleSolution2 = NULL;

CREATE OR REPLACE TABLE input AS
SELECT regexp_split_to_table(trim(content, chr(10) || ' '), '\n\n\s*') as line FROM read_text('input');
SET VARIABLE solution1 = 3395;
SET VARIABLE solution2 = NULL;

.maxrows 75
-- SET VARIABLE mode = 'example';
SET VARIABLE mode = 'input';

CREATE OR REPLACE VIEW schematics AS (
    SELECT
        id,
        y,
        unnest(range(0, len(line))) as x,
        unnest(string_split(line, '')) as symbol,
        kind,
    FROM (
        SELECT
            id,
            generate_subscripts(lines, 1) - 1 as y,
            trim(unnest(lines)) as line,
            if(lines[1] = '#####', 'lock', 'key') as kind,
        FROM (
            SELECT
                row_number() OVER () as id,
                string_split(line, chr(10)) as lines,
            FROM query_table(getvariable('mode'))
        )
    )
);

CREATE OR REPLACE VIEW schematic_heights AS (
    SELECT
        id,
        x,
        count() FILTER (symbol = '#') - 1 as height,
        any_value(kind) as kind,
    FROM schematics
    GROUP BY id, x
);


CREATE OR REPLACE VIEW key_lock_fits AS (
    WITH
        column_fits AS (
            SELECT 
                l.id as lock_id,
                k.id as key_id,
                l.x as x,
                l.height as lock_height,
                k.height as key_height,
                l.height + k.height as total_space,
                total_space < 6 as fits,
            FROM schematic_heights l
            JOIN schematic_heights k ON k.kind = 'key' AND l.x = k.x
            WHERE l.kind = 'lock'
        )
    FROM column_fits
);

CREATE OR REPLACE VIEW results AS (
    WITH
        fitting AS (
            SELECT 
                lock_id, key_id 
            FROM key_lock_fits 
            GROUP BY lock_id, key_id 
            HAVING bool_and(fits)
        )

    SELECT
        (SELECT count() FROM fitting) as part1,
        NULL as part2
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
