import re
import sys
from textwrap import dedent, indent

cte_matcher = r'(?:\.timer on\s*)?WITH\s+(\w+)\s+AS\s+\(([\s\S]*)\)\s*(SELECT[\s\S]*;)'
cte_splitter = r'\)\s*,\s*(\w+)\s+AS\s+\('

with open(sys.argv[1], 'r') as f:
    content = f.read()

if (match := re.search(cte_matcher, content)) is None:
    print('Whomp whomp')
    sys.exit(1)

first_name, cte, select = match.groups()
parts = re.split(cte_splitter, cte)

replacements = []
for name, query in zip([first_name] + parts[1::2], parts[::2]):
    replacement = f'''
        .print {name}
        CREATE VIEW {name} AS
        {query.strip()};
        SELECT * FROM {name};
    '''
    replacements.append(dedent(replacement))

replacement = f'{''.join(replacements)}\n\n{select}'
transformed = content[:match.start()] + replacement + content[match.end():]
print(transformed)
