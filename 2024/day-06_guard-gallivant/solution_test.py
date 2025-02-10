import pytest

from pathlib import Path
from .solution import solve_part1, solve_part2

# region Example
example = '''
    ....#.....
    .........#
    ..........
    ..#.......
    .......#..
    ..........
    .#..^.....
    ........#.
    #.........
    ......#...
'''.strip()
example_solution1 = 41
example = '''
    ...#......
    #.......#.
    .......#..
    ...^......
    ..........
'''.strip()
example_solution1 = 10
# example = '''
#     ........#....
#     .............
#     .#...........
#     .........#...
#     .^..#........
#     ............#
#     .............
#     .............
#     .......#.....
#     ...#.......#.
#     ........#....
# '''.strip()
# example_solution1 = 40
example_solution2 = None


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
solution1 = 4433
solution2 = None


def test_input_part1():
    result = solve_part1(input)
    assert result == solution1, f'Expected {solution1 or '?'}, got {result}'


@pytest.mark.skip(reason='Part 2 solution not implemented')
def test_input_part2():
    result = solve_part2(input)
    assert result == solution2, f'Expected {solution2 or '?'}, got {result}'
# endregion
