import math

from pathlib import Path
from enum import Enum
from dataclasses import dataclass

# region Types and Globals
@dataclass(frozen=True)
class DirectionDataMixin:
    symbol: str
    dx: int
    dy: int


class Direction(DirectionDataMixin, Enum):
    Up    = '^',  0, -1
    Right = '>',  1,  0
    Down  = 'v',  0,  1
    Left  = '<', -1,  0

    @classmethod
    def from_symbol(cls, symbol: str) -> "Direction":
        return next(d for d in Direction if d.symbol == symbol)
    
    def turn_right(self) -> "Direction":
        if self is Direction.Up:
            return Direction.Right

        if self is Direction.Right:
            return Direction.Down

        if self is Direction.Down:
            return Direction.Left

        if self is Direction.Left:
            return Direction.Up


@dataclass(slots=True)
class VisitedTile:
    x: int
    y: int
    direction: Direction
# endregion


def solve_part1(input: str) -> int:
    grid = [line.strip() for line in input.splitlines()]
    return len(_collect_path(grid))


def _collect_path(grid: list[str]) -> list[VisitedTile]:
    height = len(grid)
    width = len(grid[0])
    (x, y), direction = next(
        ((x, y), Direction.from_symbol(symbol))
        for y, row in enumerate(grid) 
        for x, symbol in enumerate(row) 
        if symbol != '.' and symbol != '#'
    )

    visited = [[False] * width for _ in grid]
    visited_tiles = list()
    while True:
        visited_tile = VisitedTile(x, y, direction)
        if not visited[y][x]:
            visited[y][x] = True
            visited_tiles.append(visited_tile)

        next_x = x + direction.dx
        next_y = y + direction.dy
        if next_x < 0 or next_x >= width or next_y < 0 or next_y >= height:
            break
        next_symbol = grid[next_y][next_x]
        if next_symbol == '#':
            direction = direction.turn_right()
            visited_tile.direction = direction  # Overwriting direction or the new obstacle would be placed over an existing one
        else:
            x = next_x
            y = next_y

    return visited_tiles


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
