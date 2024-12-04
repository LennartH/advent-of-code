import re
from textwrap import dedent, indent

cte_matcher = r'(\.timer on\s*)?WITH([\s\S]*\))\s*(SELECT[\s\S]*;)'
cte_splitter = r'(\w+)\s+AS\s+\(([\s\S]+?)\),\n'

with open('/home/lennart/projects/advent-of-code/2024/day-03_mull-it-over/regex_bad.sql', 'r') as f:
    content = f.read()

_, cte, select = re.search(cte_matcher, content).groups()
parts = re.findall(cte_splitter, cte)


replacements = []
for name, query in parts:
    replacement = f'''
.print {name}
CREATE VIEW {name} AS
{indent(dedent(query).strip(), '    ')};
SELECT * FROM {name};
    '''
    replacements.append(replacement.strip())

replacement = f'{"\n\n".join(replacements)}\n\n{select}'
print(re.sub(cte_matcher, replacement, content))
