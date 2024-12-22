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
SET VARIABLE solution1 = NULL; -- 160190 too high
SET VARIABLE solution2 = NULL;

SET VARIABLE mode = 'example';
-- SET VARIABLE mode = 'input';

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

-- CREATE OR REPLACE MACRO moveval(move) AS CASE
--     WHEN move = '<' THEN 0
--     WHEN move = 'v' THEN 1
--     ELSE 2
-- END;

CREATE OR REPLACE TABLE numpaths AS (
    WITH RECURSIVE
        paths AS (
            SELECT
                n1 as from_button,
                n2 as to_button,
                [n1] as path,
                [move] as moves,
                -- [moveval(move)] as movevals,
                -- 0 as pairs,
            FROM numpad
            UNION ALL
            SELECT
                p.from_button,
                n.n2 as to_button,
                list_append(p.path, p.to_button) as path,
                list_append(p.moves, n.move) as moves,
                -- list_append(p.movevals, moveval(n.move)) as movevals,
                -- p.pairs + if(n.move = p.moves[-1], 1, 0) as pairs,
            FROM paths p
            JOIN numpad n ON n.n1 = p.to_button
            WHERE NOT EXISTS (
                FROM paths pp
                WHERE pp.from_button = p.from_button AND n.n2 IN pp.path
            )
        )
        -- distinct_paths AS (
        --     SELECT
        --         from_button,
        --         to_button,
        --         -- max_by(moves, pairs) as moves,
        --         min_by(moves, movevals) as moves,
        --     FROM paths
        --     GROUP BY from_button, to_button
        -- )

    SELECT
        from_button as n1,
        to_button as n2,
        -- pairs,
        row_number() OVER (PARTITION BY from_button, to_button) as perm,
        list_append(moves, 'A') as moves,
        -- movevals,
    -- FROM distinct_paths
    FROM paths
    -- WHERE n1 = 'A'
    -- ORDER BY from_button, to_button
);

-- FIXME yikes
-- UPDATE numpaths SET moves = ['<', '<', '^', '^', 'A']
-- WHERE n1 = '3' AND n2 = '7';


-- FROM (VALUES
--     ('0', '4', ['^', '^', '<']),
--     ('0', '4', ['^', '<', '^']),
--     ('0', '6', ['^', '^', '>']),
--     ('0', '6', ['^', '>', '^']),
--     ('0', '6', ['>', '^', '^']),
--     ('0', '7', ['^', '^', '<', '^']),
--     ('0', '7', ['^', '<', '^', '^']),
--     ('0', '7', ['^', '^', '^', '<']),
--     ('0', '8', ['^', '^', '^']),
--     ('0', '9', ['^', '^', '>', '^']),
--     ('0', '9', ['^', '>', '^', '^']),
--     ('0', '9', ['^', '^', '^', '>']),
--     ('0', '9', ['>', '^', '^', '^']),
--     ('1', '6', ['^', '>', '>']),
--     ('1', '6', ['>', '^', '>']),
--     ('1', '6', ['>', '>', '^']),
--     ('1', '8', ['^', '>', '^']),
--     ('1', '8', ['>', '^', '^']),
--     ('1', '8', ['^', '^', '>']),
--     ('1', '9', ['>', '^', '^', '>']),
--     ('1', '9', ['^', '>', '^', '>']),
--     ('1', '9', ['^', '>', '>', '^']),
--     ('1', '9', ['>', '>', '^', '^']),
--     ('1', '9', ['^', '^', '>', '>']),
--     ('1', '9', ['>', '^', '>', '^']),
--     ('1', 'A', ['>', '>', 'v']),
--     ('1', 'A', ['>', 'v', '>']),
-- ) _(from_button, to_button, moves)
-- ;


