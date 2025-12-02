SET VARIABLE example = '
    11-22,95-115,998-1012,1188511880-1188511890,222220-222224,1698522-1698528,446443-446449,38593856-38593862,565653-565659,824824821-824824827,2121212118-2121212124
';
SET VARIABLE exampleSolution1 = 1227775554;
SET VARIABLE exampleSolution2 = 4174379265;

-- -- challenge input from https://www.reddit.com/r/adventofcode/comments/1pc2h1l/comment/nruor09/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button
-- SET VARIABLE example = '
--     98765432-1234567890,1000000000000000000000000-1500000000000000000000000,988970940900875998011400-1050032916531789321707634,123456789012345678901234567890-234567890123456789012345678901
-- ';
-- SET VARIABLE exampleSolution1 = NULL;  -- last 24 digits: 678017181064742987556396
-- SET VARIABLE exampleSolution2 = NULL;  -- last 24 digits: 566774526871242591557185

CREATE OR REPLACE VIEW example AS SELECT regexp_split_to_table(trim(getvariable('example'), E'\n '), '\n\s*') as line;

CREATE OR REPLACE TABLE input AS
FROM read_text('input') SELECT regexp_split_to_table(trim(content, E'\n '), '\n\s*') as line;
SET VARIABLE solution1 = 24043483400;
SET VARIABLE solution2 = 38262920235;

.maxrows 75
SET VARIABLE mode = 'example';
-- SET VARIABLE mode = 'input';

CREATE OR REPLACE TABLE ranges AS (
    WITH
        input_parts AS (
            FROM query_table(getvariable('mode'))
            SELECT
                parts: string_split(line, ','),
        ),
        range_strings AS (
            FROM input_parts
            SELECT
                    range_id: generate_subscripts(parts, 1),
                range_string: unnest(parts),
        )

    FROM range_strings
    SELECT
        range_id,
           lower: split_part(range_string, '-', 1)::BIGINT,
           upper: split_part(range_string, '-', 2)::BIGINT,
);

CREATE OR REPLACE TABLE invalid_ids AS (
    WITH
        id_base(base) AS (
            SELECT unnest(range(1, 1000000))
        ),
        id_base_with_repetitions(base, repetitions) AS (
            FROM id_base
            SELECT
                base,
                repetitions: unnest(generate_series(2, 12 // len(base::STRING))),
        )

    FROM id_base_with_repetitions
    SELECT
         invalid_id: repeat(base::STRING, repetitions)::BIGINT,
        repetitions,
);

CREATE OR REPLACE TABLE invalid_ids_in_ranges AS (
    FROM ranges
    JOIN invalid_ids ON invalid_id BETWEEN lower AND upper
);

CREATE OR REPLACE VIEW results AS (
    SELECT
        part1: (FROM invalid_ids_in_ranges SELECT sum(invalid_id) WHERE repetitions = 2),
        part2: (FROM invalid_ids_in_ranges SELECT sum(DISTINCT invalid_id)),
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
