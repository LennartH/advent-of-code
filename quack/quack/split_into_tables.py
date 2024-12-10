import sys

from sqlglot import parse_one, parse
from sqlglot.optimizer import optimize

with open(sys.argv[1], 'r') as f:
    content = f.read()

ast = parse(content, dialect="duckdb")

for expr in ast:
    print(repr(expr))
