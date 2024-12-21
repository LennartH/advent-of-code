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
SET VARIABLE exampleSolution2 = '6,1';


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
SET VARIABLE solution2 = '58,44';


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
        edges AS (
            SELECT
                f.id as from,
                t.id as to,
                abs(c.max_coord - t.x) + abs(c.max_coord - t.y) as distance,
            FROM memory f, memory t, config c
            WHERE abs(f.x - t.x) + abs(f.y - t.y) = 1
        )

    SELECT
        e.from, e.to,
        min(b.pos) as corrupted_at,
        any_value(distance) as distance,
    FROM edges e
    LEFT JOIN bytes b ON b.id = e.from OR b.id = e.to
    GROUP BY e.from, e.to
);

CREATE OR REPLACE TABLE pathfinder AS (
    WITH RECURSIVE
        edges AS (
            SELECT 
                e.* 
            FROM main.edges e, config c
            WHERE e.corrupted_at IS NULL OR e.corrupted_at > c.bytes_part1
        ),
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
        p.it, p.id, p.path,
        len(p.path) as length,
    FROM paths p, config c
    WHERE p.id = c.end_id
);

CREATE OR REPLACE TABLE pathbreaker AS (
    WITH RECURSIVE
        edges AS (FROM main.edges e),
        pathbreaker AS (
            SELECT
                0 as it,
                (SELECT bytes_part1 FROM config) as lower,
                (count() + (SELECT bytes_part1 FROM config)) // 2 as current,
                count() as upper,
                false as terminate,
            FROM bytes b
            UNION ALL (
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
                            FROM paths p, config c, pathbreaker x
                            JOIN edges e ON e.from = p.id 
                            WHERE NOT p.terminate
                              AND (e.corrupted_at IS NULL OR e.corrupted_at > x.current)
                            ORDER BY e.distance
                            LIMIT 100
                        ) p
                        WHERE NOT EXISTS (FROM paths pp WHERE p.id IN pp.path)
                    ),
                    any_path AS (
                        SELECT EXISTS (FROM paths WHERE terminate) as exists
                    )
                
                SELECT
                    x.it + 1 as it,
                    if(any_path.exists, x.current, x.lower) as lower,
                    (if(any_path.exists, x.upper, x.lower) + x.current) // 2 as current,
                    if(any_path.exists, x.upper, x.current) as upper,
                    x.current = x.lower OR x.current = x.upper as terminate,
                FROM pathbreaker x, any_path
                WHERE NOT terminate
            )
        )

    SELECT
        upper as pos
    FROM pathbreaker
    WHERE terminate
);

CREATE OR REPLACE VIEW results AS (
    SELECT
        (SELECT min(length) FROM pathfinder) as part1,
        (SELECT x || ',' || y FROM bytes JOIN pathbreaker USING (pos)) as part2,
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
CREATE OR REPLACE MACRO print_corrupted_bytes(at_byte) AS TABLE (
    WITH
        fallen_bytes AS (
            FROM bytes WHERE pos <= at_byte
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

CREATE OR REPLACE MACRO print_reachable_tiles(at_byte) AS TABLE (
    WITH
        edges AS (
            FROM main.edges WHERE corrupted_at IS NULL OR corrupted_at > at_byte
        )

    SELECT
        y,
        string_agg(symbol, ' ' ORDER BY x) as line,
    FROM (
        SELECT DISTINCT
            x, y,
            if(e.from IS NOT NULL, '.', '#') as symbol,
        FROM memory m
        LEFT JOIN edges e ON m.id IN (e.from, e.to)
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
-- endregion