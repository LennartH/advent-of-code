SET VARIABLE example = '
    ########
    #..O.O.#
    ##@.O..#
    #...O..#
    #.#.O..#
    #...O..#
    #......#
    ########

    <^^>>>vv<v>>v<<
';
SET VARIABLE exampleSolution1 = 2028;
SET VARIABLE exampleSolution2 = NULL;

SET VARIABLE example = '
    ##########
    #..O..O.O#
    #......O.#
    #.OO..O.O#
    #..O@..O.#
    #O#..O...#
    #O..O..O.#
    #.OO.O.OO#
    #....O...#
    ##########

    <vv>^<v^>v>^vv^v>v<>v^v<v<^vv<<<^><<><>>v<vvv<>^v^>^<<<><<v<<<v^vv^v>^
    vvv<<^>^v^^><<>>><>^<<><^vv^^<>vvv<>><^^v>^>vv<>v<<<<v<^v>^<^^>>>^<v<v
    ><>vv>v^v^<>><>>>><^^>vv>v<^^^>>v^v^<^^>v^^>v^<^v>v<>>v^v^<v>v^^<^^vv<
    <<v<^>>^^^^>>>v^<>vvv^><v<<<>^^^vv^<vvv>^>v<^^^^v<>^>vvvv><>>v^<<^^^^^
    ^><^><>>><>^^<<^^v>>><^<v>^<vv>>v>>>^v><>^v><<<<v>>v<v<v>vvv>^<><<>^><
    ^>><>^v<><^vvv<^^<><v<<<<<><^v<<<><<<^^<v<^^^><^>>^<v^><<<^>>^v<v^v<v^
    >^>>^v>vv>^<<^v<>><<><<v<<v><>v<^vv<<<>^^v^>^^>>><<^v>>v^v><^^>>^<>vv^
    <><^^>^^^<><vvvvv^v<v<<>^v<v>v<<^><<><<><<<^^<<<^<<>><<><^^^>^^<>^>v<>
    ^^>vv<^v^v<vv>^<><v<^v>^^^>>>^^vvv^>vvv<>>>^<^>>>>>^<<^v>^vvv<>^<><<v>
    v^^>>><<^^<>>^v^<v^vv<>v^<<>^<^v^v><^<<<><<^<v><v<>vv>>v><v^<vv<>v^<<^
';
SET VARIABLE exampleSolution1 = 10092;
SET VARIABLE exampleSolution2 = 9021;

CREATE OR REPLACE VIEW example AS SELECT trim(getvariable('example'), chr(10) || ' ') as text;

CREATE OR REPLACE TABLE input AS
SELECT trim(content, chr(10) || ' ') as text FROM read_text('input');
SET VARIABLE solution1 = 1465152;
SET VARIABLE solution2 = 1511259;

-- SET VARIABLE mode = 'example';
SET VARIABLE mode = 'input';

CREATE OR REPLACE VIEW input_parts AS (
    SELECT 
        trim(parts[1], e'\n ') as warehouse,
        trim(parts[2], e'\n ') as moves,
    FROM (
        SELECT
            string_split("text", e'\n\n') as parts,
        FROM query_table(getvariable('mode'))
    )
);

CREATE OR REPLACE TABLE warehouse AS (
    WITH
        lines AS (
            SELECT regexp_split_to_table(warehouse, '\n\s*') as line
            FROM input_parts
        )

    SELECT
        idy - 1 as idy,
        generate_subscripts(objects, 1) - 1 as idx,
        unnest(objects) as object,
    FROM (
        SELECT
            row_number() OVER () as idy,
            string_split(line, '') as objects
        FROM lines
    )
);

CREATE OR REPLACE TABLE moves AS (
    SELECT
        generate_subscripts(moves, 1) as idm,
        unnest(moves) as dir,
    FROM (
        SELECT string_split(replace(moves, e'\s', ''), '') as moves
        FROM input_parts
    )
);

CREATE OR REPLACE TABLE directions AS (
    FROM (VALUES 
        ('^',  0, -1),
        ('>',  1,  0),
        ('v',  0,  1),
        ('<', -1,  0)
    ) directions(dir, dx, dy)
);

