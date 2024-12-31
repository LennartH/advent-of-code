import math

from pathlib import Path
from collections import Counter


def solve_part1(input: str) -> int:
    left, right = parse_lists(input)
    left.sort()
    right.sort()
    total_distance = sum(abs(l - r) for l, r in zip(left, right))
    return total_distance


def solve_part2(input: str) -> int:
    left, right = parse_lists(input)
    counts = Counter(right)
    similarity_score = sum(v * counts[v] for v in left)
    return similarity_score


# region Shared Code
def parse_lists(input: str) -> tuple[list[int], list[int]]:
    left, right = zip(*[map(int, line.split()) for line in input.splitlines()])
    return list(left), list(right)
# endregion


if __name__ == '__main__':
    input = Path(__file__).parent.joinpath('input').read_text()
    print(f'Part 1: {solve_part1(input)}')
    print(f'Part 2: {solve_part2(input)}')
