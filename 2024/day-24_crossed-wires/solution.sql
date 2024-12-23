-- SET VARIABLE example = '
--     x00: 1
--     x01: 1
--     x02: 1
--     y00: 0
--     y01: 1
--     y02: 0

--     x00 AND y00 -> z00
--     x01 XOR y01 -> z01
--     x02 OR y02 -> z02
-- ';
-- SET VARIABLE exampleSolution1 = 4; -- 100
-- SET VARIABLE exampleSolution2 = NULL;

SET VARIABLE example = '
    x00: 1
    x01: 0
    x02: 1
    x03: 1
    x04: 0
    y00: 1
    y01: 1
    y02: 1
    y03: 1
    y04: 1

    ntg XOR fgs -> mjb
    y02 OR x01 -> tnw
    kwq OR kpj -> z05
    x00 OR x03 -> fst
    tgd XOR rvg -> z01
    vdt OR tnw -> bfw
    bfw AND frj -> z10
    ffh OR nrd -> bqk
    y00 AND y03 -> djm
    y03 OR y00 -> psh
    bqk OR frj -> z08
    tnw OR fst -> frj
    gnj AND tgd -> z11
    bfw XOR mjb -> z00
    x03 OR x00 -> vdt
    gnj AND wpb -> z02
    x04 AND y00 -> kjc
    djm OR pbm -> qhw
    nrd AND vdt -> hwm
    kjc AND fst -> rvg
    y04 OR y02 -> fgs
    y01 AND x02 -> pbm
    ntg OR kjc -> kwq
    psh XOR fgs -> tgd
    qhw XOR tgd -> z09
    pbm OR djm -> kpj
    x03 XOR y03 -> ffh
    x00 XOR y04 -> ntg
    bfw OR bqk -> z06
    nrd XOR fgs -> wpb
    frj XOR qhw -> z04
    bqk OR frj -> z07
    y03 OR x01 -> nrd
    hwm AND bqk -> z03
    tgd XOR rvg -> z12
    tnw OR pbm -> gnj
';
SET VARIABLE exampleSolution1 = 2024; -- 0011111101000
SET VARIABLE exampleSolution2 = NULL;

-- SET VARIABLE example = '
--     x1: 1
--     x2: 0
--     x3: 1

--     x1 OR x2 -> a
--     x2 AND x3 -> b
--     x1 OR a -> z1
--     a XOR b -> z2
-- ';
-- SET VARIABLE exampleSolution1 = 3; -- 11
-- SET VARIABLE exampleSolution2 = NULL;

-- SET VARIABLE example = '
--     x00: 1
--     x01: 0
--     x02: 1
--     x03: 1
--     y00: 1
--     y01: 0
--     y02: 0
--     y03: 1

--     x00 XOR y00 -> z00
--     y01 XOR x01 -> tdh
--     x00 AND y00 -> gtb
--     x01 AND y01 -> vpp

--     gtb AND tdh -> svv
--     tdh XOR gtb -> z01

--     svv OR vpp -> prf
--     x02 XOR y02 -> dvr
--     x02 AND y02 -> qvc

--     prf XOR dvr -> z02
--     prf AND dvr -> npq

--     npq OR qvc -> ptp
--     y03 XOR x03 -> tcb

--     tcb XOR ptp -> z03
-- ';
-- SET VARIABLE exampleSolution1 = NULL; -- ?
-- SET VARIABLE exampleSolution2 = NULL;

CREATE OR REPLACE VIEW example AS SELECT regexp_split_to_table(trim(getvariable('example'), chr(10) || ' '), '\n\s*') as line;

CREATE OR REPLACE TABLE input AS
SELECT regexp_split_to_table(trim(content, chr(10) || ' '), '\n\s*') as line FROM read_text('input');
SET VARIABLE solution1 = 52038112429798;
SET VARIABLE solution2 = NULL;

.maxrows 75
-- SET VARIABLE mode = 'example';
SET VARIABLE mode = 'input';

CREATE OR REPLACE VIEW connections AS (
    SELECT
        parts[1] as in1,
        parts[3] as in2,
        parts[2] as op,
        parts[5] as node,
    FROM (
        SELECT
            row_number() OVER () as id,
            string_split(line, ' ') as parts,
        FROM query_table(getvariable('mode'))
        WHERE contains(line, '->')
    )
);

CREATE OR REPLACE VIEW initial_values AS (
    SELECT
        parts[1] as node,
        parts[2]::BOOLEAN as active,
    FROM (
        SELECT
            row_number() OVER () as id,
            string_split(line, ': ') as parts,
        FROM query_table(getvariable('mode'))
        WHERE contains(line, ': ')
    )
);

CREATE OR REPLACE VIEW nodes AS (
    SELECT node
    FROM initial_values
    UNION
    SELECT node
    FROM connections
);

