WITH
    first_cte AS (FROM foo),
    second_cte AS (FROM first_cte)

FROM second_cte;
