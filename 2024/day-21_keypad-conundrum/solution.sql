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
SET VARIABLE solution2 = NULL; -- 602493282827076 too high

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

-- -- Used for lookup tables
-- CREATE OR REPLACE TABLE dir_buttons AS (
--     FROM (VALUES
--         (1, '<'),
--         (2, '^'),
--         (3, '>'),
--         (4, 'v'),
--         (5, 'A'),
--     ) _(id, symbol)
-- );

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

-- Shortest paths between all numpad buttons
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

-- Shortest paths between all dirpad buttons
CREATE OR REPLACE TABLE dirpaths AS (
    WITH RECURSIVE
        paths AS (
            SELECT
                d1 as from_button,
                d2 as to_button,
                [d1] as path,
                [move] as moves,
                0 as score,
            FROM dirpad
            UNION ALL
            SELECT
                p.from_button,
                d.d2 as to_button,
                list_append(p.path, p.to_button) as path,
                list_append(p.moves, d.move) as moves,
                score + if(p.moves[-1] = d.move, 1, 0) as score,
            FROM paths p
            JOIN dirpad d ON d.d1 = p.to_button
            WHERE NOT EXISTS (
                FROM paths pp
                WHERE pp.from_button = p.from_button AND d.d2 IN pp.path
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
        from_button as d1,
        to_button as d2,
        list_append(moves, 'A') as moves,
    FROM ranked_paths
);

-- -- numpaths with less branches by ranking with some heuristic (repeating symbols)
-- CREATE OR REPLACE TABLE numpaths AS (
--     WITH RECURSIVE
--         paths AS (
--             SELECT
--                 n1 as from_button,
--                 n2 as to_button,
--                 [n1] as path,
--                 [move] as moves,
--                 0 as score,
--             FROM numpad
--             UNION ALL
--             SELECT
--                 p.from_button,
--                 n.n2 as to_button,
--                 list_append(p.path, p.to_button) as path,
--                 list_append(p.moves, n.move) as moves,
--                 score - if(p.moves[-1] != n.move, 1, 0) as score,
--             FROM paths p
--             JOIN numpad n ON n.n1 = p.to_button
--             WHERE NOT EXISTS (
--                 FROM paths pp
--                 WHERE pp.from_button = p.from_button AND n.n2 IN pp.path
--             )
--         ),
--         ranked_paths AS (
--             FROM paths
--             QUALIFY dense_rank() OVER (
--                 PARTITION BY from_button, to_button 
--                 ORDER BY score desc
--             ) = 1
--         )

--     SELECT
--         from_button as n1,
--         to_button as n2,
--         list_append(moves, 'A') as moves,
--     FROM ranked_paths
-- );

-- -- dirpaths with less branches by ranking with some heuristic (repeating symbols)
-- CREATE OR REPLACE TABLE dirpaths AS (
--     WITH RECURSIVE
--         paths AS (
--             SELECT
--                 d1 as from_button,
--                 d2 as to_button,
--                 [d1] as path,
--                 [move] as moves,
--                 0 as score,
--             FROM dirpad
--             UNION ALL
--             SELECT
--                 p.from_button,
--                 d.d2 as to_button,
--                 list_append(p.path, p.to_button) as path,
--                 list_append(p.moves, d.move) as moves,
--                 score + if(p.moves[-1] = d.move, 1, 0) as score,
--             FROM paths p
--             JOIN dirpad d ON d.d1 = p.to_button
--             WHERE NOT EXISTS (
--                 FROM paths pp
--                 WHERE pp.from_button = p.from_button AND d.d2 IN pp.path
--             )
--         ),
--         ranked_paths AS (
--             FROM paths
--             QUALIFY dense_rank() OVER (
--                 PARTITION BY from_button, to_button 
--                 ORDER BY score desc
--             ) = 1
--         )

--     SELECT
--         from_button as d1,
--         to_button as d2,
--         list_append(moves, 'A') as moves,
--     FROM ranked_paths
-- );

-- -- Lookup table for movements on the dirpad (from d1 to d2 which buttons/moves have to be done on the next level)
-- CREATE OR REPLACE TABLE dirpad_lookup AS (
--     WITH RECURSIVE
--         move_ids AS (
--             SELECT
--                 -- row_number() OVER (ORDER BY b1.symbol, b2.symbol) as id,
--                 b1.symbol || b2.symbol as id,
--                 b1.symbol as d1,
--                 b2.symbol as d2,
--             FROM dir_buttons b1, dir_buttons b2
--             WHERE b1.id != b2.id
--         ),
--         paths AS (
--             SELECT
--                 d1 as from_button,
--                 d2 as to_button,
--                 [d1] as path,
--                 [move] as moves,
--                 0 as score,
--             FROM dirpad
--             UNION ALL
--             SELECT
--                 p.from_button,
--                 d.d2 as to_button,
--                 list_append(p.path, p.to_button) as path,
--                 list_append(p.moves, d.move) as moves,
--                 score + if(p.moves[-1] = d.move, 1, 0) as score,
--             FROM paths p
--             JOIN dirpad d ON d.d1 = p.to_button
--             WHERE NOT EXISTS (
--                 FROM paths pp
--                 WHERE pp.from_button = p.from_button AND d.d2 IN pp.path
--             )
--         ),
--         ranked_paths AS (
--             FROM paths
--             QUALIFY dense_rank() OVER (
--                 PARTITION BY from_button, to_button 
--                 ORDER BY score desc
--             ) = 1
--         )

--     SELECT
--         p.id,
--         p.d1, p.d2,
--         p.d1_id, p.d2_id,
--         p.branch, p.pos,
--         -- coalesce(m.id, 0) as move_id,
--         coalesce(m.id, '*') as move_id,
--         p.m1, p.m2,
--         m1.id as m1_id,
--         m2.id as m2_id,
--     FROM (
--         SELECT
--             m.id as id,
--             d1.id as d1_id,
--             from_button as d1,
--             d2.id as d2_id,
--             to_button as d2,
--             row_number() OVER (PARTITION BY from_button, to_button ORDER BY moves) as branch,
--             unnest(generate_series(1, len(moves) + 1)) as pos,
--             unnest(list_prepend('A', moves)) as m1,
--             unnest(list_append(moves, 'A')) as m2,
--         FROM ranked_paths
--         JOIN move_ids m ON from_button = m.d1 AND to_button = m.d2
--         JOIN dir_buttons d1 ON d1.symbol = from_button
--         JOIN dir_buttons d2 ON d2.symbol = to_button
--     ) p
--     LEFT JOIN move_ids m ON m.d1 = p.m1 AND m.d2 = p.m2
--     JOIN dir_buttons m1 ON m1.symbol = p.m1
--     JOIN dir_buttons m2 ON m2.symbol = p.m2

--     -- UNION ALL
--     -- SELECT
--     --     id as id1,
--     --     symbol as d1,
--     --     id as id2,
--     --     symbol as d2,
--     --     1 as branch,
--     --     1 as pos,
--     --     'A' as move,
--     --     (SELECT id FROM dir_buttons WHERE symbol = 'A') as move_id,
--     -- FROM dir_buttons

--     -- delete me
--     ORDER BY p.d1, p.d2, branch, pos
-- );

-- -- Attempt to calculate movement frequencies based on dirpad_lookup
-- -- Histogram unnesting/aggregating + branching paths make this very hard
-- -- See further down for previous/different attempts
-- CREATE OR REPLACE TABLE frequencies AS (
--     WITH RECURSIVE
--         frequencies AS (
--             SELECT DISTINCT ON (id)
--                 0 as depth,
--                 id as id,
--                 1 as branch,
--                 MAP{id: 1}::MAP(VARCHAR, UBIGINT) as moves,
--             FROM dirpad_lookup
--             -- delete me
--             WHERE d1 = 'A' AND d2 = 'v'
--         ),
--         frequenciess AS (
--             WITH
--                 explode AS (
--                     SELECT
--                         f.depth, f.id, f.branch,
--                         m.branch as sub,
--                         coalesce(m.move_id, '*') as move_id,
--                         value as move_count,
--                     FROM (
--                         SELECT 
--                             depth, id, branch,
--                             unnest(map_entries(moves), recursive := true),
--                         FROM frequencies
--                     ) f
--                     LEFT JOIN dirpad_lookup m ON m.id = key
--                 ),
--                 collect AS (
--                     SELECT
--                         depth,
--                         id,
--                         dense_rank() OVER (ORDER BY branch, sub) as branch,
--                         move_id,
--                         move_count,
--                     FROM (
--                         SELECT
--                             any_value(depth) as depth, 
--                             id, branch, sub,
--                             move_id,
--                             sum(move_count) as move_count,
--                         FROM explode
--                         GROUP BY id, branch, sub, move_id
--                     )
--                 )

--             SELECT
--                 any_value(depth) + 1 as depth, 
--                 id, branch,
--                 map_from_entries(list((move_id, move_count)))::MAP(VARCHAR, UBIGINT) as moves
--             FROM collect
--             WHERE depth < 25
--             GROUP BY id, branch
--         ),
--         frequenciesss AS (
--             WITH
--                 explode AS (
--                     SELECT
--                         f.depth, f.id, f.branch,
--                         m.branch as sub,
--                         m.pos as pos,
--                         coalesce(m.move_id, '*') as move_id,
--                         value as move_count,
--                     FROM (
--                         SELECT 
--                             depth, id, branch,
--                             unnest(map_entries(moves), recursive := true),
--                         FROM frequenciess
--                     ) f
--                     LEFT JOIN dirpad_lookup m ON m.id = key
--                 ),
--                 collect AS (
--                     SELECT
--                         depth,
--                         id,
--                         dense_rank() OVER (ORDER BY branch, sub) as branch,
--                         move_id,
--                         move_count,
--                     FROM (
--                         SELECT
--                             any_value(depth) as depth, 
--                             id, branch, sub,
--                             move_id,
--                             sum(move_count) as move_count,
--                         FROM explode
--                         GROUP BY id, branch, sub, move_id
--                     )
--                 )

--             from explode

--             -- SELECT
--             --     any_value(depth) + 1 as depth, 
--             --     id, branch,
--             --     map_from_entries(list((move_id, move_count)))::MAP(VARCHAR, UBIGINT) as moves
--             -- FROM collect
--             -- WHERE depth < 25
--             -- GROUP BY id, branch
--         ),
--         frequenciessss AS (
--             WITH
--                 explode AS (
--                     SELECT
--                         f.depth, f.id, f.branch,
--                         m.branch as sub,
--                         coalesce(m.move_id, '*') as move_id,
--                         value as move_count,
--                     FROM (
--                         SELECT 
--                             depth, id, branch,
--                             unnest(map_entries(moves), recursive := true),
--                         FROM frequenciesss
--                     ) f
--                     LEFT JOIN dirpad_lookup m ON m.id = key
--                 ),
--                 collect AS (
--                     SELECT
--                         depth,
--                         id,
--                         dense_rank() OVER (ORDER BY branch, sub) as branch,
--                         move_id,
--                         move_count,
--                     FROM (
--                         SELECT
--                             any_value(depth) as depth, 
--                             id, branch, sub,
--                             move_id,
--                             sum(move_count) as move_count,
--                         FROM explode
--                         GROUP BY id, branch, sub, move_id
--                     )
--                 )

--             SELECT
--                 any_value(depth) + 1 as depth, 
--                 id, branch,
--                 map_from_entries(list((move_id, move_count)))::MAP(VARCHAR, UBIGINT) as moves
--             FROM collect
--             WHERE depth < 25
--             GROUP BY id, branch
--         )


--     FROM frequenciesss
--     -- order by id, branch
--     order by id, branch, sub, pos
--     ;


--     FROM frequencies
--     UNION ALL
--     FROM frequenciess
--     UNION ALL
--     FROM frequenciesss
--     UNION ALL
--     FROM frequenciessss
--     ;

-- )


-- -- Different dirpad lookup table with fewer columns and follow-up moves not being unnested
-- DROP TYPE IF EXISTS PAIR;
-- CREATE TYPE PAIR AS STRUCT(a VARCHAR, b VARCHAR);
-- CREATE OR REPLACE TABLE dir_lookup AS (
--     WITH RECURSIVE
--         path_ids AS (
--             SELECT
--                 row_number() OVER () as id,
--                 (a, b)::PAIR as path,
--             FROM 
--                 unnest(['<', '^', '>', 'v', 'A']) a(a),
--                 unnest(['<', '^', '>', 'v', 'A']) b(b)
--             WHERE a != b
--         ),
--         paths AS (
--             SELECT
--                 d1 as from_button,
--                 d2 as to_button,
--                 [d1] as path,
--                 [move] as moves,
--             FROM dirpad
--             UNION ALL
--             SELECT
--                 p.from_button,
--                 d.d2 as to_button,
--                 list_append(p.path, p.to_button) as path,
--                 list_append(p.moves, d.move) as moves,
--             FROM paths p
--             JOIN dirpad d ON d.d1 = p.to_button
--             WHERE NOT EXISTS (
--                 FROM paths pp
--                 WHERE pp.from_button = p.from_button AND d.d2 IN pp.path
--             )
--         ),
--         paths_lookup AS (
--             SELECT
--                 p.id,
--                 any_value(p.path) as path,
--                 p.branch,
--                 list(p.meta_path ORDER BY pos) as meta_paths,
--                 list(coalesce(m.id, 0)) as meta_path_ids,
--                 any_value(p.length) as length,
--             FROM (
--                 SELECT
--                     i.id,
--                     i.path as path,
--                     row_number() OVER (PARTITION BY id) as branch,
--                     unnest(list_zip(
--                         list_prepend('A', moves),
--                         list_append(moves, 'A')
--                     )::PAIR[]) as meta_path,
--                     unnest(generate_series(1, len(p.moves) + 1)) as pos,
--                     len(p.moves) + 1 as length,
--                 FROM paths p
--                 JOIN path_ids i ON i.path = (from_button, to_button)
--             ) p
--             LEFT JOIN path_ids m ON m.path = p.meta_path
--             GROUP BY p.id, p.branch
--         )

--     SELECT
--         id,
--         path.a AS d1,
--         path.b AS d2,
--         path,
--         branch,
--         meta_path_ids,
--         meta_paths,
--         length
--     FROM paths_lookup
-- );

-- -- Ideal moves stolen from reddit
-- -- '<': { 'A': '>>^', 'v': '>', '^': '>^', '>': '>>', },
-- -- 'A': { '^': '<', '>': 'v', '<': 'v<<', 'v': '<v', },
-- -- '>': { 'A': '^', 'v': '<', '^': '<^', '<': '<<', },
-- -- '^': { 'A': '>', 'v': 'v', '>': 'v>', '<': 'v<', },
-- -- 'v': { 'A': '^>', '^': '^', '>': '>', '<': '<', },
-- -- 
-- -- Handwritten lookup for ideal moves. Still way to high for part 2.
-- -- deep_dirpaths must be faulty even without branching...
-- CREATE OR REPLACE TABLE dir_lookup AS (
--     SELECT
--         id, d1, d2,
--         (d1, d2)::PAIR as path,
--         1 as branch,
--         moves as meta_path_ids,
--         -- NULL::PAIR[] as meta_paths,
--         len(moves) as length,
--     FROM (VALUES
--         (1, '<', '>', [10, 0, 6]),
--         (2, '<', 'A', [10, 0, 7, 15]),
--         (3, '<', '^', [10, 7, 15]),
--         (4, '<', 'v', [10, 6]),

--         (5, '>', '<', [9, 0, 2]),
--         (6, '>', 'A', [11, 15]),
--         (7, '>', '^', [9, 3, 15]),
--         (8, '>', 'v', [9, 2]),

--         ( 9, 'A', '<', [12, 17, 0, 2]),
--         (10, 'A', '>', [12, 19]),
--         (11, 'A', '^', [9, 2]),
--         (12, 'A', 'v', [9, 4, 19]),

--         (13, '^', '<', [12, 17, 2]),
--         (14, '^', '>', [12, 17, 2]),
--         (15, '^', 'A', [10, 6]),
--         (16, '^', 'v', [12, 19]),

--         (17, 'v', '<', [9, 2]),
--         (18, 'v', '>', [10, 6]),
--         (19, 'v', 'A', [11, 14, 6]),
--         (20, 'v', '^', [11, 15]),
--     ) _(id, d1, d2, moves)
-- );

-- -- First attempt to count how often a move is done at depth X for every dirpad combination
-- -- Takes around ~4 minutes to run, works for Part 1 but Part 2 is way to high
-- -- I'm pretty sure some branches are being collected together but shouldn't be so the values explode
-- -- Kind of functional approach to handle the histogram unnesting/aggregation even with branching by
-- -- keeping only the paths with the same size of each iteration
-- -- Also probably some error how repeating buttons are handled 
-- CREATE OR REPLACE TABLE deep_dirpaths AS (
--     WITH RECURSIVE
--         dir_id_lookup AS (
--             SELECT distinct id, d1 || d2 as symbol FROM dir_lookup
--         ),
--         tracked_lookup AS (
--             SELECT
--                 row_number() OVER (ORDER BY id, branch) as drill_id,
--                 id,
--                 d1, d2,
--                 meta_path_ids,
--             FROM dir_lookup
--         ),
--         deep_dirpaths AS (
--             SELECT
--                 1 as depth,
--                 drill_id,
--                 id,
--                 list_histogram(meta_path_ids)::MAP(INTEGER, HUGEINT) as hist,
--             FROM tracked_lookup
--             -- delete me
--             -- WHERE id = 5 OR id = 3
--             -- WHERE id = 17
--             --   AND branch = 1
--             UNION ALL (
--         -- ),
--         -- deep_dirpathss AS (
--                 WITH RECURSIVE
--                     explode AS (
--                         SELECT
--                             * EXCLUDE (key, value),
--                             key as meta_id,
--                             value as meta_count,
--                         FROM (
--                             SELECT
--                                 depth, drill_id, id,
--                                 unnest(generate_series(1, cardinality(hist)::INTEGER)) as pos,
--                                 unnest(map_entries(hist), recursive := true),
--                                 cardinality(hist)::INTEGER as length,
--                             FROM deep_dirpaths
--                         )
--                     ),
--                     supercede AS (
--                         SELECT
--                             any_value(depth) as depth,
--                             drill_id, id, branch, pos,
--                             map_from_entries(list((meta_id, meta_count)))::MAP(INTEGER, HUGEINT) as hist,
--                             any_value(length) as length,
--                         FROM (
--                             SELECT
--                                 any_value(depth) as depth,
--                                 drill_id, id, pos, branch,
--                                 meta_id,
--                                 sum(meta_count) as meta_count,
--                                 any_value(length) as length,
--                             FROM (
--                                 SELECT
--                                     e.depth, e.drill_id, e.id, e.pos,
--                                     unnest(if(l.id IS NOT NULL, l.meta_path_ids, [0])) as meta_id,
--                                     e.meta_count,
--                                     coalesce(l.branch, 1) as branch,
--                                     e.length,
--                                 FROM explode e
--                                 LEFT JOIN dir_lookup l ON l.id = e.meta_id
--                             )
--                             GROUP BY drill_id, id, pos, branch, meta_id
--                         ) GROUP BY drill_id, id, pos, branch
--                     ),
--                     collect AS (
--                         SELECT
--                             depth, drill_id, id, pos,
--                             0 as branch,
--                             hist, length,
--                             -- [hist] as hist, length,
--                         FROM supercede
--                         WHERE pos = 1
--                         -- UNION ALL
--                         -- SELECT
--                         --     c.depth, c.drill_id, c.id, s.pos,
--                         --     row_number() OVER (PARTITION BY drill_id, id) as branch,
--                         --     c.hist || [s.hist],
--                         --     c.length,
--                         -- FROM collect c
--                         -- JOIN supercede s USING (drill_id, id)
--                         -- WHERE s.pos = c.pos + 1
--                         ------------------------------------------------------------
--                         UNION ALL (
--                             WITH
--                                 explode AS (
--                                     SELECT
--                                         c.depth, c.drill_id, c.id, s.pos,
--                                         row_number() OVER (PARTITION BY drill_id, id) as branch,
--                                         unnest(
--                                             [map_entries(c.hist), map_entries(s.hist)],
--                                             recursive := true
--                                         ),
--                                         c.length,
--                                     FROM collect c
--                                     JOIN supercede s USING (drill_id, id)
--                                     WHERE s.pos = c.pos + 1
--                                 )

--                             -- collect
--                             SELECT
--                                 any_value(depth) as depth,
--                                 drill_id, id,
--                                 any_value(pos) as pos,
--                                 branch,
--                                 map_from_entries(list((meta_id, meta_count)))::MAP(INTEGER, HUGEINT) as hist,
--                                 any_value(length) as length,
--                             FROM (
--                                 SELECT
--                                     any_value(depth) as depth,
--                                     drill_id, id, branch,
--                                     any_value(pos) as pos,
--                                     key as meta_id,
--                                     sum(value) as meta_count,
--                                     any_value(length) as length,
--                                 FROM explode
--                                 GROUP BY drill_id, id, branch, key
--                             )
--                             GROUP BY drill_id, id, branch
--                         )
--                     ),
--                     reduce AS (
--                         SELECT
--                             depth,
--                             drill_id,
--                             id,
--                             hist,
--                             -- list_sum(map_values(hist)) as total,
--                             -- row_number() OVER (
--                             --     PARTITION BY drill_id, id, total
--                             --     ORDER BY total
--                             -- ) as rank,
--                             -- row_number() OVER (
--                             --     PARTITION BY drill_id, id
--                             --     ORDER BY list_sum(map_values(hist))
--                             -- ) as rank,
--                             list_sum(map_values(hist)) as total,
--                             hist[0] as repetitions,
--                             rank() OVER (PARTITION BY id ORDER BY total, repetitions) as rank,
--                         FROM collect
--                         WHERE pos = length
--                         QUALIFY rank = 1
--                     )

--                 SELECT
--                     depth + 1 as depth,
--                     drill_id,
--                     id,
--                     hist,
--                 FROM reduce
--                 WHERE depth < 25
--                 -- WHERE depth < 3
--             )
--         )

--     SELECT
--         depth,
--         id,
--         d1,
--         d2,
--         hist,
--     FROM deep_dirpaths
--     JOIN dir_lookup USING (id)
-- );

-- -- Builds sequences from shortest paths in deep_dirpaths for depths 2 and 25
-- CREATE OR REPLACE VIEW sequences AS (
--     WITH RECURSIVE
--         numpresses AS (
--             SELECT
--                 id, pos,
--                 n1, n2,
--                 moves,
--                 length,
--             FROM (
--                 SELECT
--                     id,
--                     generate_subscripts(code, 1) as pos,
--                     unnest(list_prepend('A', code[:-2])) as n1,
--                     unnest(code) as n2,
--                     len(code) as length,
--                 FROM codes
--                 -- delete me
--                 -- WHERE id = 1
--             )
--             JOIN numpaths USING (n1, n2)
--         ),
--         num_pathfinder AS (
--             SELECT
--                 id, pos,
--                 n1, n2,
--                 moves,
--                 length,
--             FROM numpresses
--             WHERE pos = 1
--             UNION ALL
--             SELECT
--                 p.id, n.pos,
--                 n.n1, n.n2,
--                 p.moves || n.moves as moves,
--                 p.length
--             FROM num_pathfinder p
--             JOIN numpresses n ON n.id = p.id AND n.pos = p.pos + 1
--         ),
--         num_paths AS (
--             FROM num_pathfinder
--             WHERE pos = length
--         ),
--         shortest_dirpaths AS (
--             SELECT
--                 *,
--                 list_sum(map_values(hist)) as total,
--                 row_number() OVER (PARTITION BY depth, id ORDER BY total) as rank,
--             FROM deep_dirpaths
--             QUALIFY rank = 1
--         ),
--         dirpresses AS (
--             SELECT
--                 code_id, path_id,
--                 unnest(if(depth IS NOT NULL, [depth], [2, 25])) as depth,
--                 pos, d1, d2,
--                 coalesce(hist, MAP {0: 1}) as hist,
--                 length,
--             FROM (
--                 SELECT
--                     id as code_id,
--                     row_number() OVER (PARTITION BY id) as path_id,
--                     generate_subscripts(moves, 1) as pos,
--                     unnest(list_prepend('A', moves[:-2])) as d1,
--                     unnest(moves) as d2,
--                     len(moves) as length,
--                 FROM num_paths
--                 -- delete me
--                 -- QUALIFY path_id = 1
--             )
--             LEFT JOIN shortest_dirpaths USING (d1, d2)
--             WHERE depth IS NULL OR depth = 2  -- part 1
--                                 OR depth = 25 -- part 2
--         ),
--         dir_pathfinder AS (
--             SELECT
--                 code_id, path_id, depth,
--                 pos, d1, d2,
--                 hist,
--                 length,
--             FROM dirpresses
--             WHERE pos = 1
--             UNION ALL (
--                 WITH
--                     explode AS (
--                         SELECT
--                             code_id, path_id, depth,
--                             d.pos, d.d1, d.d2,
--                             unnest(
--                                 [map_entries(p.hist), map_entries(d.hist)],
--                                 recursive := true
--                             ),
--                             p.length,
--                         FROM dir_pathfinder p
--                         JOIN dirpresses d USING (code_id, path_id, depth)
--                         WHERE d.pos = p.pos + 1
--                     )

--                 -- collect
--                 SELECT
--                     code_id, path_id, depth,
--                     any_value(pos) as pos,
--                     any_value(d1) as d1,
--                     any_value(d2) as d2,
--                     map_from_entries(list((key, value))) as hist,
--                     any_value(length) as length,
--                 FROM (
--                     SELECT
--                         code_id, path_id, depth,
--                         any_value(pos) as pos,
--                         any_value(d1) as d1,
--                         any_value(d2) as d2,
--                         key,
--                         sum(value) as value,
--                         any_value(length) as length,
--                     FROM explode
--                     -- This assumes no branching
--                     GROUP BY code_id, path_id, depth, key
--                 )
--                 -- This assumes no branching
--                 GROUP BY code_id, path_id, depth
--             )
--         ),
--         dir_paths AS (
--             SELECT
--                 code_id, depth,
--                 length,
--                 row_number() OVER (PARTITION BY code_id, depth ORDER BY length) as rank,
--             FROM (
--                 SELECT
--                     code_id, path_id, depth,
--                     sum(value) as length,
--                 FROM (
--                     SELECT
--                         code_id, path_id, depth,
--                         unnest(map_entries(hist), recursive := true)
--                     FROM dir_pathfinder
--                     WHERE pos = length
--                 )
--                 GROUP BY code_id, path_id, depth
--             )
--             QUALIFY rank = 1
--         )

--     SELECT
--         depth, id, code,
--         value, length,
--         value * length as complexity,
--     FROM dir_paths
--     JOIN codes ON id = code_id
--     ORDER BY code_id
-- );

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

-- -- First attempt to create deeper button sequences from already determined shortest paths of depth 2
-- -- Nothing smart about this, just a lot of unnest/join/aggregate expanding the list of moves with each
-- -- iteration. Runtime and space requirements explode drastically above a depth of 13.
-- -- Building deeper sequences from previous ones (e.g. depth 12 + depth 13 = depth 25) did not work.
-- CREATE OR REPLACE TABLE deep_dirpaths AS (
--     WITH RECURSIVE
--         depth13 AS (
--             SELECT
--                 1 as depth,
--                 d1, d2,
--                 dir2_moves as moves,
--             FROM expanded_dirpaths
--             UNION ALL (
--                 WITH
--                     button_presses AS (
--                         SELECT
--                             depth,
--                             from_d1 as d1, 
--                             to_d2 as d2,
--                             pos,
--                             coalesce(dir2_moves, ['A']) as moves,
--                         FROM (
--                             SELECT
--                                 depth,
--                                 d1 as from_d1,
--                                 d2 as to_d2,
--                                 generate_subscripts(moves, 1) as pos,
--                                 unnest(list_prepend('A', moves[:-2])) as d1,
--                                 unnest(moves) as d2,
--                             FROM depth13
--                         )
--                         LEFT JOIN expanded_dirpaths USING (d1, d2)
--                     )
                
--                 SELECT
--                     any_value(depth) + 1 as depth,
--                     d1, d2,
--                     flatten(list(moves ORDER BY pos)) as moves,
--                 FROM button_presses
--                 WHERE depth < 13
--                 GROUP BY d1, d2
--             )
--         )

--     SELECT
--         depth,
--         d1, d2,
--         list_aggregate(moves, 'string_agg', '') as moves,
--         len(moves) as total,
--     FROM depth13
--     WHERE depth < 4 AND d1 = '<' AND d2 = 'A'
--     ORDER BY d1, d2, depth

-- );


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
        -- sum(complexity) FILTER (depth = 2) as part1,
        -- sum(complexity) FILTER (depth = 25) as part2,
        sum(complexity) as part1,
        NULL as part2,
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
