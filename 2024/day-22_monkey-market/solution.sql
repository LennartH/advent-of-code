SET VARIABLE example = '
    1
    2
    3
    2024
';
CREATE OR REPLACE VIEW example AS SELECT regexp_split_to_table(trim(getvariable('example'), chr(10) || ' '), '\n\s*') as line;
SET VARIABLE exampleSolution1 = 37990510;
SET VARIABLE exampleSolution2 = 23;

CREATE OR REPLACE TABLE input AS
SELECT regexp_split_to_table(trim(content, chr(10) || ' '), '\n\s*') as line FROM read_text('input');
SET VARIABLE solution1 = 17163502021;
SET VARIABLE solution2 = 1938;

.maxrows 75
-- SET VARIABLE mode = 'example';
SET VARIABLE mode = 'input';

CREATE OR REPLACE TABLE buyers AS (
    SELECT
        row_number() OVER () as id,
        line::BIGINT as secret,
    FROM query_table(getvariable('mode'))
);

CREATE OR REPLACE TABLE random_number_generator AS (
    WITH RECURSIVE
        rng AS (
            SELECT
                0 as it,
                id,
                secret,
            FROM buyers
            UNION ALL
            SELECT
                it + 1 as it,
                id,
                secret,
            FROM (
                SELECT
                    it,
                    id,
                    -- (secret XOR (secret * 64)) % 16777216
                    xor(secret, secret << 6) & 16777215 as step1,
                    -- (secret XOR (secret // 32)) % 16777216
                    xor(step1, step1 >> 5) & 16777215 as step2,
                    -- (secret XOR (secret * 2048)) % 16777216
                    xor(step2, step2 << 11) & 16777215 as secret,
                FROM rng
            )
            WHERE it < 2000
        )

    FROM rng
);

CREATE OR REPLACE TABLE price_optimizer AS (
    WITH
        price_data AS (
            SELECT
                *,
                list(delta) OVER (PARTITION BY id ORDER BY it ROWS 3 PRECEDING) as seq,
            FROM (
                SELECT
                    it,
                    id,
                    secret,
                    secret % 10 as price,
                    price - lag(price) OVER (PARTITION BY id ORDER BY it) as delta,
                FROM random_number_generator
            )
        )

    SELECT
        seq,
        sum(price) as total,
    FROM (
        SELECT
            id,
            first(price ORDER BY it) as price,
            seq,
        FROM price_data
        WHERE it > 3
        GROUP BY id, seq
    )
    GROUP BY seq
    ORDER BY total desc
);

CREATE OR REPLACE VIEW results AS (
    SELECT
        (SELECT sum(secret) FROM random_number_generator WHERE it = 2000) as part1,
        (SELECT max(total) FROM price_optimizer) as part2,
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
