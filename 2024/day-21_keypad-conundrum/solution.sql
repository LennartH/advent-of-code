SET VARIABLE example = '
    029A
    980A
    179A
    456A
    379A
';
CREATE OR REPLACE VIEW example AS SELECT regexp_split_to_table(trim(getvariable('example'), chr(10) || ' '), '\n\s*') as line;
SET VARIABLE exampleSolution1 = 126384;
SET VARIABLE exampleSolution2 = NULL;

CREATE OR REPLACE TABLE input AS
SELECT regexp_split_to_table(trim(content, chr(10) || ' '), '\n\s*') as line FROM read_text('input');
SET VARIABLE solution1 = 156714;
SET VARIABLE solution2 = NULL;

-- SET VARIABLE mode = 'example';
SET VARIABLE mode = 'input';

CREATE OR REPLACE VIEW codes AS (
    SELECT
        row_number() OVER () as id,
        string_split(line, '') as code,
        line[:-2]::INTEGER as value,
    FROM query_table(getvariable('mode'))
);

CREATE OR REPLACE TABLE numpad AS (
    FROM (VALUES
        ('7', '8', '>'),
        ('7', '4', 'v'),

        ('8', '7', '<'),
        ('8', '5', 'v'),
        ('8', '9', '>'),

        ('9', '8', '<'),
        ('9', '6', 'v'),

        ('4', '7', '^'),
        ('4', '5', '>'),
        ('4', '1', 'v'),

        ('5', '4', '<'),
        ('5', '8', '^'),
        ('5', '6', '>'),
        ('5', '2', 'v'),

        ('6', '5', '<'),
        ('6', '9', '^'),
        ('6', '3', 'v'),

        ('1', '4', '^'),
        ('1', '2', '>'),

        ('2', '1', '<'),
        ('2', '5', '^'),
        ('2', '3', '>'),
        ('2', '0', 'v'),

        ('3', '2', '<'),
        ('3', '6', '^'),
        ('3', 'A', 'v'),

        ('0', '2', '^'),
        ('0', 'A', '>'),

        ('A', '0', '<'),
        ('A', '3', '^'),
    ) _(n1, n2, move)
);

CREATE OR REPLACE TABLE dirpad AS (
    FROM (VALUES
        ('^', 'A', '>'),
        ('^', 'v', 'v'),

        ('A', '^', '<'),
        ('A', '>', 'v'),

        ('<', 'v', '>'),

        ('v', '<', '<'),
        ('v', '^', '^'),
        ('v', '>', '>'),

        ('>', 'v', '<'),
        ('>', 'A', '^'),
    ) _(d1, d2, move)
);

CREATE OR REPLACE TABLE numpaths AS (
    WITH RECURSIVE
        paths AS (
            SELECT
                n1 as from_button,
                n2 as to_button,
                [n1] as path,
                [move] as moves,
            FROM numpad
            UNION ALL
            SELECT
                p.from_button,
                n.n2 as to_button,
                list_append(p.path, p.to_button) as path,
                list_append(p.moves, n.move) as moves,
            FROM paths p
            JOIN numpad n ON n.n1 = p.to_button
            WHERE NOT EXISTS (
                FROM paths pp
                WHERE pp.from_button = p.from_button AND n.n2 IN pp.path
            )
        )

    SELECT
        from_button as n1,
        to_button as n2,
        list_append(moves, 'A') as moves,
    FROM paths
);

CREATE OR REPLACE TABLE dirpaths AS (
    WITH RECURSIVE
        paths AS (
            SELECT
                d1 as from_button,
                d2 as to_button,
                [d1] as path,
                [move] as moves,
            FROM dirpad
            UNION ALL
            SELECT
                p.from_button,
                d.d2 as to_button,
                list_append(p.path, p.to_button) as path,
                list_append(p.moves, d.move) as moves,
            FROM paths p
            JOIN dirpad d ON d.d1 = p.to_button
            WHERE NOT EXISTS (
                FROM paths pp
                WHERE pp.from_button = p.from_button AND d.d2 IN pp.path
            )
        )

    SELECT
        from_button as d1,
        to_button as d2,
        list_append(moves, 'A') as moves,
    FROM paths
);

