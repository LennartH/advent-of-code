import pytest

from pathlib import Path
from .solution import solve_part1, solve_part2

# region Example
example = '''
    MMMSXXMASM
    MSAMXMSMSA
    AMXSXMAAMM
    MSAMASMSMX
    XMASAMXAMM
    XXAMMXXAMA
    SMSMSASXSS
    SAXAMASAAA
    MAMMMXMMMM
    MXMXAXMASX
'''.strip()
example_solution1 = 18
example_solution2 = 9


def test_example_part1():
    result = solve_part1(example)
    assert result == example_solution1, f'Expected {example_solution1 or '?'}, got {result}'


@pytest.mark.skip(reason='Part 2 solution not implemented')
def test_example_part2():
    result = solve_part2(example)
    assert result == example_solution2, f'Expected {example_solution2 or '?'}, got {result}'
# endregion


# region Input
input = Path(__file__).parent.joinpath('input').read_text()
solution1 = 2633
solution2 = 1936


def test_input_part1():
    result = solve_part1(input)
    assert result == solution1, f'Expected {solution1 or '?'}, got {result}'


@pytest.mark.skip(reason='Part 2 solution not implemented')
def test_input_part2():
    result = solve_part2(input)
    assert result == solution2, f'Expected {solution2 or '?'}, got {result}'
# endregion
