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
SET VARIABLE exampleSolution2 = 43;
CREATE OR REPLACE VIEW example AS SELECT regexp_split_to_table(trim(getvariable('example'), E'\n '), '\n\s*') as line;

CREATE OR REPLACE TABLE input AS
FROM read_text('input') SELECT regexp_split_to_table(trim(content, E'\n '), '\n\s*') as line;
SET VARIABLE solution1 = 1560;
SET VARIABLE solution2 = 9609;

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

CREATE OR REPLACE TABLE cleared_grid AS (
    WITH RECURSIVE
        cleared_grid(y, x, symbol, iteration) USING KEY (y, x) AS (
            FROM grid
            SELECT *, 0
            UNION
            FROM (
                FROM recurring.cleared_grid r
                JOIN recurring.cleared_grid a ON abs(r.x - a.x) <= 1 AND abs(r.y - a.y) <= 1
                    -- AND (r.x, r.y) != (a.x, a.y)  -- FIXME This removes 2 valid results
                SELECT
                          r.y, r.x,
                            symbol: r.symbol,
                    adjacent_rolls: count(*) - 1,
                       r.iteration,
                WHERE r.symbol = '@' AND a.symbol = '@'
                GROUP BY ALL
            )
            SELECT
                     y, x,
                -- hacky stuff to track which rolls are removed first (for part 1 solution)
                   symbol: if(adjacent_rolls < 4, '.', symbol),
                iteration: if(adjacent_rolls < 4, iteration + 1, NULL),
            WHERE adjacent_rolls < 4 OR iteration = 0
        )
    
    FROM cleared_grid
    SELECT 
         x, y, symbol, 
        first_removal: iteration = 1
);

CREATE OR REPLACE VIEW results AS (
    SELECT
        part1: (FROM cleared_grid SELECT count(*) WHERE first_removal),
        part2: (FROM grid SELECT count(*) WHERE symbol = '@') - (FROM cleared_grid SELECT count(*) WHERE symbol = '@'),
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