CREATE OR REPLACE TABLE dirpaths AS (
    WITH RECURSIVE
        paths AS (
            SELECT
                d1 as from_button,
                d2 as to_button,
                [d1] as path,
                [move] as moves,
                -- [moveval(move)] as movevals,
                -- 0 as pairs,
            FROM dirpad
            UNION ALL
            SELECT
                p.from_button,
                d.d2 as to_button,
                list_append(p.path, p.to_button) as path,
                list_append(p.moves, d.move) as moves,
                -- list_append(p.movevals, moveval(d.move)) as movevals,
                -- p.pairs + if(d.move = p.moves[-1], 1, 0) as pairs,
            FROM paths p
            JOIN dirpad d ON d.d1 = p.to_button
            WHERE NOT EXISTS (
                FROM paths pp
                WHERE pp.from_button = p.from_button AND d.d2 IN pp.path
            )
        )
        -- distinct_paths AS (
        --     SELECT
        --         from_button,
        --         to_button,
        --         -- max_by(moves, pairs) as moves,
        --         min_by(moves, movevals) as moves,
        --     FROM paths
        --     GROUP BY from_button, to_button
        -- )

    SELECT
        from_button as d1,
        to_button as d2,
        row_number() OVER (PARTITION BY from_button, to_button) as perm,
        list_append(moves, 'A') as moves,
    -- FROM distinct_paths
    FROM paths
);


WITH RECURSIVE
    dir3_to_num_steps AS (
        SELECT
            code,
            id,
            pos,
            length,
            n1,
            n2,
            perm,
            coalesce(moves, ['A']) as moves,
        FROM (
            SELECT
                code,
                id,
                pos,
                length,
                coalesce(lag(button) OVER (PARTITION BY code, id ORDER BY pos), 'A') as n1,
                button as n2,
            FROM (
                SELECT
                    id as code,
                    id,
                    generate_subscripts(code, 1) as pos,
                    len(code) AS length,
                    unnest(code) as button,
                FROM codes
                -- delete me
                -- WHERE id IN (1, 2)
                -- WHERE id = 2
            )
        )
        LEFT JOIN numpaths p USING (n1, n2)
    ),
    dir3_to_num AS (
        SELECT
            code,
            id,
            pos,
            length,
            0 as perm,
            moves,
        FROM dir3_to_num_steps
        WHERE pos = 1
        UNION ALL
        SELECT
            p.code,
            p.id,
            s.pos,
            p.length,
            row_number() OVER (PARTITION BY p.code, p.id) as perm,
            list_concat(p.moves, s.moves) as moves,
        FROM dir3_to_num p
        JOIN dir3_to_num_steps s ON p.code = s.code AND p.id = s.id AND s.pos = p.pos + 1
    ),
    dir2_to_dir3_steps AS (
        SELECT
            code,
            id,
            pos,
            length,
            d1,
            d2,
            coalesce(moves, ['A']) as moves,
        FROM (
            SELECT
                code,
                id,
                pos,
                length,
                coalesce(lag(button) OVER (PARTITION BY code, id ORDER BY pos), 'A') as d1,
                button as d2,
            FROM (
                SELECT
                    code,
                    perm as id,
                    generate_subscripts(moves, 1) as pos,
                    len(moves) AS length,
                    unnest(moves) as button,
                FROM dir3_to_num
                WHERE length = pos
            )
        )
        LEFT JOIN dirpaths p USING (d1, d2)
    ),
    dir2_to_dir3 AS (
        SELECT
            code,
            id,
            pos,
            length,
            0 as perm,
            moves,
        FROM dir2_to_dir3_steps
        WHERE pos = 1
        UNION ALL
        SELECT
            p.code,
            p.id,
            s.pos,
            p.length,
            row_number() OVER (PARTITION BY p.code, p.id) as perm,
            list_concat(p.moves, s.moves) as moves,
        FROM dir2_to_dir3 p
        JOIN dir2_to_dir3_steps s ON p.code = s.code AND p.id = s.id AND s.pos = p.pos + 1
    ),
    dir1_to_dir2_steps AS (
        SELECT
            code,
            id,
            pos,
            length,
            d1,
            d2,
            coalesce(moves, ['A']) as moves,
        FROM (
            SELECT
                code,
                id,
                pos,
                length,
                coalesce(lag(button) OVER (PARTITION BY code, id ORDER BY pos), 'A') as d1,
                button as d2,
            FROM (
                SELECT
                    code,
                    perm as id,
                    generate_subscripts(moves, 1) as pos,
                    len(moves) AS length,
                    unnest(moves) as button,
                FROM dir2_to_dir3
                WHERE length = pos
                -- delete me
                --   AND perm IN (1, 2)
            )
        )
        LEFT JOIN dirpaths p USING (d1, d2)
    ),
    dir1_to_dir2 AS (
        SELECT
            code,
            id,
            pos,
            length,
            1 as perm,
            moves,
        FROM dir1_to_dir2_steps
        WHERE pos = 1
        UNION ALL
        SELECT
            p.code,
            p.id,
            s.pos,
            p.length,
            row_number() OVER (PARTITION BY p.code, p.id) as perm,
            list_concat(p.moves, s.moves) as moves,
        FROM dir1_to_dir2 p
        JOIN dir1_to_dir2_steps s ON p.code = s.code AND p.id = s.id AND s.pos = p.pos + 1
        WHERE perm = 1
    )

