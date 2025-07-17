import math
import dataclasses

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
    
    # TODO compare with dict or list
    def turn_right(self) -> "Direction":
        if self is Direction.Up:
            return Direction.Right

        if self is Direction.Right:
            return Direction.Down

        if self is Direction.Down:
            return Direction.Left

        if self is Direction.Left:
            return Direction.Up


# TODO compare with frozen dataclass
# @dataclass(slots=True, frozen=True)
@dataclass(slots=True, unsafe_hash=True)
class VisitedTile:
    x: int
    y: int
    direction: Direction
# endregion


def solve_part1(input: str) -> int:
    return _naive_part1(input)
    # return _raywalking_part1(input)


def solve_part2(input: str) -> int:
    return _naive_part2(input)
    # return _raywalking_part2(input)


# region Naive Solution
# 2025-07-17
#   Part 1:
#     count tiles: 0.00261s (average of 1000)
#     collect tiles: 0.00378s (average of 1000)
#     with IO: 0.054109 +- 0.000431 seconds time elapsed  ( +-  0.80% )
#   Part 2:
#     set with every tile: 21.08159s (average of 10)
#      ^-- with IO: 21.9483 +- 0.0579 seconds time elapsed  ( +-  0.26% )
#      ^-- Part 1 & 2 with IO: 21.9025 +- 0.0261 seconds time elapsed  ( +-  0.12% )

def _naive_part1(input: str) -> int:
    grid = [line.strip() for line in input.splitlines()]
    start = next(
        VisitedTile(x, y, Direction.from_symbol(symbol))
        for y, row in enumerate(grid)
        for x, symbol in enumerate(row)
        if symbol in ['^', '>', 'v', '<']
    )
    return _naive_count_visited_tiles(start, grid)


# TODO Compare with reusing visited_tiles for part 1
def _naive_part2(input: str) -> int:
    grid = [line.strip() for line in input.splitlines()]
    start = next(
        VisitedTile(x, y, Direction.from_symbol(symbol))
        for y, row in enumerate(grid)
        for x, symbol in enumerate(row)
        if symbol in ['^', '>', 'v', '<']
    )
    visited_tiles = _naive_collect_visited_tiles(start, grid)
    return _naive_count_loops(start, grid, visited_tiles)


def _naive_count_visited_tiles(start: VisitedTile, grid: list[str]) -> int:
    height = len(grid)
    width = len(grid[0])
    x, y, direction = (start.x, start.y, start.direction)

    visited = [[False] * width for _ in grid]
    visited_count = 0
    while True:
        if not visited[y][x]:
            visited[y][x] = True
            visited_count += 1

        next_x = x + direction.dx
        next_y = y + direction.dy
        if next_x < 0 or next_x >= width or next_y < 0 or next_y >= height:
            break
        next_symbol = grid[next_y][next_x]
        if next_symbol == '#':
            direction = direction.turn_right()
        else:
            x = next_x
            y = next_y

    return visited_count


def _naive_collect_visited_tiles(start: VisitedTile, grid: list[str]) -> list[VisitedTile]:
    height = len(grid)
    width = len(grid[0])
    x, y, direction = (start.x, start.y, start.direction)

    within_grid = True
    visited = [[False] * width for _ in grid]
    visited_tiles = list()
    # while within_grid:
    #     wall_hit = False

    #     next_x = x + direction.dx
    #     next_y = y + direction.dy
    #     if next_x < 0 or next_x >= width or next_y < 0 or next_y >= height:
    #         within_grid = False
    #     else:
    #         next_symbol = grid[next_y][next_x]
    #         if next_symbol == '#':
    #             wall_hit = True
    #             next_x = x
    #             next_y = y
    #             direction = direction.turn_right()
        
    #     if not visited[y][x] and not wall_hit:
    #         visited[y][x] = True
    #         visited_tiles.append(VisitedTile(x, y, direction))
    #     x = next_x
    #     y = next_y
    while within_grid:
        wall_hit = False
        next_x = x + direction.dx
        next_y = y + direction.dy

        try:
            next_symbol = grid[next_y][next_x]
            if next_symbol == '#':
                wall_hit = True
                next_x = x
                next_y = y
                direction = direction.turn_right()
        except IndexError:
            within_grid = False
        
        if not visited[y][x] and not wall_hit:
            # Do not add visited tile after hitting a wall or obstacle placement for part 2 gets tricky (wrong direction)
            visited[y][x] = True
            visited_tiles.append(VisitedTile(x, y, direction))
        x = next_x
        y = next_y

    return visited_tiles


def _naive_count_loops(start: VisitedTile, grid: list[str], visited_tiles: list[VisitedTile]) -> int:
    loop_count = 0

    for visited_tile in visited_tiles[1:]:
        obstacle = (visited_tile.x, visited_tile.y)
        if _naive_detect_loop(start, grid, obstacle):
            loop_count += 1

    return loop_count


def _naive_detect_loop(start: VisitedTile, grid: list[str], obstacle: tuple[int, int]) -> bool:
    height = len(grid)
    width = len(grid[0])
    obstacle_x, obstacle_y = obstacle

    current_tile = dataclasses.replace(start)
    # TODO compare with array + list/set
    # TODO compare with only storing tile when hitting wall/obstacle
    visited_tiles: set(VisitedTile) = {current_tile}
    while True:
        direction = current_tile.direction

        next_x = current_tile.x + direction.dx
        next_y = current_tile.y + direction.dy
        next_direction = direction

        # TODO compare with try-except
        if next_x < 0 or next_x >= width or next_y < 0 or next_y >= height:
            break
        next_symbol = grid[next_y][next_x]
        if next_symbol == '#' or (next_x == obstacle_x and next_y == obstacle_y):
            next_x = current_tile.x
            next_y = current_tile.y
            next_direction = direction.turn_right()

        next_tile = VisitedTile(next_x, next_y, next_direction)
        if next_tile in visited_tiles:
            return True

        current_tile = next_tile
        visited_tiles.add(current_tile)

    return False
# endregion


# region Raywalking
def _raywalking_part1(input: str) -> int:
    return _raywalk_visited_count(grid)  # 0.00214s (average of 1000)


def _raywalking_part2(input: str) -> int:
    # TODO implement solution
    return math.nan


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


if __name__ == '__main__':
    input = Path(__file__).parent.joinpath('input').read_text()
    print(f'Part 1: {solve_part1(input)}')
    print(f'Part 2: {solve_part2(input)}')

    # import timeit
    # n = 1000
    # dur = timeit.timeit('solve_part1(input)', number=n, globals=globals())
    # print(f'Part 1: {dur / n:.5f}s (average of {n})')
    # n = 10
    # dur = timeit.timeit('solve_part2(input)', number=n, globals=globals())
    # print(f'Part 2: {dur / n:.5f}s (average of {n})')
