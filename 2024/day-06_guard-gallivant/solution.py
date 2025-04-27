import math

from pathlib import Path
from enum import Enum
from dataclasses import dataclass
from itertools import pairwise


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
    # return len(_collect_visited_tiles(grid))  # 0.00310s (average of 1000)
    return _raywalk_visited_count(grid)  # 0.00214s (average of 1000)


# region Part 1 - Intuitive
def _collect_visited_tiles(grid: list[str]) -> list[VisitedTile]:
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
# endregion


# region Part 1 - Raywalking
def _raywalk_visited_count(grid: list[str]) -> int:
    total_steps = 0
    ray_steps = _collect_rays(grid)  # 0.00108s (average of 1000)
    rays = []
    offset = 1
    for a, b in pairwise(ray_steps):
        steps = abs(a.x - b.x) + abs(a.y - b.y) + 1
        total_steps += steps

        #                            A x  y    B x  y     axis  u    v
        # Change ray representation:  (4, 6) -> (4, 1)  to  4,  1 -> 6
        axis1 = a.x if a.x == b.x else a.y
        u1, v1 = (a.y, b.y) if a.x == b.x else (a.x, b.x)
        u1, v1 = (v1, u1) if v1 < u1 else (u1, v1)

        # Collect all distinct overlaps with previous rays
        ray_overlaps = set()
        for i, (axis2, u2, v2) in enumerate(rays):
            if i % 2 == offset:
                # Opposite orientation: Overlap is combination of both axis values
                if u1 <= axis2 <= v1 and u2 <= axis1 <= v2:
                    ray_overlaps.add((axis1, axis2) if a.x == b.x else (axis2, axis1))
            else:
                # Same orientation: Overlaps are along the same line
                if axis1 == axis2 and (overlap_end := min(v1, v2)) - (overlap_start := max(u1, u2)) > 0:
                    ray_overlaps.update(
                        (axis1, w) if a.x == b.x else (w, axis1)
                        for w in range(overlap_start, overlap_end)
                    )
        total_steps -= len(ray_overlaps)

        rays.append((axis1, u1, v1))
        offset = offset ^ 1  # toggle between 0 and 1
    
    return total_steps

def _collect_rays(grid: list[str]) -> list[VisitedTile]:
    height = len(grid)
    width = len(grid[0])

    obstacles_by_x = [[] for _ in range(width)]
    obstacles_by_y = [[] for _ in range(height)]
    x = -1
    y = -1
    direction: Direction = None
    for tile_y, row in enumerate(grid):
        for tile_x, symbol in enumerate(row):
            if symbol == '#':
                obstacles_by_x[tile_x].append(tile_y)
                obstacles_by_y[tile_y].append(tile_x)
            elif symbol != '.':
                x = tile_x
                y = tile_y
                direction = Direction.from_symbol(symbol)

    visited_tiles = [VisitedTile(x, y, direction)]
    while True:
        # TODO Cleanup
        if direction.dx == 0:
            closest_obstacle = _closest_obstacle(y, direction.dy, obstacles_by_x[x])
            y = closest_obstacle - direction.dy if closest_obstacle is not None else 0 if direction.dy < 0 else height - 1
        else:
            closest_obstacle = _closest_obstacle(x, direction.dx, obstacles_by_y[y])
            x = closest_obstacle - direction.dx if closest_obstacle is not None else 0 if direction.dx < 0 else width - 1
        direction = direction.turn_right()
        visited_tiles.append(VisitedTile(x, y, direction))
        
        if closest_obstacle is None:
            break

    return visited_tiles


def _closest_obstacle(position: int, delta: int, obstacles: list[int]) -> int:
    if not obstacles:
        return None

    left = 0
    right = len(obstacles) - 1
    while abs(left - right) > 1:
        index = (left + right) // 2
        if obstacles[index] > position:
            right = index
        else:
            left = index
    
    left_value = obstacles[left]
    right_value = obstacles[right]
    if delta*position < delta*left_value and delta*position < delta*right_value:
        return left_value if abs(left_value - position) < abs(right_value - position) else right_value
    if delta*position < delta*left_value:
        return left_value
    if delta*position < delta*right_value:
        return right_value
    return None
# endregion


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

    import timeit
    n = 1000
    dur = timeit.timeit('solve_part1(input)', number=n, globals=globals())
    print(f'Part 1: {dur / n:.5f}s (average of {n})')
    dur = timeit.timeit('solve_part2(input)', number=n, globals=globals())
    print(f'Part 2: {dur / n:.5f}s (average of {n})')
