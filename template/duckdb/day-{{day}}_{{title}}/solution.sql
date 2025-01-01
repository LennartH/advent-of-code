SET VARIABLE example = '

';
CREATE OR REPLACE VIEW example AS SELECT regexp_split_to_table(trim(getvariable('example'), chr(10) || ' '), '\n\s*') as line;
SET VARIABLE exampleSolution1 = NULL;
SET VARIABLE exampleSolution2 = NULL;

CREATE OR REPLACE TABLE input AS
FROM read_text('input') SELECT regexp_split_to_table(trim(content, chr(10) || ' '), '\n\s*') as line;
SET VARIABLE solution1 = NULL;
SET VARIABLE solution2 = NULL;

.maxrows 75
SET VARIABLE mode = 'example';
-- SET VARIABLE mode = 'input';

CREATE OR REPLACE VIEW parser AS (
    FROM query_table(getvariable('mode'))
    SELECT
        row_number() OVER () as idx,
        string_split(line, ' ') as parts,
        cast(string_split(line, ' ') as INTEGER[]) as values
);

-- Do stuff

CREATE OR REPLACE VIEW results AS (
    SELECT
        NULL as part1,
        NULL as part2
);


CREATE OR REPLACE VIEW solution AS (
    FROM results
    SELECT 
        'Part 1' as part,
        part1 as result,
        if(getvariable('mode') = 'example', getvariable('exampleSolution1'), getvariable('solution1')) as expected,
        result = expected as correct
    UNION
    FROM results
    SELECT 
        'Part 2' as part,
        part2 as result,
        if(getvariable('mode') = 'example', getvariable('exampleSolution2'), getvariable('solution2')) as expected,
        result = expected as correct
    ORDER BY part
);
FROM solution;
