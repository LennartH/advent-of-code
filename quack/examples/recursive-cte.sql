WITH RECURSIVE
    seed AS (FROM foo),
    iter AS (
        FROM seed
        UNION ALL
        FROM iter
    ),
    follow AS (FROM iter)

FROM follow