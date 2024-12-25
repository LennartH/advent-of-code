SET VARIABLE example = '
    029A
    980A
    179A
    456A
    379A
';
CREATE OR REPLACE VIEW example AS SELECT regexp_split_to_table(trim(getvariable('example'), chr(10) || ' '), '\n\s*') as line;
SET VARIABLE exampleSolution1 = 126384;
SET VARIABLE exampleSolution2 = 154115708116294;

CREATE OR REPLACE TABLE input AS
SELECT regexp_split_to_table(trim(content, chr(10) || ' '), '\n\s*') as line FROM read_text('input');
SET VARIABLE solution1 = 156714;
SET VARIABLE solution2 = 191139369248202;

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

-- numpaths with less branches by ranking with some heuristic (repeating symbols)
CREATE OR REPLACE TABLE numpaths AS (
    WITH RECURSIVE
        paths AS (
            SELECT
                n1 as from_button,
                n2 as to_button,
                [n1] as path,
                [move] as moves,
                0 as score,
            FROM numpad
            UNION ALL
            SELECT
                p.from_button,
                n.n2 as to_button,
                list_append(p.path, p.to_button) as path,
                list_append(p.moves, n.move) as moves,
                score - if(p.moves[-1] != n.move, 1, 0) as score,
            FROM paths p
            JOIN numpad n ON n.n1 = p.to_button
            WHERE NOT EXISTS (
                FROM paths pp
                WHERE pp.from_button = p.from_button AND n.n2 IN pp.path
            )
        ),
        ranked_paths AS (
            FROM paths
            QUALIFY dense_rank() OVER (
                PARTITION BY from_button, to_button 
                ORDER BY score desc
            ) = 1
        )

    SELECT
        from_button as n1,
        to_button as n2,
        list_append(moves, 'A') as moves,
    FROM ranked_paths
);

-- Optimal moves taken from reddit:
--  - https://www.reddit.com/r/adventofcode/comments/1hjgyps/2024_day_21_part_2_i_got_greedyish/
--  - https://www.reddit.com/r/adventofcode/comments/1hj7f89/comment/m34erhg/
CREATE OR REPLACE TABLE dir_moves AS (
    SELECT
        id, d1, d2,
        list(m2 ORDER BY pos) as path,
        list(move_id ORDER BY pos) as move_ids,
    FROM (
        SELECT
            d1 || d2 as id,
            d1, d2,
            unnest(generate_series(1, len(moves) + 1)) as pos,
            unnest(list_prepend('A', moves)) as m1,
            unnest(list_append(moves, 'A')) as m2,
            m1 || m2 as move_id,
        FROM (VALUES
            ('<', '>', ['>', '>']),
            ('<', 'A', ['>', '>', '^']),
            ('<', '^', ['>', '^']),
            ('<', 'v', ['>']),

            ('>', '<', ['<', '<']),
            ('>', 'A', ['^']),
            ('>', '^', ['<', '^']),
            ('>', 'v', ['<']),

            ('A', '<', ['v', '<', '<']),
            ('A', '>', ['v']),
            ('A', '^', ['<']),
            ('A', 'v', ['<', 'v']),

            ('^', '<', ['v', '<']),
            ('^', '>', ['v', '>']),
            ('^', 'A', ['>']),
            ('^', 'v', ['v']),

            ('v', '<', ['<']),
            ('v', '>', ['>']),
            ('v', 'A', ['^', '>']),
            ('v', '^', ['^']),
        ) _(d1, d2, moves)
    )
    GROUP BY id, d1, d2
);

