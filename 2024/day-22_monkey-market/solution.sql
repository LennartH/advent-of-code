SET VARIABLE example = '
    1
    10
    100
    2024
';
CREATE OR REPLACE VIEW example AS SELECT regexp_split_to_table(trim(getvariable('example'), chr(10) || ' '), '\n\s*') as line;
SET VARIABLE exampleSolution1 = 37327623;
SET VARIABLE exampleSolution2 = NULL;

CREATE OR REPLACE TABLE input AS
SELECT regexp_split_to_table(trim(content, chr(10) || ' '), '\n\s*') as line FROM read_text('input');
SET VARIABLE solution1 = 17163502021;
SET VARIABLE solution2 = NULL;

.maxrows 75
-- SET VARIABLE mode = 'example';
SET VARIABLE mode = 'input';

CREATE OR REPLACE VIEW buyers AS (
    SELECT
        row_number() OVER () as id,
        line::BIGINT as secret,
    FROM query_table(getvariable('mode'))
);

CREATE OR REPLACE VIEW random_number_generator AS (
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
    WHERE it = 2000
);

CREATE OR REPLACE VIEW results AS (
    SELECT
        (SELECT sum(secret) FROM random_number_generator) as part1,
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
