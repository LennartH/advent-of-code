SET VARIABLE example = '
    125 17
';
CREATE OR REPLACE VIEW example AS SELECT regexp_split_to_table(trim(getvariable('example'), chr(10) || ' '), '\n\s*') as line;
SET VARIABLE exampleSolution1 = 55312;
SET VARIABLE exampleSolution2 = NULL;

CREATE OR REPLACE TABLE input AS
SELECT regexp_split_to_table(trim(content, chr(10) || ' '), '\n') as line FROM read_text('input');
SET VARIABLE solution1 = 224529;
SET VARIABLE solution2 = NULL;

SET VARIABLE mode = 'example';
-- SET VARIABLE mode = 'input';

CREATE OR REPLACE VIEW pebbles AS (
    SELECT
        unnest(generate_series(1, len(values))) as idx,
        unnest(values) as value,
    FROM (
        SELECT
            cast(regexp_split_to_array(line, ' ') as BIGINT[]) as values
        FROM query_table(getvariable('mode'))
    )
);

CREATE OR REPLACE VIEW blinks AS (
    WITH RECURSIVE
        blinks AS (
            SELECT
                0 as blink,
                idx,
                -- 1 as part,
                value,
            FROM pebbles
            UNION ALL
            SELECT
                blink + 1 as blink,
                idx,
                -- unnest(generate_series(1, if(len(value::varchar) % 2 = 0, 2, 1))) as part,
                unnest(CASE
                    WHEN value < 10 THEN [value]
                    WHEN value = 0 THEN [1]
                    WHEN len(value::varchar) % 2 = 0 THEN [
                        left(value::varchar, len(value::varchar) // 2)::BIGINT,
                        right(value::varchar, len(value::varchar) // 2)::BIGINT
                    ]
                    ELSE [value * 2024]
                END) as value,
            FROM blinks
            -- WHERE blink < 75
            WHERE blink < 25
        )
FROM blinks
);

CREATE OR REPLACE VIEW blinks AS (
      WITH RECURSIVE
          blinks AS (
              SELECT
                  0 as blink,
                  idx,
                  -- 1 as part,
                  value,
              FROM pebbles
              UNION ALL
              SELECT
                  blink + 1 as blink,
                  idx,
                  -- unnest(generate_series(1, if(len(value::varchar) % 2 = 0, 2, 1))) as part,
                  unnest(CASE
                      WHEN value < 10 THEN [value]
                      WHEN value = 0 THEN [1]
                      WHEN len(value::varchar) % 2 = 0 THEN [
                          left(value::varchar, len(value::varchar) // 2)::BIGINT,
                          right(value::varchar, len(value::varchar) // 2)::BIGINT
                      ]
                      ELSE [value * 2024]
                  END) as value,
              FROM blinks
              -- WHERE blink < 75
              WHERE blink < 25
          )
  FROM blinks
  );

--   SET VARIABLE example = list_aggregate([2024 * 2, 2024 * 3, 2024 * 4, 2024 * 5, 2024 * 6, 2024 * 7, 2024 * 8, 2024 * 9], 'string_agg', ' ');

-- CREATE OR REPLACE VIEW blinks AS (
--       WITH RECURSIVE
--           blinks AS (
--               SELECT
--                   0 as blink,
--                   idx,
--                   -- 1 as part,
--                   value,
--               FROM pebbles
--               UNION ALL
--               SELECT
--                   blink + 1 as blink,
--                   idx,
--                   -- unnest(generate_series(1, if(len(value::varchar) % 2 = 0, 2, 1))) as part,
--                   unnest(CASE
--                       WHEN value < 10 THEN [value]
--                       WHEN value = 0 THEN [1]
--                       WHEN len(value::varchar) % 2 = 0 THEN [
--                           left(value::varchar, len(value::varchar) // 2)::BIGINT,
--                           right(value::varchar, len(value::varchar) // 2)::BIGINT
--                       ]
--                       ELSE [value * 2024]
--                   END) as value,
--               FROM blinks
--               -- WHERE blink < 75
--               WHERE blink < 25 AND blinks.value > 9
--           )
--   FROM blinks
--   );

-- SELECT b.idx, p.value // 2024 as origin, blinks, b.pebbles
--   FROM (
--   SELECT idx, max(blink) as blinks, first(pebbles ORDER BY blink desc) as pebbles FROM (
--     SELECT b.idx, b.blink, list(b.value) as pebbles
--     FROM blinks b 
--     GROUP BY b.idx, b.blink 
--     ORDER BY b.blink desc, b.idx
--   )
--   GROUP BY idx
--   ) b
--   JOIN pebbles p USING (idx)
--   ORDER BY idx
--   ;


CREATE OR REPLACE VIEW solution AS (
    SELECT
        (SELECT count() FROM blinks WHERE blink = 25) as part1,
        (SELECT count() FROM blinks WHERE blink = 75) as part2
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
PREPARE print_blinks AS
SELECT
    blink,
    string_agg(value, ' ') as pebbles,
FROM blinks
WHERE $1 IS NULL OR $1 = 0 OR blink <= $1
GROUP BY blink
ORDER BY blink;
-- endregion