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
SET VARIABLE exampleSolution2 = 16;

CREATE OR REPLACE TABLE input AS
SELECT regexp_split_to_table(trim(content, chr(10) || ' '), '\n\s*') as line FROM read_text('input');
SET VARIABLE solution1 = 255;
SET VARIABLE solution2 = 621820080273474;

-- SET VARIABLE mode = 'example';
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

-- TODO Can this be done without a map (like day 21)?
CREATE OR REPLACE TABLE arrangements AS (
    WITH RECURSIVE
        arrangements AS (
            SELECT
                0 as it,
                MAP{idx: 1}::MAP(INTEGER, BIGINT) as design_count,
                design as remaining,
            FROM designs
            UNION ALL (
                WITH
                    arrange AS (
                        SELECT
                            it,
                            key as id,
                            value as count,
                            remaining,
                        FROM (
                            SELECT
                                a.it + 1 as it,
                                unnest(map_entries(a.design_count), recursive := true),
                                a.remaining[len(p.pattern) + 1:] as remaining,
                            FROM arrangements a, patterns p
                            WHERE starts_with(a.remaining, p.pattern)
                        )
                    ),
                    design_counts AS (
                        SELECT
                            any_value(it) as it,
                            id,
                            sum(count) as count,
                            remaining,
                        FROM arrange
                        GROUP BY remaining, id
                    )

                SELECT
                    any_value(it) as it,
                    map_from_entries(list((id, count))) as design_count,
                    remaining,
                FROM design_counts
                GROUP BY remaining
            )
        )

    SELECT
        key as id,
        sum(value) as count,
    FROM (
        SELECT
            unnest(map_entries(design_count), recursive := true),
        FROM arrangements
        WHERE remaining = ''
    )
    GROUP BY key
);

CREATE OR REPLACE VIEW results AS (
    SELECT
        count() as part1,
        sum(count) as part2,
    FROM arrangements
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
