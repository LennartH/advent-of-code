SET VARIABLE example = '
    125 17
';
CREATE OR REPLACE VIEW example AS SELECT regexp_split_to_table(trim(getvariable('example'), chr(10) || ' '), '\n\s*') as line;
SET VARIABLE exampleSolution1 = 55312;
SET VARIABLE exampleSolution2 = 65601038650482;

CREATE OR REPLACE TABLE input AS
SELECT regexp_split_to_table(trim(content, chr(10) || ' '), '\n') as line FROM read_text('input');
SET VARIABLE solution1 = 224529;
SET VARIABLE solution2 = 266820198587914;

-- SET VARIABLE mode = 'example';
SET VARIABLE mode = 'input';

CREATE OR REPLACE VIEW pebbles AS (
    SELECT
        unnest(generate_series(1, len(values))) as idx,
        unnest(values) as value,
    FROM (
        SELECT
            cast(regexp_split_to_array(line, ' ') as BIGINT[]) as values
        FROM query_table(getvariable('mode'))
    )
);

CREATE OR REPLACE VIEW blinks AS (
    WITH RECURSIVE
        blinks AS (
            SELECT
                0 as blink,
                p.value,
                1::BIGINT as count,
            FROM pebbles p
            UNION ALL
            SELECT
                any_value(b.blink) as blink,
                b.value as value,
                sum(b.count) as count,
            FROM (
                SELECT
                    b.blink + 1 as blink,
                    unnest(CASE
                        WHEN b.value = 0 THEN [1]
                        WHEN len(b.value::varchar) % 2 = 0 THEN [
                            left(b.value::varchar, len(b.value::varchar) // 2)::BIGINT,
                            right(b.value::varchar, len(b.value::varchar) // 2)::BIGINT
                        ]
                        ELSE [b.value * 2024]
                    END) as value,
                    b.count as count,
                FROM blinks b
                WHERE b.blink < 75
            ) b
            GROUP BY b.value
        )
    FROM blinks
);

CREATE OR REPLACE VIEW solution AS (
    SELECT
        (SELECT sum(count) FROM blinks WHERE blink = 25) as part1,
        (SELECT sum(count) FROM blinks WHERE blink = 75) as part2
);


SELECT 
    'Part 1' as part,
    part1 as result,
    if(getvariable('mode') = 'example', getvariable('exampleSolution1'), getvariable('solution1')) as expected,
    result = expected as correct
FROM solution
UNION
SELECT 
    'Part 2' as part,
    part2 as result,
    if(getvariable('mode') = 'example', getvariable('exampleSolution2'), getvariable('solution2')) as expected,
    result = expected as correct
FROM solution
ORDER BY part;