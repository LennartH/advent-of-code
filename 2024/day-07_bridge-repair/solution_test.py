import pytest

from pathlib import Path
from .solution import solve_part1, solve_part2

# region Example
example = '''
    190: 10 19
    3267: 81 40 27
    83: 17 5
    156: 15 6
    7290: 6 8 6 15
    161011: 16 10 13
    192: 17 8 14
    21037: 9 7 18 13
    292: 11 6 16 20
'''.strip()
example_solution1 = 3749
example_solution2 = 11387


def test_example_part1():
    result = solve_part1(example)
    assert result == example_solution1, f'Expected {example_solution1 or '?'}, got {result}'


def test_example_part2():
    result = solve_part2(example)
    assert result == example_solution2, f'Expected {example_solution2 or '?'}, got {result}'
# endregion


# region Input
input = Path(__file__).parent.joinpath('input').read_text()
solution1 = 21572148763543
solution2 = 581941094529163


def test_input_part1():
    result = solve_part1(input)
    assert result == solution1, f'Expected {solution1 or '?'}, got {result}'


def test_input_part2():
    result = solve_part2(input)
    assert result == solution2, f'Expected {solution2 or '?'}, got {result}'
# endregion
