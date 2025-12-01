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
CREATE OR REPLACE VIEW example AS SELECT regexp_split_to_table(trim(getvariable('example'), E'\n '), '\n\s*') as line;
SET VARIABLE exampleSolution1 = 3;
SET VARIABLE exampleSolution2 = NULL;

CREATE OR REPLACE TABLE input AS
FROM read_text('input') SELECT regexp_split_to_table(trim(content, E'\n '), '\n\s*') as line;
SET VARIABLE solution1 = 1081;
SET VARIABLE solution2 = NULL;

.maxrows 75
-- SET VARIABLE mode = 'example';
SET VARIABLE mode = 'input';

CREATE OR REPLACE TABLE rotations AS (
    FROM query_table(getvariable('mode'))
    SELECT
        id: row_number() OVER (),
        direction: line[1],
        distance: line[2:]::INTEGER,
);

CREATE OR REPLACE TABLE positions AS (
    WITH
        relative_positions AS (
            SELECT
                id: 0,
                relative_position: 50
            UNION ALL
            FROM rotations
            SELECT
                id,
                relative_position: if(direction = 'L', -1, 1) * distance,
        ),
        positions AS (
            FROM relative_positions
            SELECT
                id,
                relative_position,
                cumulative_position: sum(relative_position) OVER (ORDER BY id ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW),
                position: cumulative_position % 100
        )

    FROM positions
    SELECT id, position
);

CREATE OR REPLACE VIEW results AS (
    SELECT
        part1: (FROM positions SELECT count(*) WHERE position = 0),
        part2: NULL
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