--  Example evolution for movement from < to ^
-- 0:     |<                                                                                                                          ^
-- 1:   3 |                                        >                                                      ^                           A
-- 2:   7 |                     v                  A                         <                  ^         A               >           A
-- 3:  19 |          <   v      A       ^      >   A        v       <<       A     >        ^   A     >   A        v      A       ^   A
-- 4:  47 |   v <<   A > A ^  > A   <   A  v > A ^ A   < v  A   <   AA >>  ^ A  v  A   <  ^ A > A  v  A ^ A   < v  A ^  > A   <   A > A
-- 5: 123 | <vA<AA>>^AvA^A<Av>A^Av<<A>>^A<vA>A^A<A>Av<<A>A^>Av<<A>>^AAvAA<^A>A<vA^>Av<<A>^A>AvA^A<vA^>A<A>Av<<A>A^>A<Av>A^Av<<A>>^AvA^A

CREATE OR REPLACE TABLE frequencies AS (
    WITH RECURSIVE
        dir_move_lookup AS (
            SELECT
                id,
                unnest(move_ids) as move_id,
            FROM dir_moves
        ),
        frequencies AS (
            SELECT
                1 as depth,
                id,
                move_id,
                1::HUGEINT as move_count,
            FROM dir_move_lookup
            UNION ALL (
                WITH
                    extend AS (
                        SELECT
                            f.depth,
                            f.id,
                            coalesce(l.move_id, '*') as move_id,
                            f.move_count as move_count,
                        FROM frequencies f
                        LEFT JOIN dir_move_lookup l ON l.id = f.move_id
                    )

                SELECT
                    any_value(depth) + 1 as depth,
                    id,
                    move_id,
                    sum(move_count) as move_count,
                FROM extend
                WHERE depth < 25
                GROUP BY id, move_id
            )
        )

    SELECT
        depth,
        id,
        d1,
        d2,
        move_count,
    FROM (
        SELECT
            depth,
            id,
            sum(move_count) as move_count,
        FROM frequencies
        GROUP BY depth, id
    )
    JOIN dir_moves USING (id)
);

CREATE OR REPLACE VIEW sequences AS (
    WITH
        tracked_numpaths AS (
            SELECT
                row_number() OVER () as id,
                n1, n2,
                moves
            FROM numpaths
        ),
        unnest_numpaths AS (
            SELECT
                id,
                n1, n2,
                unnest(list_prepend('A', moves[:-2])) as d1,
                unnest(moves) as d2,
            FROM tracked_numpaths
        ),
        numpath_lengths AS (
            SELECT
                depth, n1, n2,
                min(length) as length,
            FROM (
                SELECT
                    depth, id,
                    any_value(n1) as n1,
                    any_value(n2) as n2,
                    sum(length) as length,
                FROM (
                    SELECT
                        unnest(if(f.depth IS NULL, [2, 25], [f.depth])) as depth,
                        n.id,
                        n.n1, n.n2,
                        n.d1, n.d2,
                        coalesce(f.move_count, 1) as length,
                    FROM unnest_numpaths n
                    LEFT JOIN frequencies f USING (d1, d2)
                    WHERE f.depth IS NULL OR f.depth = 2 OR f.depth = 25
                )
                GROUP BY depth, id
            )
            GROUP BY depth, n1, n2
        ),
        unnest_codes AS (
            SELECT
                id,
                list_aggregate(code, 'string_agg', '') as code,
                unnest(list_prepend('A', code[:-2])) as n1,
                unnest(code) as n2,
                value,
            FROM codes
        ),
        code_lengths AS (
            SELECT
                depth,
                id,
                any_value(code) as code,
                any_value(value) as value,
                sum(length) as length,
            FROM (
                SELECT
                    n.depth,
                    c.id, c.code,
                    c.n1, c.n2,
                    c.value,
                    n.length
                FROM unnest_codes c
                JOIN numpath_lengths n USING (n1, n2)
            )
            GROUP BY depth, id,
        )

    SELECT
        depth,
        id, code,
        value,
        length,
        value * length as complexity,
    FROM code_lengths
);


CREATE OR REPLACE VIEW results AS (
    SELECT
        sum(complexity) FILTER (depth < 10) as part1,
        sum(complexity) FILTER (depth > 10) as part2,
    FROM sequences
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
