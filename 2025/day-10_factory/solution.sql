SET VARIABLE example = '
    [.##.] (3) (1,3) (2) (2,3) (0,2) (0,1) {3,5,4,7}
    [...#.] (0,2,3,4) (2,3) (0,4) (0,1,2) (1,2,3,4) {7,5,12,7,2}
    [.###.#] (0,1,2,3,4) (0,3,4) (0,1,2,4,5) (1,2) {10,11,11,5,10,5}
';
SET VARIABLE exampleSolution1 = 7;
SET VARIABLE exampleSolution2 = NULL;
CREATE OR REPLACE VIEW example AS SELECT regexp_split_to_table(trim(getvariable('example'), E'\n '), '\n\s*') as line;

CREATE OR REPLACE TABLE input AS
FROM read_text('input') SELECT regexp_split_to_table(trim(content, E'\n '), '\n\s*') as line;
SET VARIABLE solution1 = NULL;
SET VARIABLE solution2 = NULL;

.maxrows 75
-- SET VARIABLE mode = 'example';
SET VARIABLE mode = 'input';

CREATE OR REPLACE TABLE machines AS (
    WITH
        parts AS (
            FROM query_table(getvariable('mode'))
            SELECT
                id: row_number() OVER (),
                parts: string_split(line, ' '),
        ),
        step AS (
            FROM parts
            SELECT
                id,
                target_state: replace(replace(parts[1][2:-2], '#', '1'), '.', '0')::BITSTRING,
                schematics: [string_split(p[2:-2], ',')::INTEGER[] FOR p IN parts[2:-2]],
                joltages: string_split(parts[-1][2:-2], ',')::INTEGER[],
        )

    FROM step
    SELECT
        id,
        target_state,
        schematics: [ -- transform button wirings to bitstrings (think about how messy this would be without list comprehensions)
            (list_sum([
                2**(length(target_state) - b - 1) FOR b IN s
            ])::INTEGER::BITSTRING::STRING)[-length(target_state):]::BITSTRING FOR s IN schematics
        ],
        joltages,
);

CREATE OR REPLACE TABLE nodes_superset AS (
    WITH
        enumeration AS (
            FROM machines
            SELECT
                state: unnest(range(0, (2**max(length(target_state)))::INTEGER))
        ),
        state_lengths AS (
            FROM machines
            SELECT DISTINCT
                length: length(target_state)
        )

    FROM enumeration e, state_lengths l
    SELECT
        length,
        state: (state::BITSTRING::STRING)[-length:]::BITSTRING,
    WHERE state < 2**length
);

CREATE OR REPLACE TABLE edges_superset AS (
    WITH
        buttons AS (
            FROM machines
            SELECT
                id,
                button_id: generate_subscripts(schematics, 1),
                button: unnest(schematics),
        )


    FROM buttons b, nodes_superset n
    SELECT
        b.id,
        b.button_id,
        b.button,
        state1: n.state,
        state2: xor(n.state, b.button),
    WHERE
        length(button) = n.length
);

CREATE OR REPLACE VIEW results AS (
    SELECT
        part1: NULL,
        part2: NULL,
);


CREATE OR REPLACE VIEW solution AS (
    FROM results
    SELECT 
            part: 'Part 1',
          result: part1,
        expected: if(getvariable('mode') = 'example', getvariable('exampleSolution1'), getvariable('solution1')),
         correct: result = expected,
    UNION
    FROM results
    SELECT 
            part: 'Part 2',
          result: part2,
        expected: if(getvariable('mode') = 'example', getvariable('exampleSolution2'), getvariable('solution2')),
         correct: result = expected,
    ORDER BY part
);
FROM solution;
