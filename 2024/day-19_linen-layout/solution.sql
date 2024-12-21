SET VARIABLE example = '
    r, wr, b, g, bwu, rb, gb, br

    brwrr
    bggr
    gbbr
    rrbgbr
    ubwu
    bwurrg
    brgr
    bbrgwb
';
CREATE OR REPLACE VIEW example AS SELECT regexp_split_to_table(trim(getvariable('example'), chr(10) || ' '), '\n\s*') as line;
SET VARIABLE exampleSolution1 = 6;
SET VARIABLE exampleSolution2 = NULL;

CREATE OR REPLACE TABLE input AS
SELECT regexp_split_to_table(trim(content, chr(10) || ' '), '\n\s*') as line FROM read_text('input');
SET VARIABLE solution1 = 255;
SET VARIABLE solution2 = NULL;

SET VARIABLE mode = 'example';
SET VARIABLE mode = 'input';

CREATE OR REPLACE TABLE patterns AS (
    SELECT
        generate_subscripts(patterns, 1) as idx,
        unnest(patterns) as pattern,
    FROM (
        SELECT
            string_split(line, ', ') as patterns,
        FROM query_table(getvariable('mode'))
        LIMIT 1
    )
);

CREATE OR REPLACE TABLE designs AS (
    SELECT
        row_number() OVER () - 1 as idx,
        line as design,
    FROM query_table(getvariable('mode'))
    OFFSET 1
);

CREATE OR REPLACE TABLE arrangements AS (
    WITH RECURSIVE
        arrangements AS (
            SELECT
                0 as it,
                [idx] as design,
                design as remaining,
            FROM designs
            UNION ALL
            SELECT
                any_value(it) as it,
                list_distinct(flatten(list(design))) as design,
                remaining,
            FROM (
                SELECT
                    a.it + 1 as it,
                    a.design,
                    a.remaining[len(p.pattern) + 1:] as remaining,
                FROM arrangements a, patterns p
                WHERE starts_with(a.remaining, p.pattern)
            )
            GROUP BY remaining
        )

    SELECT
        unnest(design) as design,
    FROM arrangements
    WHERE remaining = ''
);

-- CREATE OR REPLACE TABLE foo AS (
--     SELECT
--         design,
--         count() as count,
--     FROM arrangements
--     GROUP BY design
-- );
-- FROM foo;

CREATE OR REPLACE VIEW results AS (
    SELECT
        (SELECT count(DISTINCT design) FROM arrangements) as part1,
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
