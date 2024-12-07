SET VARIABLE example = '
    ....#.....
    .........#
    ..........
    ..#.......
    .......#..
    ..........
    .#..^.....
    ........#.
    #.........
    ......#...
';
CREATE OR REPLACE TABLE example AS SELECT regexp_split_to_table(trim(getvariable('example'), E'\n '), '\n\s*') as line;
SET VARIABLE exampleSolution1 = 41;
SET VARIABLE exampleSolution2 = 6;

CREATE OR REPLACE TABLE input AS SELECT regexp_split_to_table(trim(content, E'\n '), '\n') as line FROM read_text('input');
SET VARIABLE solution1 = 4433;
SET VARIABLE solution2 = NULL;

SET VARIABLE mode = 'input';

CREATE OR REPLACE TABLE cells AS (
    SELECT 
        generate_subscripts(values, 1) as idx,
        idy,
        unnest(values) as value
    FROM (
        SELECT
            row_number() OVER () as idy,
            string_split(line, '') as values
        FROM query_table(getvariable('mode'))
    )
);

CREATE OR REPLACE TABLE directions AS (
    FROM (VALUES 
        ('^', '>', '<',  0, -1, NULL, 1),
        ('>', 'v', '^',  1,  0, (SELECT max(idx) FROM cells), NULL),
        ('v', '<', '>',  0,  1, NULL, (SELECT max(idy) FROM cells)),
        ('<', '^', 'v', -1,  0, 1, NULL)
    ) directions(dir, next, prev, dx, dy, edge_x, edge_y)
);

CREATE OR REPLACE TABLE moves AS (
WITH RECURSIVE
    moves AS (
        SELECT
            0 as idm,
            idx,
            idy,
            dir,
            NULL::INTEGER[] as steps,
            NULL::varchar as prev_dir,
            false as final,
        FROM cells
        JOIN directions d ON d.dir = value
        UNION ALL
        SELECT
            idm, idx, idy, dir,
            CASE WHEN dx = 0 
                THEN generate_series(prev_y, idy, dy)
                ELSE generate_series(prev_x, idx, dx)
            END as steps,
            prev_dir,
            final,
        FROM (
            SELECT
                idm + 1 as idm,
                c.idx - if(value = '#', d.dx, 0) as idx,
                c.idy - if(value = '#', d.dy, 0) as idy,
                if(value = '#', d.next, NULL) as dir,
                d.dir as prev_dir,
                v.idx as prev_x,
                v.idy as prev_y,
                d.dx,
                d.dy,
                value != '#' as final,
            FROM 
                moves v,
                (FROM directions d WHERE d.dir = v.dir) d,
                (
                    FROM cells c
                    WHERE 
                        (c.value = '#' OR c.idx = d.edge_x OR c.idy = d.edge_y) AND 
                        CASE WHEN d.dx = 0
                            THEN c.idx = v.idx AND c.idy * d.dy > v.idy * d.dy
                            ELSE c.idy = v.idy AND c.idx * d.dx > v.idx * d.dx
                        END
                    ORDER BY abs(c.idx - v.idx) + abs(c.idy - v.idy)
                    LIMIT 1
                ) c
        )
    )
SELECT * FROM moves);

CREATE OR REPLACE TABLE visited AS (
    SELECT
        idm,
        generate_subscripts(steps, 1) as ids,
        if(d.dx != 0, unnest(steps), idx) as idx,
        if(d.dy != 0, unnest(steps), idy) as idy,
        d.dir,
        ids = len(steps) as last,
    FROM moves m
    JOIN directions d ON d.dir = m.prev_dir
);

CREATE OR REPLACE MACRO step_id(idx, idy, dir) AS idx || '|' || idy || '|' || dir;
CREATE OR REPLACE TABLE loops AS (
WITH RECURSIVE
    loops AS (
        SELECT
            idm,
            ids,
            0 as idl,
            v.idx + d.dx as ox,
            v.idy + d.dy as oy,
            v.idx as idx,
            v.idy as idy,
            d.next as dir,
            false as cycle,
            [step_id(idx, idy, dir)] as path,
        FROM visited v
        JOIN directions d USING (dir)
        WHERE NOT v.last
        UNION ALL
        SELECT
            idm, ids, idl,
            ox, oy, idx, idy, dir,
            list_contains(path, step_id(idx, idy, dir)) as cycle,
            list_append(path, step_id(idx, idy, dir)) as path,
        FROM (
            SELECT
                idm, ids,
                idl + 1 as idl,
                ox, oy,
                c.idx - if(c.value = '#' OR (c.idx = l.ox AND c.idy = l.oy), d.dx, 0) as idx,
                c.idy - if(c.value = '#' OR (c.idx = l.ox AND c.idy = l.oy), d.dy, 0) as idy,
                d.next as dir,
                path,
            FROM 
                loops l,
                (FROM directions d WHERE d.dir = l.dir) d,
                (
                    FROM cells c
                    WHERE 
                        (c.value = '#' OR (c.idx = l.ox AND c.idy = l.oy)) AND 
                        CASE WHEN d.dx = 0
                            THEN c.idx = l.idx AND c.idy * d.dy > l.idy * d.dy
                            ELSE c.idy = l.idy AND c.idx * d.dx > l.idx * d.dx
                        END
                    ORDER BY abs(c.idx - l.idx) + abs(c.idy - l.idy)
                    LIMIT 1
                ) c
            WHERE NOT l.cycle
        )
    )
FROM loops);


CREATE OR REPLACE VIEW solution AS (
    SELECT
        (SELECT count() FROM (SELECT distinct idx, idy FROM visited)) as part1,
        (SELECT count() FROM (SELECT distinct ox, oy FROM loops WHERE cycle)) as part2
);

SET VARIABLE expected1 = if(getvariable('mode') = 'example', getvariable('exampleSolution1'), getvariable('solution1'));
SET VARIABLE expected2 = if(getvariable('mode') = 'example', getvariable('exampleSolution2'), getvariable('solution2'));
SELECT 
    'Part 1' as part,
    part1 as result,
    getvariable('expected1') as expected,
    result = expected as correct
FROM solution
UNION
SELECT 
    'Part 2' as part,
    part2 as result,
    getvariable('expected2') as expected,
    result = expected as correct
FROM solution;