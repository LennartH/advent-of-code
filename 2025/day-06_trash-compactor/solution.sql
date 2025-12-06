SET VARIABLE example = '
    123 328  51 64 
     45 64  387 23 
      6 98  215 314
    *   +   *   +  
';
SET VARIABLE exampleSolution1 = 4277556;
SET VARIABLE exampleSolution2 = NULL;
CREATE OR REPLACE VIEW example AS SELECT regexp_split_to_table(trim(getvariable('example'), E'\n '), '\n\s*') as line;

CREATE OR REPLACE TABLE input AS
FROM read_text('input') SELECT regexp_split_to_table(trim(content, E'\n '), '\n\s*') as line;
SET VARIABLE solution1 = 7644505810277;
SET VARIABLE solution2 = NULL;

.maxrows 75
SET VARIABLE mode = 'example';
-- SET VARIABLE mode = 'input';

CREATE OR REPLACE TABLE parser AS (
    FROM query_table(getvariable('mode'))
    SELECT
        y: row_number() OVER (),
        x: generate_subscripts(string_split_regex(trim(line), '\s+'), 1),
        value: unnest(string_split_regex(trim(line), '\s+')),
);

CREATE OR REPLACE TABLE worksheet_results AS (
    WITH
        transposed AS (
            FROM parser
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

CREATE OR REPLACE VIEW results AS (
    SELECT
        part1: (FROM worksheet_results SELECT sum(result)),
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
