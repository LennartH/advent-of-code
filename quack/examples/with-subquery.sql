WITH
    first_cte AS (FROM foo),
    has_subquery AS (
        FROM (FROM first_cte) foo, (SELECT 'bar' as b) bar
    )

FROM has_subquery;