CREATE OR REPLACE TABLE updated_warehouse AS (
    WITH RECURSIVE
        updated_warehouse AS (
            SELECT
                0 as idm,
                idy,
                idx,
                object,
            FROM warehouse
            UNION ALL (
                WITH
                    robot AS (
                        SELECT
                            w.idy, w.idx,
                            m.dir,
                            d.dy, d.dx,
                            w.idy + d.dy as next_y,
                            w.idx + d.dx as next_x,
                        FROM updated_warehouse w
                        JOIN moves m ON m.idm = w.idm + 1
                        JOIN directions d USING (dir)
                        WHERE w.object = '@'
                    ),
                    moved_objects AS (
                        -- Empty Space
                        SELECT
                            unnest(['@', '.']) as object,
                            unnest([r.next_y, r.idy]) as idy,
                            unnest([r.next_x, r.idx]) as idx,
                        FROM robot r
                        JOIN updated_warehouse e ON e.object = '.' AND e.idy = r.next_y AND e.idx = r.next_x
                        UNION ALL
                        -- Pushable Box
                        SELECT
                            unnest(['@', '.', 'O']) as object,
                            unnest([r.next_y, r.idy, ab.idy]) as idy,
                            unnest([r.next_x, r.idx, ab.idx]) as idx,
                        FROM robot r, (
                            FROM updated_warehouse ab -- after box
                            WHERE ab.object != 'O' AND CASE WHEN r.dx = 0
                                -- TODO Can check for same column/row be expressed mathematically?
                                THEN ab.idx = r.idx AND ab.idy * r.dy > r.idy * r.dy
                                ELSE ab.idy = r.idy AND ab.idx * r.dx > r.idx * r.dx
                            END
                            ORDER BY abs(ab.idx - r.idx) + abs(ab.idy - r.idy)
                            LIMIT 1
                        ) ab
                        JOIN updated_warehouse b ON b.object = 'O' AND b.idy = r.next_y AND b.idx = r.next_x
                        WHERE ab.object = '.' -- The closest space after a row of boxes must be free
                        
                        -- Moving towards a wall or a box that can't be pushed does nothing
                        -- which is the same as having no moved objects
                    )

                SELECT
                    idm + 1 as idm,
                    idy,
                    idx,
                    coalesce(o.object, w.object)
                FROM updated_warehouse w
                LEFT JOIN moved_objects o USING (idy, idx)
                WHERE idm < (SELECT count() FROM moves)
            )
        )

    FROM updated_warehouse
    WHERE idm = (SELECT count() FROM moves)
);

CREATE OR REPLACE TABLE scaled_warehouse AS (
    WITH
        scaled_parts AS (
            SELECT
                replace(warehouse, '#', '##') as walls,
                replace(walls, 'O', '[]') as boxes,
                replace(boxes, '.', '..') as floors,
                replace(floors, '@', '@.') as scaled,
            FROM input_parts
        ),
        lines AS (
            SELECT regexp_split_to_table(scaled, '\n\s*') as line
            FROM scaled_parts
        )

    SELECT
        idy - 1 as idy,
        generate_subscripts(objects, 1) - 1 as idx,
        unnest(objects) as object,
    FROM (
        SELECT
            row_number() OVER () as idy,
            string_split(line, '') as objects
        FROM lines
    )
);

