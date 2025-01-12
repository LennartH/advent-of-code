import math

from pathlib import Path

# region Types and Globals
word_forward = 'XMAS'
word_backward = 'SAMX'
directions = [(-1, 0), (-1, -1), (0, -1), (1, -1), (1, 0), (1, 1), (0, 1), (-1, 1)]
# endregion


def solve_part1(input: str) -> int:
    grid = [list(line.strip()) for line in input.splitlines()]
    # return count_xmas_naive(grid)        # 0.026 (average of 100 executions)
    # return count_xmas_single_loop(grid)  # 0.038 (average of 100 executions)
    return count_xmas_seeking(grid)        # 0.013 (average of 100 executions)


def count_xmas_seeking(grid: list[list[str]]) -> int:
    height = len(grid)
    width = len(grid[0])
    count = 0
    for y in range(height):
        for x in range(width):
            if grid[y][x] == 'X':
                for dx, dy in directions:
                    for i in range(1, 4):
                        nx = x + dx*i
                        ny = y + dy*i
                        if (
                            nx < 0 or nx >= width or ny < 0 or ny >= height or
                            grid[ny][nx] != word_forward[i]
                        ):
                            break
                        if i == 3:
                            count += 1
    return count


def count_xmas_single_loop(grid: list[list[str]]) -> int:
    height = len(grid)
    width = len(grid[0])
    count = 0

    word_index_forward = 0
    word_index_backward = 0
    word_index_vertical = (
        [0] * width,
        [0] * width,
    )
    word_index_diagonal = (
        [0] * (width + height - 1),
        [0] * (width + height - 1),
        [0] * (width + height - 1),
        [0] * (width + height - 1),
    )
    for y in range(height):
        word_index_forward = 0
        word_index_backward = 0
        for x in range(width):
            character = grid[y][x]
            word_index_forward, count = do_count(character, word_forward, word_index_forward, count)
            word_index_backward, count = do_count(character, word_backward, word_index_backward, count)
            word_index_vertical[0][x], count = do_count(character, word_forward, word_index_vertical[0][x], count)
            word_index_vertical[1][x], count = do_count(character, word_backward, word_index_vertical[1][x], count)

            word_index_diagonal[0][x + y], count = do_count(character, word_forward, word_index_diagonal[0][x + y], count)
            word_index_diagonal[1][x + y], count = do_count(character, word_backward, word_index_diagonal[1][x + y], count)
            word_index_diagonal[2][x - y], count = do_count(character, word_forward, word_index_diagonal[2][x - y], count)
            word_index_diagonal[3][x - y], count = do_count(character, word_backward, word_index_diagonal[3][x - y], count)
    return count


def do_count(character: str, word: str, word_index: int, count: int) -> tuple[int, int]:
    if character == word[word_index]:
        word_index += 1
        if word_index == 4:
            word_index = 0
            count += 1
    else:
        word_index = 1 if character == word[0] else 0
    
    return (word_index, count)


def count_xmas_naive(grid: list[list[str]]) -> int:
    height = len(grid)
    width = len(grid[0])

    count = 0
    for y in range(height):
        count += count_xmas_in_direction(grid, 0, y, 1, 0, width, math.nan)
        count += count_xmas_in_direction(grid, width - 1, y, -1, 0, -1, math.nan)
        if y != height - 1:
            count += count_xmas_in_direction(grid, 0, y, 1, 1, width, height)
            count += count_xmas_in_direction(grid, 0, y, 1, -1, width, -1)
        if y != 0:
            count += count_xmas_in_direction(grid, width - 1, y, -1, -1, -1, -1)
            count += count_xmas_in_direction(grid, width - 1, y, -1, 1, -1, height)
    for x in range(width):
        count += count_xmas_in_direction(grid, x, 0, 0, 1, math.nan, height)
        count += count_xmas_in_direction(grid, x, height - 1, 0, -1, math.nan, -1)
        if x != 0:
            count += count_xmas_in_direction(grid, x, 0, 1, 1, width, height)
            count += count_xmas_in_direction(grid, x, 0, -1, 1, -1, height)
        if x != width - 1:
            count += count_xmas_in_direction(grid, x, height - 1, -1, -1, -1, -1)
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
        if character == word_forward[word_index]:
            word_index += 1
            if word_index == 4:
                word_index = 0
                count += 1
        else:
            word_index = 1 if character == word_forward[0] else 0
        
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


if __name__ == '__main__':
    input = Path(__file__).parent.joinpath('input').read_text()
    print(f'Part 1: {solve_part1(input)}')
    print(f'Part 2: {solve_part2(input)}')
