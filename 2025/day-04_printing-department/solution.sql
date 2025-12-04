SET VARIABLE example = '
  ..@@.@@@@.
  @@@.@.@.@@
  @@@@@.@.@@
  @.@@@@..@.
  @@.@@@@.@@
  .@@@@@@@.@
  .@.@.@.@@@
  @.@@@.@@@@
  .@@@@@@@@.
  @.@.@@@.@.
';
SET VARIABLE exampleSolution1 = 13;
SET VARIABLE exampleSolution2 = NULL;
CREATE OR REPLACE VIEW example AS SELECT regexp_split_to_table(trim(getvariable('example'), E'\n '), '\n\s*') as line;

CREATE OR REPLACE TABLE input AS
FROM read_text('input') SELECT regexp_split_to_table(trim(content, E'\n '), '\n\s*') as line;
SET VARIABLE solution1 = 1560;
SET VARIABLE solution2 = NULL;

.maxrows 75
SET VARIABLE mode = 'example';
-- SET VARIABLE mode = 'input';

CREATE OR REPLACE TABLE grid AS (
    FROM query_table(getvariable('mode'))
    SELECT
        y: row_number() OVER (),
        x: generate_subscripts(string_split(line, ''), 1),
        symbol: unnest(string_split(line, '')),
);

CREATE OR REPLACE TABLE accessible_rolls AS (
    WITH
        rolls_with_adjacent_rolls AS (
            FROM grid r
            JOIN grid a ON a.symbol = '@' 
                       AND (a.y = r.y - 1 OR a.y = r.y + 1 OR a.y = r.y)
                       AND (a.x = r.x - 1 OR a.x = r.x + 1 OR a.x = r.x)
                    --    AND NOT (a.y = r.y AND a.x = r.x)  -- FIXME This removes 2 valid results
            SELECT
                r.y, r.x,
                r.symbol,
                ax: a.x,
                ay: a.y,
            WHERE
                r.symbol = '@'
        )
    
    FROM rolls_with_adjacent_rolls
    SELECT
        y, x,
        adjacent_rolls: count(*) - 1,
    GROUP BY ALL
    HAVING
        adjacent_rolls < 4
);

CREATE OR REPLACE VIEW results AS (
    SELECT
        part1: (FROM accessible_rolls SELECT count(*)),
        part2: NULL,
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
