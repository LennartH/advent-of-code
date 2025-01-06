import sys
import re
import sqlglot
import os

from sqlglot import expressions as exp, parse
from sqlglot.optimizer.scope import Scope, build_scope
from sqlglot.optimizer.qualify import qualify
from sqlglot.optimizer.eliminate_subqueries import eliminate_subqueries
from sqlglot.optimizer.eliminate_ctes import eliminate_ctes


def unnest_ctes(expression: exp.Expression, prefix: str) -> list[exp.Expression]:
    root = build_scope(expression)
    transformed_expressions = []
    if root:
        # TODO resolve name conflicts
        renames = dict()
        with_nodes = set()
        for scope in root.traverse():
            if scope.is_cte:
                # FIXME Handle recursive CTE
                query = scope.expression
                cte_node = query.parent
                with_node = cte_node.parent

                view_name = f'{prefix}_{cte_node.alias}'
                renames[cte_node.alias] = view_name
                transformed_expressions.append(exp.Create(
                    this=exp.Table(this=view_name),
                    kind="VIEW",
                    replace=True,
                    expression=exp.Subquery(this=query),
                ))
                with_nodes.add(with_node)
        
        for table in expression.find_all(exp.Table):
            if (new_name := renames.get(table.name)) is not None:
                renamed_table = exp.alias_(exp.table_(new_name), alias=table.alias_or_name, quoted=True, copy=False)
                table.replace(renamed_table)
        for with_node in with_nodes:
            with_node.pop()

    return transformed_expressions + [expression]


if __name__ == '__main__':
    # input_file = sys.argv[1]
    input_file = '/home/lennart/projects/advent-of-code/quack/examples/2024-day1.sql'
    # input_file = '/home/lennart/projects/advent-of-code/quack/examples/some-ctes.sql'
    # input_file = '/home/lennart/projects/advent-of-code/quack/examples/simple-table.sql'
    # input_file = '/home/lennart/projects/advent-of-code/quack/examples/standalone-cte.sql'
    # input_file = '/home/lennart/projects/advent-of-code/quack/examples/with-subquery.sql'
    # input_file = '/home/lennart/projects/advent-of-code/quack/examples/nested-ctes.sql'
    # input_file = '/home/lennart/projects/advent-of-code/quack/examples/recursive-cte.sql'
    # input_file = '/home/lennart/projects/advent-of-code/quack/examples/recursive-nested-cte.sql'
    # input_file = '/home/lennart/projects/advent-of-code/quack/examples/nested-recursive-cte.sql'
    # output_file = sys.argv[2]
    output_file = '/home/lennart/projects/advent-of-code/quack/out/transformed.sql'

    dot_commands = re.compile(r'^\.\w+.*$', re.MULTILINE)
    with open(input_file, 'r') as f:
        content = dot_commands.sub('', f.read())

    sqlglot.pretty = True
    expressions = sqlglot.parse(content, dialect='duckdb')
    cte_counter = 1
    transformed_expressions = []
    for expression in expressions:
        try:
            name_prefix = expression.this.name if expression.this else None
        except AttributeError:
            name_prefix = None
        if name_prefix is None:
            name_prefix = f'cte{cte_counter}'
            cte_counter += 1
        
        # FIXME qualify breaks FROM query_table(getvariable('mode')) because DuckDB has a bug if query_table is given an alias
        expression = qualify(expression, dialect='duckdb')
        expression = eliminate_subqueries(expression)
        # TODO Make optional (e.g. by magic comment)
        expression = eliminate_ctes(expression)
        # transformed_expressions.append(expression)
        unnested_ctes = unnest_ctes(expression, prefix=name_prefix)
        transformed_expressions.extend(unnested_ctes)
    
    os.makedirs(os.path.dirname(output_file), exist_ok=True)
    with open(output_file, 'w') as f:
        f.write('\n\n'.join(e.sql(dialect='duckdb', indent=4) + ';' for e in transformed_expressions))

