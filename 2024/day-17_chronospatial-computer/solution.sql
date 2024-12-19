SET VARIABLE example = '
    Register A: 729
    Register B: 0
    Register C: 0

    Program: 0,1,5,4,3,0
';
SET VARIABLE exampleSolution1 = '4,6,3,5,6,3,5,2,1,0';
SET VARIABLE exampleSolution2 = NULL;

-- SET VARIABLE example = '
--     Register A: 10
--     Register B: 0
--     Register C: 0

--     Program: 5,0,5,1,5,4
-- ';
-- SET VARIABLE exampleSolution1 = '0,1,2';
-- SET VARIABLE exampleSolution2 = NULL;


CREATE OR REPLACE VIEW example AS SELECT regexp_split_to_table(trim(getvariable('example'), chr(10) || ' '), '\n\s*') as line;

CREATE OR REPLACE TABLE input AS
SELECT regexp_split_to_table(trim(content, chr(10) || ' '), '\n') as line FROM read_text('input');
SET VARIABLE solution1 = '1,5,0,5,2,0,1,3,5';
SET VARIABLE solution2 = NULL;

-- SET VARIABLE mode = 'example';
SET VARIABLE mode = 'input';

CREATE OR REPLACE VIEW register AS (
    SELECT
        string_split(lines[1], ': ')[2]::INTEGER as a,
        string_split(lines[2], ': ')[2]::INTEGER as b,
        string_split(lines[3], ': ')[2]::INTEGER as c,
    FROM (
        SELECT
            list(line) as lines,
        FROM query_table(getvariable('mode'))
    )
);

CREATE OR REPLACE VIEW instructions AS (
    WITH
        instructions AS (
            SELECT
                generate_subscripts(instructions, 1) - 1 as line_no,
                unnest(instructions) as instruction,
            FROM (
                SELECT
                    string_split(
                        string_split(last(line), ': ')[2],
                        ','
                    )::INTEGER[] as instructions,
                FROM query_table(getvariable('mode'))
            )
        ),
        opcodes AS (
            SELECT
                line_no as ptr,
                instruction as opcode,
                ['adv', 'bxl', 'bst', 'jnz', 'bxc', 'out', 'bdv', 'cdv'][opcode + 1] as op,
            FROM instructions
            WHERE line_no % 2 = 0
        ),
        operands AS (
            SELECT
                instruction as operand,
            FROM instructions
            WHERE line_no % 2 = 1
        )

    FROM opcodes
    POSITIONAL JOIN operands
);

CREATE OR REPLACE VIEW exe AS (
    WITH RECURSIVE
        exe AS (
            SELECT
                0 as it,
                r.a, r.b, r.c,
                0 as ptr,
                NULL as opcode,
                NULL::VARCHAR as op,
                NULL as operand,
                NULL as combo_operand,
                NULL::VARCHAR as out,
            UNION ALL (
                WITH
                    combo_operand AS (
                        SELECT 
                            i.ptr, i.opcode, i.op, i.operand,
                            CASE
                                WHEN i.operand = 4 THEN e.a
                                WHEN i.operand = 5 THEN e.b
                                WHEN i.operand = 6 THEN e.c
                                ELSE i.operand
                            END as combo_operand
                        FROM exe e, (FROM instructions i WHERE i.ptr = e.ptr) i
                    ),
                    op_result AS (
                        SELECT
                            i.opcode, i.op, i.operand, i.combo_operand,
                            -- Register A
                            CASE
                                WHEN i.op = 'adv' THEN e.a >> i.combo_operand
                                ELSE e.a
                            END as a,
                            -- Register B
                            CASE
                                WHEN i.op = 'bxl' THEN xor(e.b, i.operand)
                                WHEN i.op = 'bst' THEN i.combo_operand & 7 -- 0b111
                                WHEN i.op = 'bxc' THEN xor(e.b, e.c)
                                WHEN i.op = 'bdv' THEN e.a >> i.combo_operand
                                ELSE e.b
                            END as b,
                            -- Register C
                            CASE
                                WHEN i.op = 'cdv' THEN e.a >> i.combo_operand
                                ELSE e.c
                            END as c,
                            -- Output
                            CASE
                                WHEN i.op = 'out' THEN i.combo_operand & 7 -- 0b111
                                ELSE NULL
                            END as out,
                            -- Pointer
                            CASE
                                WHEN i.op = 'jnz' AND e.a != 0 THEN i.operand
                                ELSE e.ptr + 2
                            END as ptr,
                        FROM exe e, combo_operand i
                    )

                SELECT
                    e.it + 1 as it,
                    r.a, r.b, r.c,
                    r.ptr, r.opcode, r.op, r.operand,
                    r.combo_operand,
                    r.out,
                FROM exe e, op_result r
                WHERE r.ptr IS NOT NULL
            )
        )
    
    FROM exe
);

CREATE OR REPLACE VIEW results AS (
    SELECT
        (SELECT string_agg(out, ',' ORDER BY it) FROM exe) as part1,
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
CREATE OR REPLACE MACRO memdump() AS TABLE (
    SELECT
        it,
        CASE
            WHEN op = 'adv' THEN format('{:b} >> {:d} -> A', a, operand)
            WHEN op = 'bdv' THEN format('{:b} >> {:d} -> B', a, operand)
            WHEN op = 'cdv' THEN format('{:b} >> {:d} -> C', a, operand)
            WHEN op = 'bxl' THEN format('{:b} ^ {:b} -> B', b, operand)
            WHEN op = 'bst' THEN format('{:b} & {:b} -> B', operand, 7)
            WHEN op = 'jnz' AND a != 0 THEN format('jump {:d}', operand)
            WHEN op = 'bxc' THEN format('{:b} ^ {:b} -> B', b, c)
            WHEN op = 'out' THEN format('{:b} & {:b} | stdout', operand, 7)
            ELSE ''
        END as explain,
        format('{0:d}: {0:b}', a) as a,
        format('{0:d}: {0:b}', b) as b,
        format('{0:d}: {0:b}', c) as c,
        if(ptr NOT IN (SELECT ptr FROM instructions), 'EOF', ptr::VARCHAR) as ptr,
        opcode,
        op,
        format('{0:d}: {0:b}', operand) as operand,
        CASE
            WHEN op IN ('adv', 'bdv', 'cdv', 'bst', 'out') THEN
                'combo (' || CASE
                    WHEN operand = 4 THEN 'A'
                    WHEN operand = 5 THEN 'B'
                    WHEN operand = 6 THEN 'C'
                    ELSE operand::VARCHAR
                END || ')'
            WHEN op IS NULL THEN NULL
            ELSE 'literal'
        END as optype,
    FROM (
        SELECT
            * EXCLUDE (operand, combo_operand),
            CASE
                WHEN op IN ('adv', 'bdv', 'cdv', 'bst', 'out') THEN combo_operand
                WHEN op = 'bxc' THEN NULL
                ELSE operand
            END as operand,
        FROM (
            SELECT
                e.it, e.a, e.b, e.c, e.ptr,
                nxt.opcode, nxt.op,
                nxt.operand, nxt.combo_operand,
            FROM exe e
            LEFT JOIN exe nxt ON nxt.it = e.it + 1
        )
    )
);
-- endregion
