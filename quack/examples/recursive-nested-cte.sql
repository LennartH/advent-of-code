WITH RECURSIVE
    seed AS (FROM foo),
    iter AS (
        FROM seed
        UNION ALL (
            WITH
                first_cte AS (FROM iter),
                second_cte AS (FROM first_cte)

            FROM second_cte
        )
    ),
    follow AS (FROM iter)

FROM follow