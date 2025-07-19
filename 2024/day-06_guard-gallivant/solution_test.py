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
    .#.x^.....
    ......xx#.
    #x.x......
    ......#x..
'''.strip()
example_solution1 = 41
example_solution2 = 6

# # Example with consecutive obstacles
# example = '''
#     ...#......
#     #.......#.
#     .......#..
#     ...^......
#     ..........
# '''.strip()
# example_solution1 = 10
# example_solution2 = 2

# # Example with multiple obstacles in same line
# example = '''
#     .#.......
#     ....#..#.
#     .........
#     x...#....
#     ...#....#
#     .......x.
#     ....^....
#     #..x.....
#     .......#.
# '''.strip()
# example_solution1 = 27
# example_solution2 = 3

# # Loop when placing obstacle on visited cell
# example = '''
#     .#............
#     ......x......#
#     .^...........#
#     .....#........
#     ............#.
# '''.strip()
# example_solution1 = 23
# example_solution2 = 1

# # Loop between 2 points
# example = '''
#    ......
#    .#..#.
#    .....#
#    .^#x..
#    ....#.
# '''.strip()
# example_solution1 = 9
# example_solution2 = 2

# # Loop outside of original path
# example = '''
#    ............
#    ..x...#.....
#    .........#..
#    .....#......
#    ........#...
#    ..^.........
#    ............
# '''.strip()
# example_solution1 = 6
# example_solution2 = 1

# # Loop without steps in original path
# example = '''
#     .#.........
#     ...........
#     .x.........
#     .........#.
#     ...........
#     #..........
#     ........#..
#     ...........
#     .^.........
#     ...........
# '''.strip()
# example_solution1 = 17
# example_solution2 = 2

# # Encountering obstacle multiple times without loop
# example = '''
#     .............
#     ......#......
#     ..#..........
#     ......x......
#     ...........#.
#     .............
#     .#....^......
#     ..........#..
# '''.strip()
# example_solution1 = 11
# example_solution2 = 0

# # Loop after second obstacle encounter
# example = '''
#     ......#....
#     ..#........
#     ......x....
#     .........#.
#     .#....^....
#     ........#..
#     .#.........
#     .....#.....
# '''.strip()
# example_solution1 = 8
# example_solution2 = 1

# # Loop with wall from original path
# example = '''
#     .#.#.........
#     .......#.....
#     .............
#     #.x.......<..
#     .........#...
#     .#...........
#     ......#.#....
# '''.strip()
# example_solution1 = 27
# example_solution2 = 4


def test_example_part1():
    result = solve_part1(example)
    assert result == example_solution1, f'Expected {example_solution1 or '?'}, got {result}'


def test_example_part2():
    result = solve_part2(example)
    assert result == example_solution2, f'Expected {example_solution2 or '?'}, got {result}'
# endregion


# region Input
input = Path(__file__).parent.joinpath('input').read_text()
solution1 = 4433
solution2 = 1516


def test_input_part1():
    result = solve_part1(input)
    assert result == solution1, f'Expected {solution1 or '?'}, got {result}'


def test_input_part2():
    result = solve_part2(input)
    assert result == solution2, f'Expected {solution2 or '?'}, got {result}'
# endregion
