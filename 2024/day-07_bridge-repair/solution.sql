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
CREATE OR REPLACE TABLE example AS SELECT regexp_split_to_table(trim(getvariable('example'), E'\n '), '\n\s*') as line;
SET VARIABLE exampleSolution1 = 3749;
SET VARIABLE exampleSolution2 = NULL;

CREATE OR REPLACE TABLE input AS
SELECT regexp_split_to_table(trim(content, E'\n '), '\n') as line FROM read_text('input');
SET VARIABLE solution1 = 21572148763543;
SET VARIABLE solution2 = NULL;

SET VARIABLE mode = 'input'; -- example or input

CREATE OR REPLACE VIEW calibrations AS (
    SELECT
        idx,
        expected,
        string_split(operands, ' ')::BIGINT[] as operands,
    FROM (
        SELECT
            row_number() OVER () as idx,
            string_split(line, ':')[1]::BIGINT as expected,
            string_split(line, ':')[2].trim() as operands,
        FROM query_table(getvariable('mode'))
    )
);

CREATE OR REPLACE VIEW calculations AS (
WITH RECURSIVE
    calculations AS (
        SELECT
            idx, 
            2 as ido,
            expected,
            operands,
            []::varchar[] as operators,
            operands[1] as result,
            false as finished,
        FROM calibrations
        UNION ALL
        SELECT
            idx,
            ido + 1 as ido,
            expected,
            operands,
            unnest([
                array_append(operators, '+'),
                array_append(operators, '*')
            ]) as operators,
            unnest([
                result + operands[ido],
                result * operands[ido]
            ]) as result,
            ido = len(operands) as finished,
        FROM calculations
        WHERE ido <= len(operands)
    )
SELECT
    * EXCLUDE (ido, finished),
    result = expected as correct,
FROM calculations
WHERE finished);

CREATE OR REPLACE VIEW solution AS (
    SELECT
        (SELECT sum(DISTINCT result) FROM calculations WHERE correct) as part1,
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