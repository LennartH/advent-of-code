SET VARIABLE example = '
    5,4
    4,2
    4,5
    3,0
    2,1
    6,3
    2,4
    1,5
    0,6
    3,3
    2,6
    5,1
    1,2
    5,5
    2,5
    6,5
    1,4
    0,4
    6,4
    1,1
    6,1
    1,0
    0,5
    1,6
    2,0
';
CREATE OR REPLACE VIEW example AS SELECT regexp_split_to_table(trim(getvariable('example'), chr(10) || ' '), '\n\s*') as line;

CREATE OR REPLACE VIEW example_config AS (
    SELECT
        6 as max_coord,
        12 as bytes_part1,
        0 as start_id,
        ((max_coord + 1)**2 - 1)::INTEGER as end_id,
);

SET VARIABLE exampleSolution1 = 22;
SET VARIABLE exampleSolution2 = NULL;


CREATE OR REPLACE TABLE input AS
SELECT regexp_split_to_table(trim(content, chr(10) || ' '), '\n') as line FROM read_text('input');

CREATE OR REPLACE TABLE input_config AS (
    SELECT
        70 as max_coord,
        1024 as bytes_part1,
        0 as start_id,
        ((max_coord + 1)**2 - 1)::INTEGER as end_id,
);

SET VARIABLE solution1 = 292;
SET VARIABLE solution2 = NULL;


-- SET VARIABLE mode = 'example';
SET VARIABLE mode = 'input';

CREATE OR REPLACE TABLE config AS (
    FROM query_table(if(getvariable('mode') = 'example', 'example_config', 'input_config'))
);

CREATE OR REPLACE TABLE memory AS (
    SELECT
        y,
        unnest(generate_series(0, max_coord)) as x,
        (y * (max_coord + 1)) + x as id,
    FROM (
        SELECT
            unnest(generate_series(0, max_coord)) as y,
            max_coord,
        FROM config
    )
);

CREATE OR REPLACE TABLE bytes AS (
    SELECT
        pos,
        values[2] as y,
        values[1] as x,
        (y * (max_coord + 1)) + x as id,
    FROM config, (
        SELECT
            row_number() OVER () as pos,
            cast(regexp_split_to_array(line, ',') as INTEGER[]) as values
        FROM query_table(getvariable('mode'))
    )
);

CREATE OR REPLACE TABLE edges AS (
    WITH
        fallen_bytes AS (
            SELECT 
                bytes.* 
            FROM bytes, config WHERE pos <= bytes_part1
        ),
        corrupted_memory AS (
            SELECT
                m.*,
                EXISTS (FROM fallen_bytes b WHERE b.id = m.id) as corrupted,
            FROM memory m
        ),
        edges AS (
            SELECT
                f.id as from,
                t.id as to,
                abs(c.max_coord - t.x) + abs(c.max_coord - t.y) as distance,
            FROM corrupted_memory f, corrupted_memory t, config c
            WHERE NOT t.corrupted AND NOT f.corrupted AND abs(f.x - t.x) + abs(f.y - t.y) = 1
        )

    FROM edges
);

CREATE OR REPLACE TABLE pathfinder AS (
    WITH RECURSIVE
        paths AS (
            SELECT
                0 as it,
                0 as id,
                [] as path,
                false as terminate,
            UNION ALL
            FROM (
                SELECT DISTINCT ON (id, len(path))
                    p.it + 1 as it,
                    e.to as id,
                    list_prepend(p.id, p.path) as path,
                    bool_or(e.to = c.end_id) OVER () as terminate,
                FROM paths p, config c
                JOIN edges e ON e.from = p.id
                WHERE NOT p.terminate
                ORDER BY e.distance
                LIMIT 100
            ) p
            WHERE NOT EXISTS (FROM paths pp WHERE p.id IN pp.path)
        )

    SELECT
        it, id, path,
        len(path) as length,
    FROM paths, config
    WHERE id = end_id
);

CREATE OR REPLACE VIEW results AS (
    SELECT
        (SELECT min(length) FROM pathfinder) as part1,
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

-- region Troubleshooting Utils
CREATE OR REPLACE MACRO print_corrupted_bytes() AS TABLE (
    WITH
        fallen_bytes AS (
            FROM bytes WHERE pos <= (SELECT bytes_part1 FROM config)
        )

    SELECT
        y,
        string_agg(symbol, ' ' ORDER BY x) as line,
    FROM (
        SELECT
            m.y, m.x,
            if(b.id IS NOT NULL, '#', '.') as symbol,
        FROM memory m
        LEFT JOIN fallen_bytes b USING (id)
    )
    GROUP BY y
    ORDER BY y
);

CREATE OR REPLACE MACRO print_path() AS TABLE (
    WITH
        fallen_bytes AS (
            FROM bytes WHERE pos <= (SELECT bytes_part1 FROM config)
        ),
        path AS (
            SELECT
                unnest(min_by(path, length)) as id,
            FROM pathfinder
        )

    SELECT
        y,
        string_agg(symbol, ' ' ORDER BY x) as line,
    FROM (
        SELECT
            m.y, m.x,
            CASE
                WHEN b.id IS NOT NULL THEN '#'
                WHEN p.id IS NOT NULL THEN 'O'
                WHEN m.id = (SELECT end_id FROM config) THEN 'E'
                ELSE '.'
            END as symbol,
        FROM memory m
        LEFT JOIN fallen_bytes b USING (id)
        LEFT JOIN path p USING (id)
    )
    GROUP BY y
    ORDER BY y
);
--