-- TODO Clean aliases
CREATE OR REPLACE TABLE expanded_dirpaths AS (
    WITH RECURSIVE
        tracked_dirpaths AS (
            SELECT
                d.*,
                row_number() OVER (PARTITION BY d1, d2) as id,
            FROM dirpaths d
        ),
        exploded AS (
            SELECT
                d1 as from_d1,
                d2 as to_d2,
                id,
                generate_subscripts(moves, 1) as pos,
                unnest(list_prepend('A', moves[:-2])) as d1,
                unnest(moves) as d2,
                len(moves) as length,
            FROM tracked_dirpaths
        ),
        moves AS (
            SELECT
                from_d1, to_d2,
                id, pos, length,
                d1, d2,
                coalesce(moves, ['A']) as moves,
            FROM exploded
            LEFT JOIN dirpaths USING (d1, d2)
        ),
        expanded AS (
            SELECT
                from_d1, to_d2,
                id, pos, length,
                moves,
            FROM moves
            WHERE pos = 1
            UNION ALL
            SELECT
                e.from_d1,
                e.to_d2,
                e.id,
                m.pos,
                e.length,
                e.moves || m.moves AS moves,
            FROM expanded e
            JOIN moves m USING (from_d1, to_d2, id) 
            WHERE m.pos = e.pos + 1
        ),
        shortest AS (
            SELECT
                from_d1, to_d2, id, moves,
                row_number() OVER (PARTITION BY from_d1, to_d2 ORDER BY len(moves)) as rank,
            FROM expanded
            WHERE pos = length
            QUALIFY rank = 1
        )

    SELECT
        s.from_d1 as d1,
        s.to_d2 as d2,
        n.moves as dir2_moves,
        s.moves as dir1_moves,
    FROM shortest s
    JOIN tracked_dirpaths n ON s.from_d1 = n.d1 AND 
                               s.to_d2 = n.d2 AND 
                               s.id = n.id
);


CREATE OR REPLACE TABLE expanded_numpaths AS (
    WITH RECURSIVE
        tracked_numpaths AS (
            SELECT
                n.*,
                row_number() OVER (PARTITION BY n1, n2) as id,
            FROM numpaths n
        ),
        exploded AS (
            SELECT
                n1, n2, id,
                generate_subscripts(moves, 1) as pos,
                unnest(list_prepend('A', moves[:-2])) as d1,
                unnest(moves) as d2,
                len(moves) as length,
            FROM tracked_numpaths
        ),
        moves AS (
            SELECT
                n1, n2,
                id, pos, length,
                d1, d2,
                coalesce(dir2_moves, ['A']) as dir2_moves,
                coalesce(dir1_moves, ['A']) as dir1_moves,
            FROM exploded
            LEFT JOIN expanded_dirpaths USING (d1, d2)
        ),
        expanded AS (
            SELECT
                n1, n2, id,
                pos, length,
                dir2_moves,
                dir1_moves,
            FROM moves
            WHERE pos = 1
            UNION ALL
            SELECT
                e.n1, e.n2, e.id,
                m.pos, e.length,
                e.dir2_moves || m.dir2_moves AS dir2_moves,
                e.dir1_moves || m.dir1_moves AS dir1_moves,
            FROM expanded e
            JOIN moves m ON m.n1 = e.n1 AND m.n2 = e.n2 AND m.id = e.id AND m.pos = e.pos + 1
        ),
        shortest AS (
            SELECT
                n1, n2, id, dir2_moves, dir1_moves,
                row_number() OVER (PARTITION BY n1, n2 ORDER BY len(dir1_moves)) as rank,
            FROM expanded
            WHERE pos = length
            QUALIFY rank = 1
        )

    SELECT
        s.n1, s.n2,
        n.moves as dir3_moves,
        s.dir2_moves,
        s.dir1_moves,
    FROM shortest s
    JOIN tracked_numpaths n USING (n1, n2, id)
);

CREATE OR REPLACE VIEW sequences AS (
    WITH
        button_presses AS (
            SELECT
                id, n1, n2, pos,
                dir3_moves,
                dir2_moves,
                dir1_moves,
            FROM (
                SELECT
                    id,
                    generate_subscripts(code, 1) as pos,
                    unnest(list_prepend('A', code[:-2])) as n1,
                    unnest(code) as n2,
                FROM codes
            )
            JOIN expanded_numpaths USING (n1, n2)
        ),
        aggregated_button_presses AS (
            SELECT
                id,
                flatten(list(dir3_moves ORDER BY pos)) as dir3_moves,
                flatten(list(dir2_moves ORDER BY pos)) as dir2_moves,
                flatten(list(dir1_moves ORDER BY pos)) as dir1_moves,
            FROM button_presses
            GROUP BY id
        )

    SELECT
        id,
        list_aggregate(code, 'string_agg', '') as numpad,
        list_aggregate(dir3_moves, 'string_agg', '') as dirpad3,
        list_aggregate(dir2_moves, 'string_agg', '') as dirpad2,
        list_aggregate(dir1_moves, 'string_agg', '') as dirpad1,
        value,
        len(dir1_moves) as length,
        value * length as complexity,
    FROM aggregated_button_presses
    JOIN codes USING (id)
    ORDER BY id
);

CREATE OR REPLACE VIEW results AS (
    SELECT
        (SELECT sum(complexity) FROM sequences) as part1,
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
