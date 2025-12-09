SET VARIABLE example = '
    162,817,812
    57,618,57
    906,360,560
    592,479,940
    352,342,300
    466,668,158
    542,29,236
    431,825,988
    739,650,466
    52,470,668
    216,146,977
    819,987,18
    117,168,530
    805,96,715
    346,949,466
    970,615,88
    941,993,340
    862,61,35
    984,92,344
    425,690,689
';
SET VARIABLE exampleConnections = 10;
SET VARIABLE exampleSolution1 = 40;
SET VARIABLE exampleSolution2 = 25272;
CREATE OR REPLACE VIEW example AS SELECT regexp_split_to_table(trim(getvariable('example'), E'\n '), '\n\s*') as line;

CREATE OR REPLACE TABLE input AS
FROM read_text('input') SELECT regexp_split_to_table(trim(content, E'\n '), '\n\s*') as line;
SET VARIABLE inputConnections = 1000;
SET VARIABLE solution1 = 46398;
SET VARIABLE solution2 = NULL;

.maxrows 75
-- SET VARIABLE mode = 'example';
SET VARIABLE mode = 'input';
SET VARIABLE part1Connections = if(
    getvariable('mode') = 'example',
    getvariable('exampleConnections'),
    getvariable('inputConnections')
);

CREATE OR REPLACE TABLE junction_boxes AS (
    FROM query_table(getvariable('mode'))
    SELECT
              id: row_number() OVER (),
        position: string_split(line, ',')::INT[],
);

-- TODO prune to only keep necessary closest connections?
-- TODO duplicate edges for more efficient joins?
CREATE OR REPLACE TABLE junction_box_distances AS (
    FROM junction_boxes j1
    JOIN junction_boxes j2 ON j1.id < j2.id
    SELECT
              j1_id: j1.id,
              j2_id: j2.id,
           distance: list_distance(j1.position, j2.position),
    ORDER BY distance ASC
);

CREATE OR REPLACE TABLE part1_edges AS (
    FROM junction_box_distances
    LIMIT getvariable('part1Connections')
);

CREATE OR REPLACE TABLE part1_connected_boxes AS (
    WITH RECURSIVE
        connected_junction_boxes(id, component) USING KEY (id) AS (
            FROM junction_boxes
            SELECT
                id,
                component: id,
            UNION 
            FROM recurring.connected_junction_boxes j1
            JOIN recurring.connected_junction_boxes j2 ON j2.component < j1.component
            JOIN part1_edges e ON (e.j1_id, e.j2_id) = (j1.id, j2.id) OR (e.j1_id, e.j2_id) = (j2.id, j1.id)
            SELECT
                       id: j1.id,
                component: min(j2.component),
            GROUP BY j1.id
        )

    FROM connected_junction_boxes
);

CREATE OR REPLACE TABLE circuit_sizes AS (
    FROM part1_connected_boxes
    SELECT
        component,
             size: count(*),
    GROUP BY component
);

-- FIXME takes ages and doesn't yield the last 2 connected boxes
--  ^-- "iterate" over closest connections instead of BFS?
CREATE OR REPLACE TABLE part2_connected_boxes AS (
    WITH RECURSIVE
        connected_junction_boxes(id, component) USING KEY (id) AS (
            FROM junction_boxes
            SELECT
                id,
                component: id,
            UNION 
            FROM recurring.connected_junction_boxes j1
            JOIN recurring.connected_junction_boxes j2 ON j2.component < j1.component
            JOIN junction_box_distances e ON (e.j1_id, e.j2_id) = (j1.id, j2.id) OR (e.j1_id, e.j2_id) = (j2.id, j1.id)
            SELECT
                       id: j1.id,
                component: min(j2.component),
            GROUP BY j1.id
        )

    FROM connected_junction_boxes
);

CREATE OR REPLACE VIEW results AS (
    WITH
        largest_circuits AS (
            FROM circuit_sizes
            ORDER BY size DESC
            LIMIT 3
        )

    SELECT
        part1: (FROM largest_circuits SELECT product(size)::BIGINT),
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
