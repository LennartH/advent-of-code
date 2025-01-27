import math

from pathlib import Path

# region Types and Globals

# endregion


def solve_part1(input: str) -> int:
    lines = [line.strip() for line in input.splitlines()]
    # TODO implement solution
    return math.nan


def solve_part2(input: str) -> int:
    lines = [line.strip() for line in input.splitlines()]
    # TODO implement solution
    return math.nan


# region Shared Code

# endregion


if __name__ == '__main__':
    input = Path(__file__).parent.joinpath('input').read_text()
    print(f'Part 1: {solve_part1(input)}')
    print(f'Part 2: {solve_part2(input)}')

    # import timeit
    # n = 1000
    # dur = timeit.timeit('solve_part1(input)', number=n, globals=globals())
    # print(f'Part 1: {dur / n:.5f}s (average of {n})')
    # dur = timeit.timeit('solve_part2(input)', number=n, globals=globals())
    # print(f'Part 2: {dur / n:.5f}s (average of {n})')
