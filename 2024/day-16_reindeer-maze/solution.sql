SET VARIABLE example = '
    ###############
    #.......#....E#
    #.#.###.#.###.#
    #.....#.#...#.#
    #.###.#####.#.#
    #.#.#.......#.#
    #.#.#####.###.#
    #...........#.#
    ###.#.#####.#.#
    #...#.....#.#.#
    #.#.#.###.#.#.#
    #.....#...#.#.#
    #.###.#.#.#.#.#
    #S..#.....#...#
    ###############
';
SET VARIABLE exampleSolution1 = 7036;
SET VARIABLE exampleSolution2 = NULL;

-- SET VARIABLE example = '
--     #################
--     #...#...#...#..E#
--     #.#.#.#.#.#.#.#.#
--     #.#.#.#...#...#.#
--     #.#.#.#.###.#.#.#
--     #...#.#.#.....#.#
--     #.#.#.#.#.#####.#
--     #.#...#.#.#.....#
--     #.#.#####.#.###.#
--     #.#.#.......#...#
--     #.#.###.#####.###
--     #.#.#...#.....#.#
--     #.#.#.#####.###.#
--     #.#.#.........#.#
--     #.#.#.#########.#
--     #S#.............#
--     #################
-- ';
-- SET VARIABLE exampleSolution1 = 11048;
-- SET VARIABLE exampleSolution2 = NULL;

CREATE OR REPLACE VIEW example AS SELECT regexp_split_to_table(trim(getvariable('example'), chr(10) || ' '), '\n\s*') as line;

CREATE OR REPLACE TABLE input AS
SELECT regexp_split_to_table(trim(content, chr(10) || ' '), '\n') as line FROM read_text('input');
SET VARIABLE solution1 = NULL;
SET VARIABLE solution2 = NULL;

SET VARIABLE mode = 'example';
-- SET VARIABLE mode = 'input';

