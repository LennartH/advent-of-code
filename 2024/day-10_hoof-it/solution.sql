SET VARIABLE example = '
    89010123
    78121874
    87430965
    96549874
    45678903
    32019012
    01329801
    10456732
';
CREATE OR REPLACE VIEW example AS SELECT regexp_split_to_table(trim(getvariable('example'), E'\n '), '\n\s*') as line;
SET VARIABLE exampleSolution1 = 36;
SET VARIABLE exampleSolution2 = 81;

CREATE OR REPLACE TABLE input AS
SELECT regexp_split_to_table(trim(content, E'\n '), '\n') as line FROM read_text('input');
SET VARIABLE solution1 = 841;
SET VARIABLE solution2 = NULL;

-- SET VARIABLE mode = 'example';
SET VARIABLE mode = 'input';

CREATE OR REPLACE TABLE topo_map AS (
    SELECT
        row_number() OVER () as idy,
        unnest(generate_series(1, len(line))) as idx,
        unnest(cast(regexp_split_to_array(line, '') as INTEGER[])) as height,
    FROM query_table(getvariable('mode'))
);

CREATE OR REPLACE TABLE trails AS (
    WITH RECURSIVE
        trails AS (
            SELECT
                {'x': idx, 'y': idy} as trailhead,
                idx,
                idy,
                height,
            FROM topo_map
            WHERE height = 0
            UNION ALL
            SELECT
                trailhead,
                m.idx,
                m.idy,
                m.height,
            FROM trails t
            JOIN topo_map m ON m.height = t.height + 1 AND (
                (m.idx = t.idx AND (m.idy = t.idy + 1 OR m.idy = t.idy - 1)) OR
                (m.idy = t.idy AND (m.idx = t.idx + 1 OR m.idx = t.idx - 1))
            )
        )
    
    FROM trails
);

CREATE OR REPLACE TABLE trail_scores AS (
    SELECT
        trailhead,
        count(DISTINCT (idx, idy)) as score,
    FROM trails
    WHERE height = 9
    GROUP BY trailhead
);

CREATE OR REPLACE TABLE trail_ratings AS (
    SELECT
        trailhead,
        count() as rating,
    FROM trails
    WHERE height = 9
    GROUP BY trailhead
);

CREATE OR REPLACE VIEW solution AS (
    SELECT
        (SELECT sum(score) FROM trail_scores) as part1,
        (SELECT sum(rating) FROM trail_ratings) as part2
);


SELECT 
    'Part 1' as part,
    part1 as result,
    if(getvariable('mode') = 'example', getvariable('exampleSolution1'), getvariable('solution1')) as expected,
    result = expected as correct
FROM solution
UNION
SELECT 
    'Part 2' as part,
    part2 as result,
    if(getvariable('mode') = 'example', getvariable('exampleSolution2'), getvariable('solution2')) as expected,
    result = expected as correct
FROM solution
ORDER BY part;

-- region Troubleshooting Utils
PREPARE print_map AS
SELECT
    idy,
    string_agg(height, ' ') as line,
FROM topo_map
GROUP BY idy
ORDER BY idy;
-- endregion