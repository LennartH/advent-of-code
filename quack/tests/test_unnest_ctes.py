import pytest

from pytest_check import check
from sqlglot import parse_one
from quack.unnest_ctes import unnest_ctes


def test_standalone_cte():
    query = '''
        WITH
            first_cte AS (FROM foo),
            second_cte AS (FROM first_cte)

        FROM second_cte;
    '''
    expression = parse_one(query)

    first_cte, second_cte, select = [e.sql(dialect='duckdb') for e in unnest_ctes(expression, 'cte1')]
    assert first_cte == 'CREATE OR REPLACE VIEW cte1_first_cte AS (SELECT * FROM foo)'
    assert second_cte == 'CREATE OR REPLACE VIEW cte1_second_cte AS (SELECT * FROM cte1_first_cte AS first_cte)'
    assert select == 'SELECT * FROM cte1_second_cte AS second_cte'


def test_simple_table():
    query = '''
        CREATE OR REPLACE TABLE table1 AS (
            WITH
                first_cte AS (FROM foo),
                second_cte AS (FROM first_cte)

            FROM second_cte
        );
    '''
    expression = parse_one(query)

    first_cte, second_cte, create_table = [e.sql(dialect='duckdb') for e in unnest_ctes(expression, 'table1')]
    assert first_cte == 'CREATE OR REPLACE VIEW table1_first_cte AS (SELECT * FROM foo)'
    assert second_cte == 'CREATE OR REPLACE VIEW table1_second_cte AS (SELECT * FROM table1_first_cte AS first_cte)'
    assert create_table == 'CREATE OR REPLACE TABLE table1 AS (SELECT * FROM table1_second_cte AS second_cte)'


def test_nested_ctes():
    query = '''
        WITH
            first_cte AS (FROM foo),
            second_cte AS (
                WITH
                    inner_cte AS (FROM first_cte),
                    second_cte AS (FROM inner_cte)
                
                FROM second_cte
            )

        FROM second_cte
    '''
    expression = parse_one(query)

    first_cte, second_cte_inner_cte, second_cte_second_cte, second_cte, create_table = [e.sql(dialect='duckdb') for e in unnest_ctes(expression, 'cte1')]
    assert first_cte == 'CREATE OR REPLACE VIEW cte1_first_cte AS (SELECT * FROM foo)'
    assert second_cte_inner_cte == 'CREATE OR REPLACE VIEW cte1_inner_cte AS (SELECT * FROM cte1_first_cte AS first_cte)'
    assert second_cte_second_cte == 'CREATE OR REPLACE VIEW cte1_second_cte AS (SELECT * FROM cte1_inner_cte AS inner_cte)'
    assert second_cte == 'CREATE OR REPLACE VIEW cte1_second_cte AS (SELECT * FROM cte1_second_cte AS second_cte)'
    assert create_table == 'SELECT * FROM cte1_second_cte AS second_cte'


# TODO recursive nested and nested recursive
def test_recursive_cte():
    query = '''
        WITH RECURSIVE
            seed AS (FROM foo),
            iter AS (
                FROM seed
                UNION ALL
                FROM iter
            ),
            follow AS (FROM iter)

        FROM follow
    '''
    expression = parse_one(query)

    seed, iter_, follow, select = [e.sql(dialect='duckdb') for e in unnest_ctes(expression, 'cte1')]
    with check:
        assert seed == 'CREATE OR REPLACE VIEW cte1_seed AS (SELECT * FROM foo)'
    with check:
        assert iter_ == 'CREATE OR REPLACE VIEW cte1_iter AS (WITH RECURSIVE iter AS (SELECT * FROM cte1_seed AS seed UNION ALL SELECT * FROM iter) SELECT * FROM iter)'
    with check:
        assert follow == 'CREATE OR REPLACE VIEW cte1_follow AS (SELECT * FROM cte1_iter AS iter)'
    with check:
        assert select == 'SELECT * FROM cte1_follow AS follow'
