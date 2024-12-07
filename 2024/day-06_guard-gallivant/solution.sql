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
        ('^', '>', '<',  0, -1, NULL, 0),
        ('>', 'v', '^',  1,  0, (SELECT max(idx) FROM cells) + 1, NULL),
        ('v', '<', '>',  0,  1, NULL, (SELECT max(idy) FROM cells) + 1),
        ('<', '^', 'v', -1,  0, 0, NULL)
    ) directions(dir, next, prev, dx, dy, edge_x, edge_y)
);

CREATE OR REPLACE TABLE visited AS (
WITH RECURSIVE
    visited AS (
        SELECT
            0 as idm,
            idx,
            idy,
            dir,
            [idx||','||idy||dir] as path,
        FROM cells
        JOIN directions d ON d.dir = value
        UNION ALL
        SELECT 
            * EXCLUDE (path),
            list_append(path, idx||','||idy||dir) as path
        FROM (
            SELECT
                idm + 1 as idm,
                -- v.idx + if(value = '#', dd.dx, d.dx) as idx,
                -- v.idy + if(value = '#', dd.dy, d.dy) as idy,
                -- if(value = '#', dd.dir, d.dir) as dir,
                v.idx + if(value = '#', 0, d.dx) as idx,
                v.idy + if(value = '#', 0, d.dy) as idy,
                if(value = '#', d.next, d.dir) as dir,
                path,
            FROM visited v
            JOIN directions d USING (dir)
            -- JOIN directions dd ON dd.dir = d.next
            JOIN cells c ON c.idx = v.idx + d.dx AND c.idy = v.idy + d.dy
        )
    )
SELECT * FROM visited);

CREATE OR REPLACE VIEW obstacles AS (
WITH RECURSIVE
    obstacles AS (
        SELECT
            idm,
            idm as ido,
            v.idx as ox,
            v.idy as oy,
            v.idx - d.dx as idx,
            v.idy - d.dy as idy,
            d.next as dir,
            false as seen,
            false as loop,
            path[:-2] as path,
        FROM visited v
        JOIN directions d USING (dir)
        WHERE idm > 0
        UNION ALL
        SELECT
            * EXCLUDE path,
            EXISTS(FROM visited v WHERE v.idx = p.idx AND v.idy = p.idy AND v.dir = p.dir) as seen,
            list_contains(p.path, idx||','||idy||dir) as loop,
            list_append(p.path, idx||','||idy||dir) as path,
        FROM (
            SELECT
                p.idm,
                p.ido + 1 as ido,
                p.ox,
                p.oy,
                -- p.idx + if(value = '#' OR (c.idx = p.ox AND c.idy = p.oy), dd.dx, d.dx) as idx,
                -- p.idy + if(value = '#' OR (c.idx = p.ox AND c.idy = p.oy), dd.dy, d.dy) as idy,
                -- if(value = '#' OR (c.idx = p.ox AND c.idy = p.oy), dd.dir, d.dir) as dir,
                p.idx + if(value = '#' OR (c.idx = p.ox AND c.idy = p.oy), 0, d.dx) as idx,
                p.idy + if(value = '#' OR (c.idx = p.ox AND c.idy = p.oy), 0, d.dy) as idy,
                if(value = '#' OR (c.idx = p.ox AND c.idy = p.oy), d.next, d.dir) as dir,
                path,
            FROM obstacles p
            JOIN directions d USING (dir)
            -- JOIN directions dd ON dd.dir = d.next
            JOIN cells c ON c.idx = p.idx + d.dx AND c.idy = p.idy + d.dy
            WHERE NOT p.seen AND NOT p.loop
        ) p
    )
SELECT idm, ox as idx, oy as idy, loop, path FROM obstacles);

-- CREATE OR REPLACE VIEW obstacles AS (
--     SELECT
--         idm,
--         p.idx as idx,
--         p.idy as idy,
--         p.dir as dir,
--         (SELECT count() FROM visited v 
--          WHERE v.idx = c.idx - d.dx 
--            AND v.idy = c.idy - d.dy 
--         --    AND v.idm < p.idm
--         ) != 0 as visited
--     FROM (
--             SELECT 
--                 v.idm,
--                 v.idx,
--                 v.idy,
--                 d.next as dir,
--             FROM visited v 
--             JOIN moves m USING (idm)
--             JOIN directions d ON m.prev_dir = d.dir
--             WHERE NOT last
--         ) p,
--         (
--             SELECT
--                 c.idx, c.idy,
--                 abs(c.idx - p.idx) + abs(c.idy - p.idy) as distance
--             FROM cells c
--             WHERE c.value = '#' AND (CASE
--                 WHEN p.dir = '^' THEN c.idy < p.idy AND c.idx = p.idx
--                 WHEN p.dir = '>' THEN c.idx > p.idx AND c.idy = p.idy
--                 WHEN p.dir = 'v' THEN c.idy > p.idy AND c.idx = p.idx
--                 WHEN p.dir = '<' THEN c.idx < p.idx AND c.idy = p.idy
--             END)
--             ORDER BY distance asc
--             LIMIT 1
--         ) c,
--         (FROM directions d WHERE d.dir = p.dir) d
--     -- WHERE visited
-- );


CREATE OR REPLACE VIEW solution AS (
    SELECT
        (SELECT count() FROM (SELECT distinct idx, idy FROM visited)) as part1,
        -- (SELECT count() FROM (SELECT distinct idx, idy FROM obstacles WHERE loop)) as part2
        NULL as part2
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