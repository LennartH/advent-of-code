SET VARIABLE example = '
    Button A: X+94, Y+34
    Button B: X+22, Y+67
    Prize: X=8400, Y=5400

    Button A: X+26, Y+66
    Button B: X+67, Y+21
    Prize: X=12748, Y=12176

    Button A: X+17, Y+86
    Button B: X+84, Y+37
    Prize: X=7870, Y=6450

    Button A: X+69, Y+23
    Button B: X+27, Y+71
    Prize: X=18641, Y=10279
';
CREATE OR REPLACE VIEW example AS SELECT regexp_split_to_table(trim(getvariable('example'), chr(10) || ' '), '\n\s*\n\s*') as line;
SET VARIABLE exampleSolution1 = 480;
SET VARIABLE exampleSolution2 = 875318608908;

CREATE OR REPLACE TABLE input AS
SELECT regexp_split_to_table(trim(content, chr(10) || ' '), '\n\s*\n\s*') as line FROM read_text('input');
SET VARIABLE solution1 = 36838;
SET VARIABLE solution2 = 83029436920891;

-- SET VARIABLE mode = 'example';
SET VARIABLE mode = 'input';

CREATE OR REPLACE VIEW bad_machines AS (
    WITH 
        parts AS (
            SELECT
                row_number() OVER () as idx,
                string_split_regex(line, '[:,\n]\s*') as parts,
                len(parts) as foo,
            FROM query_table(getvariable('mode'))
        )

    SELECT
        idx,
        parts[2][3:]::BIGINT as adx,
        parts[3][3:]::BIGINT as ady,
        parts[5][3:]::BIGINT as bdx,
        parts[6][3:]::BIGINT as bdy,
        parts[8][3:]::BIGINT as px,
        parts[9][3:]::BIGINT as py,

        0 as a_min,
        100 as a_max,
        0 as b_min,
        100 as b_max,
        a_max - a_min as a_range,
        b_max - b_min as b_range,
    FROM parts
);

CREATE OR REPLACE VIEW machines AS (
    SELECT
        idx, adx, ady, bdx, bdy,
        10000000000000 + px as px,
        10000000000000 + py as py,

        0 as a_min,
        10000000000000 as a_max,
        0 as b_min,
        10000000000000 as b_max,
        10000000000000 as a_range,
        10000000000000 as b_range,
    FROM bad_machines
);

