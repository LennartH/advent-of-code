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

CREATE OR REPLACE TABLE batteries AS (
    FROM query_table(getvariable('mode'))
    SELECT
           bank_id: row_number() OVER (),
        battery_id: generate_subscripts(string_split(line, ''), 1),
        battery_value: unnest(string_split(line, ''))::INTEGER,
);

CREATE OR REPLACE TABLE largest_bank_joltages AS (
    WITH
        largest_battery AS (
            FROM batteries
            SELECT
                bank_id,
                largest_battery_id: arg_max(battery_id, battery_value ORDER BY battery_id),
                largest_battery_value: max(battery_value ORDER BY battery_id),
            GROUP BY
                bank_id
        ),
        largest_before_after AS (
            FROM largest_battery l
            LEFT JOIN batteries a ON a.bank_id = l.bank_id AND a.battery_id > l.largest_battery_id
            LEFT JOIN batteries b ON b.bank_id = l.bank_id AND b.battery_id < l.largest_battery_id
            SELECT
                l.bank_id,
                largest_battery_id,
                largest_battery_value,
                largest_battery_value_after: max(a.battery_value),
                largest_battery_value_before: max(b.battery_value),
            GROUP BY ALL
        )

    FROM largest_before_after
    SELECT
        bank_id,
        joltage: 10 * if(largest_battery_value_after IS NULL, largest_battery_value_before, largest_battery_value)
            + if(largest_battery_value_after IS NULL, largest_battery_value, largest_battery_value_after),
);

CREATE OR REPLACE TABLE largest_bank_joltages_safety_override AS (
    WITH RECURSIVE
        banks AS (
            FROM batteries
            SELECT
                bank_id,
                batteries: list(battery_value ORDER BY battery_id),
            GROUP BY ALL
        ),
        largest_sequence AS (
            FROM banks
            SELECT
                *,
                battery_count: length(batteries),
                remaining: 12,
                battery_from: 1,
                largest: []::INTEGER[],
            UNION ALL
            FROM largest_sequence
            SELECT
                bank_id,
                batteries,
                battery_count,
                remaining: remaining - 1,
                battery_from: list_indexOf(
                    batteries[battery_from : battery_count - remaining + 1],
                    list_max(batteries[battery_from : battery_count - remaining + 1])
                ) + battery_from,
                largest: list_append(largest, list_max(batteries[battery_from : battery_count - remaining + 1])),
            WHERE
                remaining > 0
        )
    
    FROM largest_sequence
    SELECT
        bank_id,
        joltage: aggregate(largest, 'string_agg', '')::BIGINT,
    WHERE remaining = 0
);

CREATE OR REPLACE VIEW results AS (
    SELECT
        part1: (FROM largest_bank_joltages SELECT sum(joltage)),
        part2: (FROM largest_bank_joltages_safety_override SELECT sum(joltage)),
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