CREATE OR REPLACE TABLE updated_scaled_warehouse AS (
    WITH RECURSIVE
        updated_warehouse AS (
            SELECT
                0 as idm,
                idy,
                idx,
                object,
            FROM scaled_warehouse
            UNION ALL (
                WITH RECURSIVE
                    robot AS (
                        SELECT
                            w.idy, w.idx,
                            m.dir,
                            d.dy, d.dx,
                            w.idy + d.dy as next_y,
                            w.idx + d.dx as next_x,
                        FROM updated_warehouse w
                        JOIN moves m ON m.idm = w.idm + 1
                        JOIN directions d USING (dir)
                        WHERE w.object = '@'
                    ),
                    vertical_boxes AS (
                        SELECT
                            '@' as object,
                            r.idy,
                            r.idx,
                            r.dy,
                        FROM robot r
                        WHERE r.dx = 0
                        UNION ALL
                        SELECT
                            bb.object,
                            bb.idy,
                            bb.idx,
                            v.dy,
                        FROM vertical_boxes v
                        JOIN updated_warehouse b ON b.object IN ('[', ']', '#') AND b.idy = v.idy + v.dy AND b.idx = v.idx
                        JOIN updated_warehouse bb ON (bb.object = ']' AND bb.idy = b.idy AND bb.idx = b.idx + 1) OR
                                                     (bb.object = '[' AND bb.idy = b.idy AND bb.idx = b.idx - 1) OR
                                                     (bb.idy = b.idy AND bb.idx = b.idx)
                        -- Break after first encountered wall
                        WHERE NOT EXISTS (FROM vertical_boxes WHERE "object" = '#')
                    ),
                    movable_vertical_boxes AS (
                        -- Drop all records if no box or any wall was encountered
                        FROM vertical_boxes
                        WHERE EXISTS (FROM vertical_boxes v WHERE v.object IN ('[', ']')) AND
                              NOT EXISTS (FROM vertical_boxes v WHERE "object" = '#')
                    ),
                    moved_objects AS (
                        -- Empty Space
                        SELECT
                            unnest(['@', '.']) as object,
                            unnest([r.next_y, r.idy]) as idy,
                            unnest([r.next_x, r.idx]) as idx,
                        FROM robot r
                        JOIN updated_warehouse e ON e.object = '.' AND e.idy = r.next_y AND e.idx = r.next_x
                        UNION ALL
                        -- Movable Box (Horizontal)
                        SELECT
                            bb.object as object,
                            bb.idy as idy,
                            if(bb.object = '.', r.idx, bb.idx + r.dx) as idx,
                        FROM robot r, (
                            FROM updated_warehouse ab -- after box
                            WHERE ab.object NOT IN ('[', ']') AND
                                  ab.idy = r.idy AND ab.idx * r.dx > r.idx * r.dx
                            ORDER BY abs(ab.idx - r.idx)
                            LIMIT 1
                        ) ab
                        JOIN updated_warehouse b ON b.object IN ('[', ']') AND b.idy = r.next_y AND b.idx = r.next_x
                        JOIN updated_warehouse bb ON bb.idy = r.idy AND bb.idx * r.dx BETWEEN r.idx * r.dx AND ab.idx * r.dx 
                        WHERE r.dy = 0 AND ab.object = '.'
                        UNION ALL
                        -- Movable Box (Vertical)
                        SELECT
                            last(object ORDER BY object) as object,
                            idy,
                            idx,
                        FROM (
                            SELECT
                                unnest([v.object, '.']) as object,
                                unnest([v.idy + v.dy, v.idy]) as idy,
                                v.idx as idx,
                            FROM movable_vertical_boxes v
                        )
                        GROUP BY idy, idx
                    )

                SELECT
                    idm + 1 as idm,
                    idy,
                    idx,
                    coalesce(o.object, w.object)
                FROM updated_warehouse w
                LEFT JOIN moved_objects o USING (idy, idx)
                WHERE idm < (SELECT count() FROM moves)
            )
        )

    FROM updated_warehouse
    WHERE idm = (SELECT count() FROM moves)
);

CREATE OR REPLACE VIEW results AS (
    WITH
        boxes AS (
            SELECT 
                idy, idx,
                idy * 100 + idx as gps,
            FROM updated_warehouse
            WHERE idm = (SELECT count() FROM moves) AND object = 'O'
        ),
        scaled_boxes AS (
            SELECT 
                idy, idx,
                idy * 100 + idx as gps,
                object,
            FROM updated_scaled_warehouse
            WHERE idm = (SELECT count() FROM moves) AND object = '['
        )

    SELECT
        (SELECT sum(gps) FROM boxes) as part1,
        (SELECT sum(gps) FROM scaled_boxes) as part2,
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
CREATE OR REPLACE MACRO print_move(idm) AS TABLE (
    SELECT
        NULL as idy,
        'Move: ' || dir as line,
    FROM moves m
    WHERE m.idm = idm
    UNION ALL
    SELECT
        idy,
        string_agg(object, ' ' ORDER BY idx) as line,
    FROM updated_warehouse w
    WHERE w.idm = idm
    GROUP BY idy
    ORDER BY idy NULLS FIRST
);

CREATE OR REPLACE MACRO print_scaled_move(idm) AS TABLE (
    SELECT
        NULL as idy,
        'Move: ' || dir as line,
    FROM moves m
    WHERE m.idm = idm
    UNION ALL
    SELECT
        idy,
        string_agg(object, '' ORDER BY idx) as line,
    FROM updated_scaled_warehouse w
    WHERE w.idm = idm
    GROUP BY idy
    ORDER BY idy NULLS FIRST
);
-- endregion