-- -- TODO Fix initial range approximation
-- CREATE OR REPLACE VIEW machine_stats AS (
--     WITH
--         winnable_machines AS (
--             SELECT
--                 *,
--                 least(px // adx, py // ady) as a_max,
--                 least(px // bdx, py // bdy) as b_max,
--             FROM machines
--             -- WHERE (a_max * adx) + (b_max * bdx) >= px AND
--             --       (a_max * ady) + (b_max * bdy) >= py
--         ),
--         button_mins AS (
--             SELECT
--                 *,
--                 ceil(greatest(
--                     (px - (b_max * bdx)) / adx,
--                     (py - (b_max * bdy)) / ady
--                 ))::BIGINT as a_min,
--                 ceil(greatest(
--                     (px - (a_max * adx)) / bdx,
--                     (py - (a_max * ady)) / bdy
--                 ))::BIGINT as b_min,
--                 a_max - a_min as a_range,
--                 b_max - b_min as b_range,
--             FROM winnable_machines
--         )

--     FROM button_mins
-- );

-- TODO Combine approximation and solver macros
CREATE OR REPLACE MACRO approximate(machines, steps, min_range) AS TABLE (
    WITH 
        first_button AS (
            SELECT
                idx, px, py,
                bdx as fdx,
                bdy as fdy,
                adx as sdx,
                ady as sdy,
                if(b_range > min_range, b_range // steps, 1) as step,
                unnest(generate_series(b_max, b_min, -step)) as f,
                true as f_is_b,
            FROM query_table(machines)
            WHERE b_range <= a_range
            UNION ALL
            SELECT
                idx, px, py,
                adx as fdx,
                ady as fdy,
                bdx as sdx,
                bdy as sdy,
                if(a_range > min_range, a_range // steps, 1) as step,
                unnest(generate_series(a_max, a_min, -step)) as f,
                false as f_is_b,
            FROM query_table(machines)
            WHERE a_range < b_range
        ),
        second_button AS (
            SELECT
                idx,
                px - (f * fdx) as rx,
                py - (f * fdy) as ry,
                rx / sdx as div_x,
                ry / sdy as div_y,
                round(abs(div_x - div_y), 3) as error,
                f,
                step,
                f_is_b,
            FROM first_button
        ),
        approximation AS (
            SELECT
                idx,
                min_by(f, error) as f,
                any_value(step) as step,
                min(error) as error,
                any_value(f_is_b) as f_is_b
            FROM second_button
            GROUP BY idx
        )

    SELECT
        *,
        a_max - a_min as a_range,
        b_max - b_min as b_range,
    FROM (
        SELECT
            idx, px, py,
            adx, ady,
            bdx, bdy,

            if(f_is_b, m.a_min, greatest(f - (step // 2), 0)) as a_min,
            if(f_is_b, m.a_max, least(f + (step // 2), 10000000000000)) as a_max,
            if(f_is_b, greatest(f - (step // 2), 0), m.b_min) as b_min,
            if(f_is_b, least(f + (step // 2), 10000000000000), m.b_max) as b_max,
        FROM approximation a
        JOIN machines m USING (idx)
    )
);

CREATE OR REPLACE TABLE approx_step1 AS
    FROM approximate('machines', 100, 5000);
CREATE OR REPLACE TABLE approx_step2 AS
    FROM approximate('approx_step1', 100, 5000);
CREATE OR REPLACE TABLE approx_step3 AS
    FROM approximate('approx_step2', 100, 5000);
CREATE OR REPLACE TABLE approx_step4 AS
    FROM approximate('approx_step3', 100, 5000);
CREATE OR REPLACE TABLE approx_step5 AS
    FROM approximate('approx_step4', 100, 5000);
CREATE OR REPLACE TABLE approx_final AS
    FROM approximate('approx_step5', 100, 5000);


CREATE OR REPLACE MACRO solver(machines) AS TABLE (
    WITH
        first_button AS (
            SELECT
                idx, px, py,
                bdx as fdx,
                bdy as fdy,
                adx as sdx,
                ady as sdy,
                unnest(generate_series(b_max, b_min, -1)) as f,
                true as f_is_b,
            FROM query_table(machines)
            WHERE b_range <= a_range
            UNION ALL
            SELECT
                idx, px, py,
                adx as fdx,
                ady as fdy,
                bdx as sdx,
                bdy as sdy,
                unnest(generate_series(a_max, a_min, -1)) as f,
                false as f_is_b,
            FROM query_table(machines)
            WHERE a_range < b_range
        ),
        second_button AS (
            SELECT
                idx,
                if(f_is_b, sdx, fdx) as adx,
                if(f_is_b, sdy, fdy) as ady,
                if(f_is_b, fdx, sdx) as bdx,
                if(f_is_b, fdy, sdy) as bdy,
                px - (f * fdx) as rx,
                py - (f * fdy) as ry,
                rx / sdx as div_x,
                ry / sdy as div_y,
                round(div_x, 0) = div_x AND round(div_y, 0) = div_y as whole,
                div_x::BIGINT = div_y::BIGINT as same,
                if(f_is_b, div_x::BIGINT, f) as a,
                if(f_is_b, f, div_x::BIGINT) as b,
            FROM first_button
            WHERE whole AND same
        )

    SELECT
        idx, a, b,
        (3 * a) + b as cost,
    FROM second_button
);

CREATE OR REPLACE VIEW results AS (
    SELECT
        (SELECT sum(cost) FROM solver('bad_machines')) as part1,
        (SELECT sum(cost) FROM solver('approx_final')) as part2,
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
