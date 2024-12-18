-- SET VARIABLE example = '
--     ###############
--     #.......#....E#
--     #.#.###.#.###.#
--     #.....#.#...#.#
--     #.###.#####.#.#
--     #.#.#.......#.#
--     #.#.#####.###.#
--     #...........#.#
--     ###.#.#####.#.#
--     #...#.....#.#.#
--     #.#.#.###.#.#.#
--     #.....#...#.#.#
--     #.###.#.#.#.#.#
--     #S..#.....#...#
--     ###############
-- ';
-- SET VARIABLE exampleSolution1 = 7036;
-- SET VARIABLE exampleSolution2 = NULL;

SET VARIABLE example = '
    #################
    #...#...#...#..E#
    #.#.#.#.#.#.#.#.#
    #.#.#.#...#...#.#
    #.#.#.#.###.#.#.#
    #...#.#.#.....#.#
    #.#.#.#.#.#####.#
    #.#...#.#.#.....#
    #.#.#####.#.###.#
    #.#.#.......#...#
    #.#.###.#####.###
    #.#.#...#.....#.#
    #.#.#.#####.###.#
    #.#.#.........#.#
    #.#.#.#########.#
    #S#.............#
    #################
';
SET VARIABLE exampleSolution1 = 11048;
SET VARIABLE exampleSolution2 = NULL;

-- SET VARIABLE example = '
--     #############
--     #####......E#
--     ####..#.#####
--     ###..##.#####
--     ##..###.#####
--     #..####.....#
--     #.#########.#
--     #...........#
--     #S###########
--     #############
-- ';
-- SET VARIABLE exampleSolution1 = 6025;

CREATE OR REPLACE VIEW example AS SELECT regexp_split_to_table(trim(getvariable('example'), chr(10) || ' '), '\n\s*') as line;

CREATE OR REPLACE TABLE input AS
SELECT regexp_split_to_table(trim(content, chr(10) || ' '), '\n') as line FROM read_text('input');
SET VARIABLE solution1 = 104516;
SET VARIABLE solution2 = NULL;

-- SET VARIABLE mode = 'example';
SET VARIABLE mode = 'input';

CREATE OR REPLACE TABLE map AS (
    SELECT
        row_number() OVER () as id,
        *
    FROM (
        SELECT
            y::INTEGER as y,
            generate_subscripts(symbols, 1)::INTEGER as x,
            unnest(symbols) as symbol,
        FROM (
            SELECT
                row_number() OVER () as y,
                regexp_split_to_array(line, '') as symbols,
            FROM query_table(getvariable('mode'))
        )
    )
);

CREATE OR REPLACE TABLE pathfinder AS (
    WITH RECURSIVE
        pathfinder AS (
            SELECT
                0 as it,
                id,
                x,
                y,
                1 as dx,
                0 as dy,
                0 as cost,
                [] as path,
                [] as path_costs,
                false as end_reached,
            FROM map
            WHERE symbol = 'S'
            UNION ALL (
                WITH
                    paths AS (
                        FROM (
                            SELECT
                                p.it + 1 as it,
                                m.id as id,
                                m.x as x,
                                m.y as y,
                                m.x - p.x as dx,
                                m.y - p.y as dy,
                                p.cost + if(
                                    m.x = p.x + p.dx AND m.y = p.y + p.dy,
                                    1,
                                    1001
                                ) as cost,
                                list_prepend(p.id, p.path) as path,
                                list_prepend(p.cost, p.path_costs) as path_costs,
                                m.symbol = 'E' as end_reached,
                            FROM pathfinder p, map m
                            WHERE m.symbol IN ('.', 'E')
                              AND abs(m.x - p.x) + abs(m.y - p.y) = 1
                        ) p
                        WHERE NOT EXISTS (FROM pathfinder pp WHERE pp.path_costs[list_position(pp.path, p.id)] < p.cost OR (pp.end_reached AND pp.cost < p.cost))
                        -- WHERE NOT EXISTS (FROM pathfinder pp WHERE pp.path_costs[list_position(pp.path, p.id)] < p.cost)
                        --   AND NOT EXISTS (FROM pathfinder pp WHERE pp.end_reached AND pp.cost < p.cost)
                    )

                SELECT * EXCLUDE (rank)
                FROM (
                    SELECT 
                        p.*,
                        -- This results in fewer records than just PARTITION BY id. I have no idea why
                        row_number() OVER (PARTITION BY id, dx, dy ORDER BY cost) as rank
                        -- row_number() OVER (PARTITION BY id ORDER BY cost) as rank
                    FROM paths p
                )
                WHERE rank = 1
            )
        )
    SELECT
        it,
        p.id,
        p.y,
        p.x,
        cost,
        dx,
        dy,
        p.end_reached as final,
        path,
    FROM pathfinder p
    WHERE final
);

CREATE OR REPLACE TABLE results AS (
    SELECT
        (SELECT min(cost) FROM pathfinder WHERE final) as part1,
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

-- region Troubleshooting Utils
CREATE OR REPLACE MACRO print_map() AS TABLE (
    SELECT
        y,
        string_agg(symbol, ' ' ORDER BY x) as line,
    FROM map
    GROUP BY y
    ORDER BY y
);

CREATE OR REPLACE MACRO print_path(step) AS TABLE (
    WITH
        path AS (
            SELECT
                id,
                min(symbol) as symbol,
            FROM (
                SELECT
                    unnest(list_prepend(p.id, p.path)) as id,
                    if(p.final, '+', 'o') as symbol,
                FROM pathfinder p
                WHERE p.it = step
            )
            GROUP BY id
        )

    SELECT
        y,
        string_agg(coalesce(nullif(m.symbol, '.'), p.symbol, m.symbol), ' ' ORDER BY x) as line,
    FROM map m
    LEFT JOIN path p USING (id)
    GROUP BY y
    ORDER BY y
);
-- endregion