-- TODO Can this be done backwards?
-- - Start with output connections (value as additional column)
-- - Calculate values of satisfied records
-- - Collect connections that would satisfy missing inputs
-- - Only keep connections that don't have a value or if their value is input
--   for a connection with missing inputs
-- - Stop when all values are set (which should happen "naturally")
CREATE OR REPLACE VIEW propagate AS (
    WITH RECURSIVE
        final_nodes AS (
            SELECT 
                count() as total,
            FROM nodes
            WHERE node[1] = 'z'
        ),
        propagate AS (
            SELECT 
                0 as it,
                node,
                active,
                false as terminate,
            FROM initial_values
            UNION ALL (
                -- FIXME How the termination condition is handled here is atrocious. Make it simpler
                WITH 
                    fuse AS (
                        SELECT any_value(terminate) FROM propagate
                    ),
                    -- TODO If approach above doesn't work: remove "saturated" values (all connections they're an input for are satisfied)
                    satisfied AS (
                        SELECT
                            c.node,
                            CASE
                                WHEN c.op = 'AND' THEN in1.active AND in2.active
                                WHEN c.op = 'OR' THEN in1.active OR in2.active
                                ELSE /*XOR*/ in1.active != in2.active
                            END as active,
                        FROM connections c, propagate in1, propagate in2
                        WHERE c.in1 = in1.node AND c.in2 = in2.node
                        AND in1.active IS NOT NULL AND in2.active IS NOT NULL
                        AND NOT EXISTS (FROM propagate p WHERE p.node = c.node)
                    ),
                    merged AS (
                        SELECT
                            *,
                            (FROM fuse) as terminate,
                        FROM satisfied
                        UNION ALL
                        SELECT
                            node, active,
                            (FROM fuse) as terminate,
                        FROM propagate
                        WHERE node[1] NOT IN ('x', 'y')
                        UNION ALL
                        SELECT
                            *,
                            (FROM fuse) as terminate,
                        FROM initial_values
                    ),
                    finished AS (
                        SELECT 
                            count() as finished,
                        FROM merged
                        WHERE node[1] = 'z'
                    )
                    
                SELECT
                    (SELECT any_value(it) FROM propagate) + 1 as it,
                    node,
                    active,
                    (FROM finished) = (FROM final_nodes) as terminate
                FROM merged
                WHERE NOT terminate -- FIXME terminates one step too early
                --   AND it < 10
            )
        )

    FROM propagate
    -- WHERE terminate
    -- delete me
    -- ORDER BY it, node
);

-- WITH RECURSIVE
--     propagate AS (
--         SELECT 
--             0 as it,
--             node,
--             active,
--         FROM initial_values
--     ),
--     propagatee AS (
--         WITH 
--             satisfied AS (
--                 SELECT
--                     c.node,
--                     CASE
--                         WHEN c.op = 'AND' THEN in1.active AND in2.active
--                         WHEN c.op = 'OR' THEN in1.active OR in2.active
--                         ELSE /*XOR*/ in1.active != in2.active
--                     END as active,
--                 FROM connections c, propagate in1, propagate in2
--                 WHERE c.in1 = in1.node AND c.in2 = in2.node
--                   AND in1.active IS NOT NULL AND in2.active IS NOT NULL
--                   AND NOT EXISTS (FROM propagate p WHERE p.node = c.node)
--             )
            
--         SELECT
--             (SELECT any_value(it) FROM propagate) + 1 as it,
--             node,
--             active,
--         FROM (
--             FROM satisfied
--             UNION ALL
--             SELECT node, active FROM propagate
--             WHERE node[1] NOT IN ('x', 'y')
--             UNION ALL
--             FROM initial_values
--         )
--     ),
--     propagateee AS (
--         WITH 
--             satisfied AS (
--                 SELECT
--                     c.node,
--                     CASE
--                         WHEN c.op = 'AND' THEN in1.active AND in2.active
--                         WHEN c.op = 'OR' THEN in1.active OR in2.active
--                         ELSE /*XOR*/ in1.active != in2.active
--                     END as active,
--                 FROM connections c, propagatee in1, propagatee in2
--                 WHERE c.in1 = in1.node AND c.in2 = in2.node
--                   AND in1.active IS NOT NULL AND in2.active IS NOT NULL
--                   AND NOT EXISTS (FROM propagatee p WHERE p.node = c.node)
--             )
            
--         SELECT
--             (SELECT any_value(it) FROM propagatee) + 1 as it,
--             node,
--             active,
--         FROM (
--             FROM satisfied
--             UNION ALL
--             SELECT node, active FROM propagatee
--             WHERE node[1] NOT IN ('x', 'y')
--             UNION ALL
--             FROM initial_values
--         )
--     ),
--     propagateeee AS (
--         WITH 
--             satisfied AS (
--                 SELECT
--                     c.node,
--                     CASE
--                         WHEN c.op = 'AND' THEN in1.active AND in2.active
--                         WHEN c.op = 'OR' THEN in1.active OR in2.active
--                         ELSE /*XOR*/ in1.active != in2.active
--                     END as active,
--                 FROM connections c, propagateee in1, propagateee in2
--                 WHERE c.in1 = in1.node AND c.in2 = in2.node
--                   AND in1.active IS NOT NULL AND in2.active IS NOT NULL
--                   AND NOT EXISTS (FROM propagateee p WHERE p.node = c.node)
--             )
            
--         SELECT
--             (SELECT any_value(it) FROM propagateee) + 1 as it,
--             node,
--             active,
--         FROM (
--             FROM satisfied
--             UNION ALL
--             SELECT node, active FROM propagateee
--             WHERE node[1] NOT IN ('x', 'y')
--             UNION ALL
--             FROM initial_values
--         )
--     )

-- FROM propagate
-- UNION ALL
-- FROM propagatee
-- UNION ALL
-- FROM propagateee
-- UNION ALL
-- FROM propagateeee
-- ORDER BY it, node
-- ;


CREATE OR REPLACE VIEW output AS (
    SELECT
        string_agg(active::UTINYINT, '' ORDER BY node desc)::BITSTRING as bits
    FROM (
        SELECT DISTINCT node, active
        FROM propagate
        WHERE starts_with(node, 'z')
    )
);

CREATE OR REPLACE VIEW results AS (
    SELECT
        (SELECT bits::UHUGEINT FROM output) as part1,
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