CREATE OR REPLACE VIEW map AS (
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

-- CREATE OR REPLACE TABLE directions AS (
--     FROM (VALUES 
--         ('^',  0, -1),
--         ('>',  1,  0),
--         ('v',  0,  1),
--         ('<', -1,  0)
--     ) directions(dir, dx, dy)
-- );


-- CREATE OR REPLACE VIEW pathfinder AS (
--     WITH RECURSIVE
--         pathfinder AS (
--             SELECT
--                 id,
--                 x,
--                 y,
--                 1 as dx,
--                 0 as dy,
--                 0 as cost,
--                 [] as visited,
--             FROM map
--             WHERE symbol = 'S'
--             UNION ALL
--             FROM (
--                 SELECT
--                     m.id as id,
--                     m.x as x,
--                     m.y as y,
--                     m.x - p.x as dx,
--                     m.y - p.y as dy,
--                     p.cost + if(
--                         m.x = p.x + p.dx AND m.y = p.y + p.dy,
--                         1,
--                         1001
--                     ) as cost,
--                     list_prepend(p.id, p.visited) as visited,
--                 FROM pathfinder p, map m
--                 WHERE m.symbol = '.'
--                 AND abs(m.x - p.x) + abs(m.y - p.y) = 1
--                 AND m.id NOT IN p.visited
--                 ORDER BY cost desc
--                 LIMIT 100
--             )
--         )

--     SELECT p.x, p.y, cost
--     FROM pathfinder p
--     JOIN map m ON m.symbol = 'E' AND abs(m.x - p.x) + abs(m.y - p.y) = 1
-- );



DROP TYPE IF EXISTS STATE;
CREATE TYPE STATE AS STRUCT(cost BIGINT, id INTEGER, x INTEGER, y INTEGER, dx INTEGER, dy INTEGER, path INTEGER[]);

CREATE OR REPLACE VIEW pathfinder AS (
    WITH RECURSIVE
        pathfinder AS (
            SELECT
                0 as it,
                [{'cost': 0, 'id': m.id, 'x': x, 'y': y, 'dx': 1, 'dy': 0, 'path': []::INTEGER[]}]::STATE[] as stack,
            FROM map m
            WHERE symbol = 'S'
            UNION ALL (
                WITH
                    reachable AS (
                        SELECT
                            m.id as id,
                            m.x as x,
                            m.y as y,
                            m.x - p.stack[1].x as dx,
                            m.y - p.stack[1].y as dy,
                            p.stack[1].cost + if(
                                m.x = p.stack[1].x + p.stack[1].dx AND m.y = p.stack[1].y + p.stack[1].dy,
                                1,
                                1001
                            ) as cost,
                            list_prepend(p.stack[1].id, p.stack[1].path) as path,
                            m.symbol = 'E' as terminate,
                        FROM pathfinder p
                        JOIN map m ON m.symbol IN ('.', 'E') AND
                                      -- cardinal directions without diagonals
                                      abs(m.x - p.stack[1].x) + abs(m.y - p.stack[1].y) = 1 AND
                                      m.id NOT IN p.stack[1].path
                    ),
                    reachable_agg AS (
                        SELECT
                            list({'cost': cost, 'id': id, 'x': x, 'y': y, 'dx': dx, 'dy': dy, 'path': path}) as agg
                        FROM reachable
                    ),
                    pushpop AS (
                        SELECT
                            x.it + 1 as it,
                            x.stack as stack,
                        FROM reachable_agg _(r), LATERAL (
                            SELECT
                                p.it,
                                r || p.stack[2:] as stack,
                            FROM pathfinder p
                            WHERE len(r) > 0
                            UNION ALL
                            SELECT
                                p.it,
                                p.stack[2:] as stack,
                            FROM pathfinder p
                            WHERE len(r) IS NULL AND len(p.stack) > 0
                        ) x
                        WHERE NOT EXISTS (FROM reachable WHERE terminate)
                    ),
                    explode AS (
                        SELECT it, unnest(stack) as state FROM pushpop
                    ),
                    compact AS (
                        SELECT DISTINCT ON (state.cost, state.id, state.dx, state.dy) *
                        FROM explode
                    )

                SELECT
                    any_value(it) as it,
                    list(state ORDER BY state.cost DESC) as stack,
                FROM compact
                WHERE it < 10
            )
        )

    -- SELECT 
    --     it,
    --     stack[1].y || ',' || stack[1].x || '|' || stack[1].cost as state,
    --     [e.y || ',' || e.x || '|' || e.cost FOR e IN stack[2:]] as stack,
    --     v.path as path,
    -- FROM pathfinder p, (
    --     SELECT
    --         list('(' || m.y || ',' || m.x || ')' ORDER BY v.idx) as path,
    --     FROM (
    --         SELECT
    --             generate_subscripts(p.stack[1].path, 1) as idx,
    --             unnest(p.stack[1].path) as id,
    --     ) v
    --     JOIN map m USING (id)
    -- ) v
    -- ORDER BY it
    -- ;

    SELECT
        it,
        unnest(p.stack[1]),
        m.id IS NOT NULL as final,
    FROM pathfinder p
    LEFT JOIN map m ON m.symbol = 'E' AND abs(m.x - p.stack[1].x) + abs(m.y - p.stack[1].y) = 1
);


-- WITH
--     pathfinder AS (
--         SELECT
--             [{'x': x, 'y': y, 'dx': dx, 'dy': dy, 'cost': 0}]::STATE[] as stack,
--             []::STRUCT(x INTEGER, y INTEGER)[] as visited,
--         FROM map m
--         JOIN directions d ON d.dir = m.symbol
--         WHERE symbol = '>'
--     ),
--     reachable AS (
--         SELECT
--             m.x as x, m.y as y,
--             m.x - p.stack[1].x as dx,
--             m.y - p.stack[1].y as dy,
--             p.stack[1].cost + if(
--                 m.x = p.stack[1].x + p.stack[1].dx AND
--                 m.y = p.stack[1].y + p.stack[1].dy,
--                 1,
--                 1000
--             ) as cost,
--         FROM pathfinder p
--         -- TODO handle reaching goal
--         JOIN map m ON m.symbol = '.'
--                         -- cardinal directions without diagonals
--                         AND abs(m.x - p.stack[1].x) + abs(m.y - p.stack[1].y) = 1
--                         AND (m.x, m.y) NOT IN p.visited
--     ),
--     reachable_agg AS (
--         SELECT
--             list({'x': x, 'y': y, 'dx': dx, 'dy': dy, 'cost': cost} ORDER BY cost) as agg
--         FROM reachable
--     ),

--     pathfinderr AS (
--         SELECT x.*
--         FROM reachable_agg _(r), LATERAL (
--             SELECT
--                 r || p.stack[2:] as stack,
--                 list_prepend((p.stack[1].x, p.stack[1].y), p.visited) as visited,
--             FROM pathfinder p
--             WHERE len(r) > 0
--             UNION ALL
--             SELECT
--                 p.stack[2:] as stack,
--                 p.visited as visited,
--             FROM pathfinder p
--             WHERE len(r) IS NULL AND len(p.stack) > 0
--         ) x
--     ),
--     reachablee AS (
--         SELECT
--             m.x as x, m.y as y,
--             m.x - p.stack[1].x as dx,
--             m.y - p.stack[1].y as dy,
--             p.stack[1].cost + if(
--                 m.x = p.stack[1].x + p.stack[1].dx AND
--                 m.y = p.stack[1].y + p.stack[1].dy,
--                 1,
--                 1000
--             ) as cost,
--         FROM pathfinderr p
--         -- TODO handle reaching goal
--         JOIN map m ON m.symbol = '.'
--                         -- cardinal directions without diagonals
--                         AND abs(m.x - p.stack[1].x) + abs(m.y - p.stack[1].y) = 1
--                         AND (m.x, m.y) NOT IN p.visited
--     ),
--     reachable_aggg AS (
--         SELECT
--             list({'x': x, 'y': y, 'dx': dx, 'dy': dy, 'cost': cost} ORDER BY cost) as agg
--         FROM reachablee
--     ),

--     pathfinderrr AS (
--         SELECT x.*
--         FROM reachable_agg _(r), LATERAL (
--             SELECT
--                 r || p.stack[2:] as stack,
--                 list_prepend((p.stack[1].x, p.stack[1].y), p.visited) as visited,
--             FROM pathfinderr p
--             WHERE len(r) > 0
--             UNION ALL
--             SELECT
--                 p.stack[2:] as stack,
--                 p.visited as visited,
--             FROM pathfinderr p
--             WHERE len(r) IS NULL AND len(p.stack) > 0
--         ) x
--     )

-- FROM pathfinderrr
-- ;



CREATE OR REPLACE VIEW results AS (
    SELECT
        (SELECT min(cost) + 1 FROM pathfinder WHERE final) as part1,
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
                unnest(list_prepend(p.id, p.path[:-2])) as id,
                'o' as symbol,
            FROM pathfinder p
            WHERE p.it = step
        )

    SELECT
        y,
        string_agg(coalesce(p.symbol, m.symbol), ' ' ORDER BY x) as line,
    FROM map m
    LEFT JOIN path p USING (id)
    GROUP BY y
    ORDER BY y
);
-- endregion
