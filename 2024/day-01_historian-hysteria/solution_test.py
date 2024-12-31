import pytest

from pathlib import Path
from .solution import solve_part1, solve_part2

# region Example
example = '''
    3   4
    4   3
    2   5
    1   3
    3   9
    3   3
'''.strip()
example_solution1 = 11
example_solution2 = 31


def test_example_part1():
    result = solve_part1(example)
    assert result == example_solution1, f'Expected {example_solution1 or '?'}, got {result}'


def test_example_part2():
    result = solve_part2(example)
    assert result == example_solution2, f'Expected {example_solution2 or '?'}, got {result}'
# endregion


# region Input
input = Path(__file__).parent.joinpath('input').read_text()
solution1 = 1873376
solution2 = 18997088


def test_input_part1():
    result = solve_part1(input)
    assert result == solution1, f'Expected {solution1 or '?'}, got {result}'


def test_input_part2():
    result = solve_part2(input)
    assert result == solution2, f'Expected {solution2 or '?'}, got {result}'
# endregion
