SET VARIABLE example = '
    kh-tc
    qp-kh
    de-cg
    ka-co
    yn-aq
    qp-ub
    cg-tb
    vc-aq
    tb-ka
    wh-tc
    yn-cg
    kh-ub
    ta-co
    de-co
    tc-td
    tb-wq
    wh-td
    ta-ka
    td-qp
    aq-cg
    wq-ub
    ub-vc
    de-ta
    wq-aq
    wq-vc
    wh-yn
    ka-de
    kh-ta
    co-tc
    wh-qp
    tb-vc
    td-yn
';
CREATE OR REPLACE VIEW example AS SELECT regexp_split_to_table(trim(getvariable('example'), chr(10) || ' '), '\n\s*') as line;
SET VARIABLE exampleSolution1 = 7;
SET VARIABLE exampleSolution2 = 'co,de,ka,ta';

CREATE OR REPLACE TABLE input AS
SELECT regexp_split_to_table(trim(content, chr(10) || ' '), '\n\s*') as line FROM read_text('input');
SET VARIABLE solution1 = 1184;
SET VARIABLE solution2 = 'hf,hz,lb,lm,ls,my,ps,qu,ra,uc,vi,xz,yv';

.maxrows 75
-- SET VARIABLE mode = 'example';
SET VARIABLE mode = 'input';

CREATE OR REPLACE TABLE edges AS (
    SELECT DISTINCT
        unnest(parts) as n1,
        unnest(list_reverse(parts)) as n2,
        starts_with(n1, 't') OR starts_with(n2, 't') as mark,
    FROM (
        SELECT
            string_split(line, '-') as parts,
        FROM query_table(getvariable('mode'))
    )
);

CREATE OR REPLACE TABLE parties AS (
    SELECT DISTINCT ON (nodes)
        list_sort([e1.n1, e1.n2, e2.n2]) as nodes,
        e1.mark OR e2.mark as mark,
    FROM edges e1, edges e2, edges e3
    WHERE e1.n1 = e2.n1 AND e3.n1 = e1.n2 AND e3.n2 = e2.n2
    ORDER BY nodes
);

CREATE OR REPLACE TABLE largest_party AS (
    WITH RECURSIVE
        largest_party AS (
            SELECT
                row_number() OVER () as id,
                [n1, n2] as nodes,
            FROM edges
            UNION ALL (
                WITH
                    connected AS (
                        SELECT DISTINCT ON (nodes)
                            list_sort(list_append(any_value(p.nodes), e.n1)) as nodes,
                        FROM largest_party p, edges e
                        WHERE e.n1 NOT IN p.nodes AND e.n2 IN p.nodes
                        GROUP BY p.id, e.n1
                        HAVING count() = len(any_value(p.nodes))
                    )

                SELECT
                    row_number() OVER () as id,
                    nodes,
                FROM connected
            )
        )

    FROM largest_party
    ORDER BY len(nodes) desc
    LIMIT 1
);

CREATE OR REPLACE TABLE results AS (
    SELECT
        (SELECT count() FROM parties WHERE mark) as part1,
        (SELECT list_aggregate(nodes, 'string_agg', ',') FROM largest_party) as part2,
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
