WITH RECURSIVE
    seed AS (FROM foo),
    iter AS (
        FROM seed
        UNION ALL (
            WITH RECURSIVE
                first_cte AS (FROM iter),
                second_cte AS (
                    FROM first_cte
                    UNION ALL
                    FROM second_cte
                )

            FROM second_cte
        )
    ),
    follow AS (FROM iter)

FROM follow