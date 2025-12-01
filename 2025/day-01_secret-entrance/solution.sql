SET VARIABLE example = '
    L68
    L30
    R48
    L5
    R60
    L55
    L1
    L99
    R14
    L82
';
SET VARIABLE exampleSolution1 = 3;
SET VARIABLE exampleSolution2 = 6;

-- SET VARIABLE example = '
--     R50
--     L50
--     L50
--     R50
--     R50
--     R100
-- ';
-- SET VARIABLE exampleSolution1 = 4;
-- SET VARIABLE exampleSolution2 = 4;

-- SET VARIABLE example = '
--     L68
--     L30
--     R48 
--     L5 
--     R60 
--     L55 
--     L1 
--     L99 
--     R14 
--     L82 
--     R427 
--     L340 
--     L75 
--     R82 
--     L2 
--     R76 
--     L80 
--     R226 
--     R74 
--     R80 
--     L13 
--     R113 
--     L128 
--     R75 
--     R47 
--     R6 
--     L350
-- ';
-- SET VARIABLE exampleSolution1 = 7;
-- SET VARIABLE exampleSolution2 = 28;

CREATE OR REPLACE VIEW example AS SELECT regexp_split_to_table(trim(getvariable('example'), E'\n '), '\n\s*') as line;

CREATE OR REPLACE TABLE input AS
FROM read_text('input') SELECT regexp_split_to_table(trim(content, E'\n '), '\n\s*') as line;
SET VARIABLE solution1 = 1081;
SET VARIABLE solution2 = 6689;

.maxrows 75
SET VARIABLE mode = 'example';
-- SET VARIABLE mode = 'input';

CREATE OR REPLACE TABLE rotations AS (
    FROM query_table(getvariable('mode'))
    SELECT
               id: row_number() OVER (),
        direction: line[1],
         distance: line[2:]::INTEGER,
);

CREATE OR REPLACE TABLE positions AS (
    WITH
        cumulative_positions AS (
            SELECT
                                 id: 0,
                           rotation: 0,
                cumulative_position: 50,
            UNION ALL
            FROM rotations
            SELECT
                                 id,
                           rotation: if(direction = 'L', -1, 1) * distance,
                cumulative_position: 50 + sum(rotation) OVER (ORDER BY id ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW),
        ),
        positions AS (
            FROM cumulative_positions
            SELECT
                                 id,
                           rotation,
                cumulative_position,
                           position: (cumulative_position % 100 + 100) % 100,
                  previous_position: lag(position, 1, 0) OVER (ORDER BY id ROWS BETWEEN 1 PRECEDING AND CURRENT ROW),
            QUALIFY
                id > 0
        ),
        positions_with_zero_visits AS (
            FROM positions
            SELECT
                id,
                previous_position,
                rotation,
                position,
                -- makes calculation of zero_visits work in either direction
                visits_helper: abs(rotation) + if(rotation < 0 AND previous_position != 0, 100 - previous_position, previous_position),
                  zero_visits: visits_helper // 100,
        )

    FROM positions_with_zero_visits
    SELECT id, position, zero_visits
);

CREATE OR REPLACE VIEW results AS (
    SELECT
        part1: (FROM positions SELECT count(*) WHERE position = 0),
        part2: (FROM positions SELECT sum(zero_visits)),
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
