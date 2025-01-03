SET VARIABLE example = '
    190: 10 19
    3267: 81 40 27
    83: 17 5
    156: 15 6
    7290: 6 8 6 15
    161011: 16 10 13
    192: 17 8 14
    21037: 9 7 18 13
    292: 11 6 16 20
';
CREATE OR REPLACE VIEW example AS SELECT regexp_split_to_table(trim(getvariable('example'), chr(10) || ' '), '\n\s*') as line;
SET VARIABLE exampleSolution1 = 3749;
SET VARIABLE exampleSolution2 = 11387;

CREATE OR REPLACE TABLE input AS
SELECT regexp_split_to_table(trim(content, chr(10) || ' '), '\n\s*') as line FROM read_text('input');
SET VARIABLE solution1 = 21572148763543;
SET VARIABLE solution2 = 581941094529163;

.maxrows 75
-- SET VARIABLE mode = 'example';
SET VARIABLE mode = 'input';

CREATE OR REPLACE TABLE calibrations AS (
    FROM query_table(getvariable('mode'))
    SELECT
        split_part(line, ':', 1)::BIGINT as target,
        string_split(split_part(line, ': ', 2), ' ')::INTEGER[] as operands,
        len(operands) as length,
);

CREATE OR REPLACE TABLE calculations AS (
    WITH RECURSIVE
        calculations AS (
            FROM calibrations
            SELECT
                length as ido,
                target,
                operands,
                false as uses_concatenation,
                target as tally,
                false as finished,
            UNION ALL
            FROM (
                -- Addition
                FROM calculations
                SELECT
                    ido, target, operands, finished,
                    uses_concatenation,
                    tally - operands[ido] as next_tally,
                WHERE next_tally > 0
                UNION ALL
                -- Multiplication
                FROM calculations
                SELECT
                    ido, target, operands, finished,
                    uses_concatenation,
                    tally // operands[ido] as next_tally,
                WHERE tally % operands[ido] = 0
                UNION ALL
                -- Concatenation
                FROM (
                    FROM calculations
                    SELECT
                        ido, target, operands, finished,
                        true as uses_concatenation,
                        floor(log10(tally)) + 1 as tally_length,
                        floor(log10(operands[ido])) + 1 as operand_length,
                        -- a**b always returns a DOUBLE, fdiv and fmod prevent subsequent errors
                        fdiv(tally, 10**operand_length) as next_tally,
                    WHERE tally_length > operand_length AND fmod(tally, 10**operand_length) = operands[ido]
                )
                SELECT * EXCLUDE (tally_length, operand_length)
            )
            SELECT
                ido - 1 as ido,
                target,
                operands,
                uses_concatenation,
                next_tally as tally,
                ido = 2 as finished,
            WHERE NOT finished
        )

    FROM calculations
    SELECT 
        target,
        uses_concatenation,
    WHERE finished AND tally = operands[1]
);

CREATE OR REPLACE TABLE results AS (
    FROM calculations
    SELECT
        sum(DISTINCT target) FILTER (NOT uses_concatenation) as part1,
        sum(DISTINCT target) as part2,
);


CREATE OR REPLACE VIEW solution AS (
    FROM results
    SELECT 
        'Part 1' as part,
        part1 as result,
        if(getvariable('mode') = 'example', getvariable('exampleSolution1'), getvariable('solution1')) as expected,
        result = expected as correct
    UNION
    FROM results
    SELECT 
        'Part 2' as part,
        part2 as result,
        if(getvariable('mode') = 'example', getvariable('exampleSolution2'), getvariable('solution2')) as expected,
        result = expected as correct
    ORDER BY part
);
FROM solution;
