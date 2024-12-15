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
SET VARIABLE exampleSolution2 = NULL;

CREATE OR REPLACE TABLE input AS
SELECT regexp_split_to_table(trim(content, chr(10) || ' '), '\n\s*\n\s*') as line FROM read_text('input');
SET VARIABLE solution1 = 36838;
SET VARIABLE solution2 = NULL;

-- SET VARIABLE mode = 'example';
SET VARIABLE mode = 'input';

CREATE OR REPLACE VIEW machines AS (
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
        parts[2][3:]::INTEGER as adx,
        parts[3][3:]::INTEGER as ady,
        parts[5][3:]::INTEGER as bdx,
        parts[6][3:]::INTEGER as bdy,
        parts[8][3:]::INTEGER as px,
        parts[9][3:]::INTEGER as py,
    FROM parts
    -- delete me
    ORDER BY idx
);

CREATE OR REPLACE VIEW machine_stats AS (
    WITH
        winnable_machines AS (
            SELECT
                *,
                least(px // adx, py // ady, 100) as a_max,
                least(px // bdx, py // bdy, 100) as b_max,
            FROM machines
            WHERE (a_max * adx) + (b_max * bdx) >= px AND
                  (a_max * ady) + (b_max * bdy) >= py
        ),
        button_mins AS (
            SELECT
                *,
                ceil(greatest(
                    (px - (b_max * bdx)) / adx,
                    (py - (b_max * bdy)) / ady
                ))::INTEGER as a_min,
                ceil(greatest(
                    (px - (a_max * adx)) / bdx,
                    (py - (a_max * ady)) / bdy
                ))::INTEGER as b_min,
            FROM winnable_machines
        )

    FROM button_mins
);

CREATE OR REPLACE VIEW solver AS (
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
            FROM machine_stats
            WHERE b_max - b_min <= a_max - a_min
            UNION ALL
            SELECT
                idx, px, py,
                adx as fdx,
                ady as fdy,
                bdx as sdx,
                bdy as sdy,
                unnest(generate_series(a_max, a_min, -1)) as f,
                false as f_is_b,
            FROM machine_stats
            WHERE a_max - a_min < b_max - b_min
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
                div_x::INTEGER = div_y::INTEGER as same,
                if(f_is_b, div_x::INTEGER, f) as a,
                if(f_is_b, f, div_x::INTEGER) as b,
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
        (SELECT sum(cost) FROM solver) as part1,
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
