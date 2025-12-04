SET VARIABLE example = '
    987654321111111
    811111111111119
    234234234234278
    818181911112111
';
SET VARIABLE exampleSolution1 = 357;
SET VARIABLE exampleSolution2 = 3121910778619;
CREATE OR REPLACE VIEW example AS SELECT regexp_split_to_table(trim(getvariable('example'), E'\n '), '\n\s*') as line;

CREATE OR REPLACE TABLE input AS
FROM read_text('input') SELECT regexp_split_to_table(trim(content, E'\n '), '\n\s*') as line;
SET VARIABLE solution1 = 17263;
SET VARIABLE solution2 = 170731717900423;

.maxrows 75
SET VARIABLE mode = 'example';
-- SET VARIABLE mode = 'input';

CREATE OR REPLACE TABLE battery_banks AS (
    FROM query_table(getvariable('mode'))
    SELECT
          bank_id: row_number() OVER (),
        batteries: split(line, ''),
);

CREATE OR REPLACE TABLE largest_bank_joltages AS (
    WITH RECURSIVE
        largest_sequence AS (
            FROM (
                FROM battery_banks
                SELECT
                             bank_id,
                           batteries,
                        battery_from: 1,
                    battery_sequence: []::STRING[],
                           remaining: 2,
                      used_batteries: 2,
                UNION ALL
                FROM battery_banks
                SELECT
                             bank_id,
                           batteries,
                        battery_from: 1,
                    battery_sequence: []::STRING[],
                           remaining: 12,
                      used_batteries: 12,
            )
            UNION ALL
            FROM (
                FROM largest_sequence
                SELECT
                             bank_id, batteries,
                       battery_count: length(batteries),
                           remaining: remaining - 1,
                               slice: batteries[battery_from : battery_count - remaining + 1],
                    largest_in_slice: list_max(slice),
                        battery_from: list_indexof(slice, largest_in_slice) + battery_from,
                    battery_sequence: list_append(battery_sequence, largest_in_slice),
                      used_batteries,
            )
            SELECT
                bank_id,
                batteries, 
                battery_from, 
                battery_sequence, 
                remaining, 
                used_batteries,
            WHERE
                remaining >= 0
        )
    
    FROM largest_sequence
    SELECT
               bank_id,
               joltage: aggregate(battery_sequence, 'string_agg', '')::BIGINT,
        used_batteries,
    WHERE remaining = 0
);

CREATE OR REPLACE VIEW results AS (
    FROM largest_bank_joltages
    SELECT
        part1: sum(joltage) FILTER (used_batteries = 2),
        part2: sum(joltage) FILTER (used_batteries = 12),
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
