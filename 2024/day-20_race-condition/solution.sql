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
-- number of cheats saving at least 50 picoseconds
SET VARIABLE exampleSolution1 = 1;
SET VARIABLE exampleSolution2 = 285;

CREATE OR REPLACE TABLE input AS
SELECT regexp_split_to_table(trim(content, chr(10) || ' '), '\n') as line FROM read_text('input');
-- number of cheats saving at least 100 picoseconds
SET VARIABLE solution1 = 1426;
SET VARIABLE solution2 = 1000697;

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
        if(getvariable('mode') = 'example', 50, 100) as cheat_threshold,
        2 as part1_cheat_duration,
        20 as part2_cheat_duration,
);

-- -- Stepwise pathfinder: 9-10 seconds
-- CREATE OR REPLACE TABLE default_path AS (
--     WITH RECURSIVE
--         default_path AS (
--             SELECT
--                 0 as steps,
--                 p.default_path_length as distance,
--                 t.id as id,
--                 t.y as y,
--                 t.x as x,
--                 -1 as prev_id,
--             FROM racetrack t, parameters p
--             WHERE t.symbol = 'S'
--             UNION ALL
--             SELECT
--                 p.steps + 1 as steps,
--                 p.distance - 1 as distance,
--                 t.id as id,
--                 t.y as y,
--                 t.x as x,
--                 p.id as prev_id,
--             FROM default_path p, racetrack t
--             WHERE t.symbol IN ('.', 'E') AND
--                   abs(t.y - p.y) + abs(t.x - p.x) = 1 AND
--                   t.id != p.prev_id
--         )

--     SELECT
--         id,
--         y,
--         x,
--         steps,
--         distance,
--     FROM default_path
-- );

-- Raywalking pathfinder: 6-7 seconds
CREATE OR REPLACE TABLE default_path AS (
    WITH RECURSIVE
        default_path AS (
            SELECT
                0 as it,
                t.y as y,
                t.x as x,
                NULL as prev_y,
                NULL as prev_x,
                2 as dy,
                2 as dx,
            FROM racetrack t
            WHERE t.symbol = 'S'
            UNION ALL (
                WITH
                    direction AS (
                        SELECT p.y, p.x, d.dy, d.dx
                        FROM default_path p, (
                            SELECT
                                t.y - p.y as dy,
                                t.x - p.x as dx,
                            FROM default_path p, racetrack t
                            WHERE t.symbol IN ('.', 'E') AND abs(t.y - p.y) + abs(t.x - p.x) = 1
                        ) d
                        WHERE p.dx != -d.dx AND p.dy != -d.dy
                    ),
                    closest_wall AS (
                        SELECT w.y, w.x, d.dy, d.dx
                        FROM direction d, racetrack w
                            -- in line with current direction (either x-x/y-y is 0 or dy/dx is 0)
                        WHERE w.symbol = '#' AND (w.y - d.y) * d.dx + (w.x - d.x) * d.dy = 0 AND
                            -- is after current position in current direction
                            (w.y * d.dy > d.y * d.dy OR w.x * d.dx > d.x * d.dx)
                        ORDER BY abs(w.y - d.y) + abs(w.x - d.x)
                        LIMIT 1
                    )

                SELECT
                    p.it + 1 as it,
                    t.y as y,
                    t.x as x,
                    p.y as prev_y,
                    p.x as prev_x,
                    w.dy as dy,
                    w.dx as dx,
                FROM default_path p, closest_wall w, racetrack t
                WHERE t.y = w.y - w.dy AND t.x = w.x - w.dx
            )
        )

    SELECT
        t.id,
        y,
        x,
        row_number() OVER (ORDER BY it, pos) - 1 as steps,
    FROM (
        SELECT
            it,
            unnest(range(0, abs(prev_y - y) + abs(prev_x - x))) as pos,
            if(dx = 0, unnest(range(prev_y, y, dy)), y) as y,
            if(dy = 0, unnest(range(prev_x, x, dx)), x) as x,
        FROM default_path
    )
    JOIN racetrack t USING (y, x)
    UNION ALL
    SELECT
        id,
        y,
        x,
        default_path_length,
    FROM racetrack, parameters
    WHERE symbol = 'E'
);

CREATE OR REPLACE TABLE part1_cheats AS (
    WITH
        cheats AS (
            SELECT
                t1, t2,
                max(shortcut) as shortcut,
            FROM (
                SELECT
                    if(t1.id < t2.id, t1.id, t2.id) as t1,
                    if(t1.id < t2.id, t2.id, t1.id) as t2,
                    abs(t1.y - t2.y) + abs(t1.x - t2.x) as duration,
                    abs(t1.steps - t2.steps) - duration as shortcut,
                FROM default_path t1, default_path t2, parameters p
                WHERE duration BETWEEN 2 AND p.part1_cheat_duration
                    AND shortcut >= p.cheat_threshold
            )
            GROUP BY t1, t2
        )

    SELECT
        shortcut,
        count() as count,
    FROM cheats
    GROUP BY shortcut
);

CREATE OR REPLACE TABLE part2_cheats AS (
    WITH
        cheats AS (
            SELECT
                t1, t2,
                max(shortcut) as shortcut,
            FROM (
                SELECT
                    if(t1.id < t2.id, t1.id, t2.id) as t1,
                    if(t1.id < t2.id, t2.id, t1.id) as t2,
                    abs(t1.y - t2.y) + abs(t1.x - t2.x) as duration,
                    abs(t1.steps - t2.steps) - duration as shortcut,
                FROM default_path t1, default_path t2, parameters p
                WHERE duration BETWEEN 2 AND p.part2_cheat_duration
                    AND shortcut >= p.cheat_threshold
            )
            GROUP BY t1, t2
        )

    SELECT
        shortcut,
        count() as count,
    FROM cheats
    GROUP BY shortcut
);

CREATE OR REPLACE VIEW results AS (
    SELECT
        (SELECT sum(count) FROM part1_cheats, parameters WHERE shortcut >= cheat_threshold) as part1,
        (SELECT sum(count) FROM part2_cheats, parameters WHERE shortcut >= cheat_threshold) as part2,
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
