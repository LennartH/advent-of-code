CREATE OR REPLACE TABLE table1 AS (
    WITH
        first_cte AS (FROM foo),
        second_cte AS (FROM first_cte)

    FROM second_cte
);

---------------------------------------------------------

CREATE OR REPLACE VIEW view1 AS (
    WITH
        first_cte AS (FROM foo),
        second_cte AS (FROM first_cte)

    FROM second_cte
);

---------------------------------------------------------

CREATE OR REPLACE TABLE table2 AS (
    WITH
        first_cte AS (FROM table1),
        second_cte AS (
            WITH
                inner_cte AS (FROM view1),
                other_inner_cte AS (FROM foo)
            
            FROM inner_cte
        )

    FROM second_cte
);

---------------------------------------------------------

CREATE OR REPLACE TABLE table3 AS (
    WITH RECURSIVE
        seed AS (FROM foo),
        iter AS (
            FROM seed
            UNION ALL
            FROM iter
        ),
        follow AS (FROM iter)

    FROM follow
);

---------------------------------------------------------

CREATE OR REPLACE VIEW view1 AS (
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
);

---------------------------------------------------------

WITH
    first_cte AS (FROM foo),
    second_cte AS (FROM first_cte)

FROM second_cte;
