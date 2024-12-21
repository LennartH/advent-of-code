SET VARIABLE example = '
    ###############
    #...#...#.....#
    #.#.#.#.#.###.#
    #S#...#.#.#...#
    #######.#.#.###
    #######.#.#...#
    #######.#.###.#
    ###..E#...#...#
    ###.#######.###
    #...###...#...#
    #.#####.#.###.#
    #.#...#.#.#...#
    #.#.#.#.#.#.###
    #...#...#...###
    ###############
';
CREATE OR REPLACE VIEW example AS SELECT regexp_split_to_table(trim(getvariable('example'), chr(10) || ' '), '\n\s*') as line;
SET VARIABLE exampleSolution1 = 4;  -- number of cheats saving at least 30 picoseconds
SET VARIABLE exampleSolution2 = NULL;

CREATE OR REPLACE TABLE input AS
SELECT regexp_split_to_table(trim(content, chr(10) || ' '), '\n') as line FROM read_text('input');
SET VARIABLE solution1 = 1426;
SET VARIABLE solution2 = NULL;

-- SET VARIABLE mode = 'example';
SET VARIABLE mode = 'input';

CREATE OR REPLACE TABLE racetrack AS (
    SELECT
        y,
        generate_subscripts(tiles, 1) as x,
        unnest(tiles) as symbol,
        (y - 1) * len(tiles) + x as id,
    FROM (
        SELECT
            row_number() OVER () as y,
            regexp_split_to_array(line, '') as tiles,
        FROM query_table(getvariable('mode'))
    )
);

CREATE OR REPLACE TABLE parameters AS (
    SELECT
        (SELECT count() + 1 FROM racetrack WHERE symbol = '.') as default_path_length,
        if(getvariable('mode') = 'example', 30, 100) as cheat_threshold,
);

-- FIXME This takes ~10 seconds for real input
CREATE OR REPLACE TABLE default_path AS (
    WITH RECURSIVE
        default_path AS (
            SELECT
                0 as steps,
                p.default_path_length as distance,
                t.id as id,
                t.y as y,
                t.x as x,
                -1 as prev_id,
            FROM racetrack t, parameters p
            WHERE t.symbol = 'S'
            UNION ALL
            SELECT
                p.steps + 1 as steps,
                p.distance - 1 as distance,
                t.id as id,
                t.y as y,
                t.x as x,
                p.id as prev_id,
            FROM default_path p, racetrack t
            WHERE t.symbol IN ('.', 'E') AND
                  abs(t.y - p.y) + abs(t.x - p.x) = 1 AND
                  t.id != p.prev_id
        )

    SELECT
        id,
        steps,
        distance,
    FROM default_path
);

CREATE OR REPLACE TABLE tunnable_walls AS (
    WITH
        tunnable_walls AS (
            -- Walls with 2 walkable tiles on opposite sides
            SELECT DISTINCT ON (w.id)
                w.*,
                t1.id as t1,
                t2.id as t2,
            FROM racetrack w, racetrack t1, racetrack t2
            WHERE w.symbol = '#' AND 
                  t1.symbol != '#' AND abs(t1.y - w.y) + abs(t1.x - w.x) = 1 AND
                  t2.symbol != '#' AND abs(t2.y - w.y) + abs(t2.x - w.x) = 1 AND
                  (t1.y = t2.y OR t1.x = t2.x) AND t1.id != t2.id
        )

    SELECT
        w.*,
        abs(t1.steps - t2.steps) - 2 as shortcut,
    FROM tunnable_walls w
    JOIN default_path t1 ON t1.id = w.t1
    JOIN default_path t2 ON t2.id = w.t2
);

CREATE OR REPLACE VIEW results AS (
    WITH
        cheats_over_threshold AS (
            SELECT
                count() as count,
            FROM tunnable_walls, parameters
            WHERE shortcut >= cheat_threshold
            GROUP BY shortcut
        )

    SELECT
        (SELECT sum(count) FROM cheats_over_threshold) as part1,
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
