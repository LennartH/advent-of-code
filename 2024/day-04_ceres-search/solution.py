import math

from pathlib import Path

# region Types and Globals
word_forwards = 'XMAS'
word_backwards = 'SAMX'
# endregion


def solve_part1(input: str) -> int:
    grid = [list(line.strip()) for line in input.splitlines()]
    return count_xmas_naive(grid)


def count_xmas_naive(grid: list[list[str]]) -> int:
    height = len(grid)
    width = len(grid[0])

    count = 0
    for y in range(height):
        # Horizontal lines from left to right
        count += count_xmas_in_direction(grid, 0, y, 1, 0, width, math.nan)
        # Horizontal lines from right to left
        count += count_xmas_in_direction(grid, width - 1, y, -1, 0, -1, math.nan)
        if y != height - 1:
            # Diagonal lines from left to bottom right
            count += count_xmas_in_direction(grid, 0, y, 1, 1, width, height)
            # Diagonal lines from left to top right
            count += count_xmas_in_direction(grid, 0, y, 1, -1, width, -1)
        if y != 0:
            # Diagonal lines from right to top left
            count += count_xmas_in_direction(grid, width - 1, y, -1, -1, -1, -1)
            # Diagonal lines from right to bottom left
            count += count_xmas_in_direction(grid, width - 1, y, -1, 1, -1, height)
    for x in range(width):
        # Vertical lines from top to bottom
        count += count_xmas_in_direction(grid, x, 0, 0, 1, math.nan, height)
        # Vertical lines from bottom to top
        count += count_xmas_in_direction(grid, x, height - 1, 0, -1, math.nan, -1)
        if x != 0:
            # Diagonal lines from top to bottom right
            count += count_xmas_in_direction(grid, x, 0, 1, 1, width, height)
            # Diagonal lines from top to bottom left
            count += count_xmas_in_direction(grid, x, 0, -1, 1, -1, height)
        if x != width - 1:
            # Diagonal lines from bottom to top left
            count += count_xmas_in_direction(grid, x, height - 1, -1, -1, -1, -1)
            # Diagonal lines from bottom to top right
            count += count_xmas_in_direction(grid, x, height - 1, 1, -1, width, -1)
    return count


def count_xmas_in_direction(
    grid: list[list[str]],
    start_x: int, start_y: int,
    dx: int, dy: int,
    end_x: int, end_y: int
) -> int:
    count = 0
    word_index = 0
    x = start_x
    y = start_y
    while x != end_x and y != end_y:
        character = grid[y][x]
        if character == word_forwards[word_index]:
            word_index += 1
            if word_index == 4:
                word_index = 0
                count += 1
        else:
            word_index = 1 if character == word_forwards[0] else 0
        
        x += dx
        y += dy
    return count


def solve_part2(input: str) -> int:
    grid = [list(line.strip()) for line in input.splitlines()]
    count = 0

    for y in range(1, len(grid) - 1):
        for x in range(1, len(grid[0]) - 1):
            if grid[y][x] == 'A':
                top_left = grid[y - 1][x - 1]
                top_right = grid[y - 1][x + 1]
                bottom_left = grid[y + 1][x - 1]
                bottom_right = grid[y + 1][x + 1]
                if (
                    sorted([top_left, top_right, bottom_left, bottom_right]) == ['M', 'M', 'S', 'S'] and
                    top_left != bottom_right and top_right != bottom_left
                ):
                    count += 1
    return count


# region Shared Code

# endregion


if __name__ == '__main__':
    input = Path(__file__).parent.joinpath('input').read_text()
    print(f'Part 1: {solve_part1(input)}')
    print(f'Part 2: {solve_part2(input)}')
