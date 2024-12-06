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
SET VARIABLE exampleSolution2 = NULL;

CREATE OR REPLACE TABLE input AS SELECT regexp_split_to_table(trim(content, E'\n '), '\n') as line FROM read_text('input');
SET VARIABLE solution1 = 4433;
SET VARIABLE solution2 = NULL;

SET VARIABLE mode = 'input';

CREATE OR REPLACE VIEW cells AS (
    SELECT 
        generate_subscripts(values, 1) as idx,
        idy,
        unnest(values) as value
    FROM (
        SELECT
            row_number() OVER () as idy,
            string_split(line, '') as values,
        FROM query_table(getvariable('mode'))
    )
);

CREATE OR REPLACE VIEW directions AS (
    FROM (VALUES 
        ('^', '>',  0, -1, NULL, 0),
        ('>', 'v',  1,  0, (SELECT max(idx) FROM cells) + 1, NULL),
        ('v', '<',  0,  1, NULL, (SELECT max(idy) FROM cells) + 1),
        ('<', '^', -1,  0, 0, NULL)
    ) directions(dir, next, dx, dy, edge_x, edge_y)
);

CREATE OR REPLACE VIEW moves AS (
WITH RECURSIVE
    moves AS (
        SELECT
            0 as move,
            idx,
            idy,
            value as dir
        FROM cells
        WHERE value IN  ('^', '>', 'v', '<')
        UNION ALL
        SELECT
            m.move + 1 as move,
            c.idx - d.dx as idx,
            c.idy - d.dy as idy,
            CASE WHEN edge THEN NULL ELSE d.next END as dir, -- this breaks the recursion
        FROM moves m, (SELECT
            c.idx, c.idy,
            abs(c.idx - m.idx) + abs(c.idy - m.idy) as distance,
            edge
            FROM (
                SELECT c.idx, c.idy, false as edge
                FROM cells c
                WHERE c.value = '#' AND (CASE
                    WHEN m.dir = '^' THEN c.idy < m.idy AND c.idx = m.idx
                    WHEN m.dir = '>' THEN c.idx > m.idx AND c.idy = m.idy
                    WHEN m.dir = 'v' THEN c.idy > m.idy AND c.idx = m.idx
                    WHEN m.dir = '<' THEN c.idx < m.idx AND c.idy = m.idy
                END)
                UNION ALL
                SELECT
                    coalesce(edge_x, m.idx) as idx,
                    coalesce(edge_y, m.idy) as idy,
                    true as edge
                FROM directions d WHERE d.dir = m.dir
            ) c
            ORDER BY distance asc
            LIMIT 1
        ) c,
        (FROM directions d WHERE d.dir = m.dir) d
    )
SELECT * FROM moves);

CREATE OR REPLACE MACRO vmin(a, b) AS CASE WHEN a < b THEN a ELSE b END;
CREATE OR REPLACE MACRO vmax(a, b) AS CASE WHEN a > b THEN a ELSE b END;
CREATE OR REPLACE VIEW visited AS (
WITH
    from_to AS (
        SELECT *,
            lead(idx) OVER (ORDER BY move) as nx,
            lead(idy) OVER (ORDER BY move) as ny,
        FROM moves
    ),
    paths AS (
        SELECT
            move,
            range(vmin(idx, nx), vmax(idx, nx) + 1) as idx,
            range(vmin(idy, ny), vmax(idy, ny) + 1) as idy,
        FROM from_to
    )
SELECT 
    move,
    CASE WHEN len(idx) = 1 THEN idx[1] ELSE unnest(idx) END as idx,
    CASE WHEN len(idy) = 1 THEN idy[1] ELSE unnest(idy) END as idy,
FROM paths);

CREATE OR REPLACE VIEW solution AS (
    SELECT
        (SELECT count() FROM (SELECT distinct idx, idy FROM visited)) as part1,
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