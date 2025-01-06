CREATE OR REPLACE TABLE table2 AS (
    WITH
        first_cte AS (FROM table1),
        second_cte AS (
            WITH
                inner_cte AS (FROM first_cte),
                second_cte AS (FROM inner_cte)
            
            FROM second_cte
        )

    FROM second_cte
);
