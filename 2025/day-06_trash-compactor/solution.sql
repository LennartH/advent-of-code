SET VARIABLE example = '
123 328  51 64 
 45 64  387 23 
  6 98  215 314
*   +   *   +  
';
SET VARIABLE exampleSolution1 = 4277556;
SET VARIABLE exampleSolution2 = 3263827;
CREATE OR REPLACE VIEW example AS SELECT regexp_split_to_table(trim(getvariable('example'), E'\n'), '\n') as line;

CREATE OR REPLACE TABLE input AS
FROM read_text('input') SELECT regexp_split_to_table(trim(content, E'\n '), '\n\s*') as line;
SET VARIABLE solution1 = 7644505810277;
SET VARIABLE solution2 = 12841228084455;

.maxrows 75
SET VARIABLE mode = 'example';
-- SET VARIABLE mode = 'input';

CREATE OR REPLACE TABLE left_to_right_parser AS (
    WITH
        values AS (
            FROM query_table(getvariable('mode'))
            SELECT
                y: row_number() OVER (),
                x: generate_subscripts(string_split_regex(trim(line), '\s+'), 1),
                value: unnest(string_split_regex(trim(line), '\s+')),
        ),
        transposed AS (
            FROM values
            SELECT
                id: x,
                entries: list(value),
            GROUP BY x
        ),
        problems AS (
            FROM transposed
            SELECT
                id,
                operator: entries[-1],
                values: [v::BIGINT FOR v IN entries[:-2]],  -- directly casting the slice causes an error
        )

    FROM problems
    SELECT
        id,
        result: CASE operator
            WHEN '+' THEN list_sum(values)::BIGINT
            WHEN '*' THEN list_product(values)::BIGINT
        END
);

CREATE OR REPLACE TABLE top_to_bottom_parser AS (
    WITH
        symbols AS (
            FROM query_table(getvariable('mode'))
            SELECT
                y: row_number() OVER (),
                x: generate_subscripts(string_split_regex(line, ''), 1),
                symbol: unnest(string_split_regex(line, '')),
        ),
        columns AS (
            FROM symbols
            SELECT
                x,
                value: string_agg(nullif(symbol, ' '), '' ORDER BY y),
            GROUP BY x
        ),
        extract_operator AS (
            FROM columns
            SELECT
                x,
                operator: if(value[-1] IN ('+', '*'), value[-1], NULL),
                value: if(value[-1] IN ('+', '*'), value[:-2], value)::BIGINT,
        ),
        grouped AS (
            FROM extract_operator
            SELECT
                id: 1 + sum(if(value IS NULL, 1, 0)) OVER (ORDER BY x ROWS UNBOUNDED PRECEDING),
                operator,
                value,
            QUALIFY value IS NOT NULL
        ),
        problems AS (
            FROM grouped
            SELECT
                id,
                operator: any_value(operator),
                values: list(value),
            GROUP BY id
        )

    FROM problems
    SELECT
        id,
        result: CASE operator
            WHEN '+' THEN list_sum(values)::BIGINT
            WHEN '*' THEN list_product(values)::BIGINT
        END
);

CREATE OR REPLACE VIEW results AS (
    SELECT
        part1: (FROM left_to_right_parser SELECT sum(result)),
        part2: (FROM top_to_bottom_parser SELECT sum(result)),
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