-- SELECT
--     code, id,
--     list(DISTINCT len(moves)) as seq_len,
-- FROM dir1_to_dir2
-- WHERE length = pos
-- GROUP BY code, id
-- ORDER BY code, id
-- ;

-- SELECT
--     code,
--     min(len(moves)) as seq_len,
-- FROM dir1_to_dir2
-- WHERE length = pos AND code = 1
-- GROUP BY code
-- ORDER BY code
-- ;

FROM (
    SELECT
        code,
        list_aggregate(moves, 'string_agg', '') as moves,
    FROM dir1_to_dir2
    WHERE length = pos AND code = 1
)
WHERE starts_with(moves, '<vA<AA>>^AvAA<^A>A<v<A>>^AvA^A<vA')
;


-- TODO Simplify: flatten instead of unnest+groupby, wrap into recursive CTE?
CREATE OR REPLACE VIEW sequences AS (
    WITH
        numpresses AS (
            SELECT
                s.id as code,
                s.pos as id,
                -- row_number() OVER (PARTITION BY id, pos) as pos,
                s.n1,
                s.n2,
                coalesce(p.moves, ['A']) as moves,
            FROM (
                SELECT
                    id,
                    pos,
                    coalesce(lag(button) OVER (PARTITION BY id ORDER BY pos), 'A') as n1,
                    button as n2,
                FROM (
                    SELECT
                        id,
                        generate_subscripts(code, 1) as pos,
                        unnest(code) as button,
                    FROM codes
                )
            ) s
            LEFT JOIN numpaths p USING (n1, n2)
            -- -- delete me
            -- ORDER BY code, n1, n2
            -- ;
        ),
        dirpresses1 AS (
            SELECT
                s.code,
                s.pos as id,
                s.d1,
                s.d2,
                coalesce(p.moves, ['A']) as moves,
            FROM (
                SELECT
                    code,
                    id,
                    row_number() OVER (PARTITION BY code ORDER BY id, pos) as pos,
                    coalesce(lag(button) OVER (PARTITION BY code, id ORDER BY pos), 'A') as d1,
                    button as d2,
                FROM (
                    SELECT
                        code,
                        id,
                        generate_subscripts(moves, 1) as pos,
                        unnest(moves) as button,
                    FROM numpresses
                )
            ) s
            LEFT JOIN dirpaths p USING (d1, d2)
        ),
        dirpresses2 AS (
            SELECT
                s.code,
                s.pos as id,
                s.d1,
                s.d2,
                coalesce(p.moves, ['A']) as moves,
            FROM (
                SELECT
                    code,
                    id,
                    row_number() OVER (PARTITION BY code ORDER BY id, pos) as pos,
                    coalesce(lag(button) OVER (PARTITION BY code, id ORDER BY pos), 'A') as d1,
                    button as d2,
                FROM (
                    SELECT
                        code,
                        id,
                        generate_subscripts(moves, 1) as pos,
                        unnest(moves) as button,
                    FROM dirpresses1
                )
            ) s
            LEFT JOIN dirpaths p USING (d1, d2)
        )

    -- FROM dirpresses1
    -- WHERE code = 1
    -- ORDER BY code, id
    -- ;


    SELECT
        c.id,
        list_aggregate(c.code, 'string_agg', '') as code,
        s.sequence,
        len(s.sequence) as length,
        c.value,
        length * c.value as complexity,
    FROM (
        SELECT
            code,
            string_agg(button, '' ORDER BY id, pos) as sequence,
        FROM (
            SELECT
                code,
                id,
                generate_subscripts(moves, 1) as pos,
                unnest(moves) as button,
            FROM dirpresses2
        )
        GROUP BY code
    ) s
    JOIN codes c ON c.id = s.code
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
