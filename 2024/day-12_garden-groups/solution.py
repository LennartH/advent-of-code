example = '''
    RRRRIICCFF
    RRRRIICCCF
    VVRRRCCFFF
    VVRCCCJFFF
    VVVVCJJCFE
    VVIVCCJJEE
    VVIIICJJEE
    MIIIIIJJEE
    MIIISIJEEE
    MMMISSJEEE
'''

directions = [(-1, 0), (0, 1), (1, 0), (0, -1)]

# input = example
with open('input', mode='r') as f:
    input = f.read()

region = [list(line.strip()) for line in input.strip().splitlines()]
height = len(region)
width = len(region[0])

def main():
    visited = [[False for _ in line] for line in region]
    plots = []
    for y in range(height):
        for x in range(width):
            current = region[y][x]
            if not visited[y][x]:
                plots.append(floodfill(x, y, visited))
    print('Part 1:', sum(plot['score1'] for plot in plots))

    count_sides(plots)
    print('Part 2:', sum(plot['score2'] for plot in plots))


def floodfill(x, y, visited):
    plant = region[y][x]
    perimeter = 0
    points = []

    stack = [(y, x)]
    while len(stack) > 0:
        current = stack.pop()
        y, x = current
        if visited[y][x]:
            continue

        visited[y][x] = True
        points.append(current)
        for dy, dx in directions:
            next_y = y + dy
            next_x = x + dx
            if next_y < 0 or next_y >= height or next_x < 0 or next_x >= width or region[next_y][next_x] != plant:
                perimeter += 1
                continue
            if not visited[next_y][next_x]:
                stack.append((next_y, next_x))

    return {
        'plant': plant,
        'points': points,
        'area': len(points),
        'perimeter': perimeter,
        'score1': len(points) * perimeter,
    }


def count_sides(plots):
    for plot in plots:
        plant = plot['plant']
        inside = plot['points']
        min_y = min(y for y, _ in inside)
        max_y = max(y for y, _ in inside)
        min_x = min(x for _, x in inside)
        max_x = max(x for _, x in inside)
        sides = 0

        horizontal_crossings = []
        is_inside = False
        for y in range(min_y, max_y + 1):
            for x in range(min_x - 1, max_x + 1):
                next_x = x + 1
                if (not is_inside and (y, next_x) in inside) or (is_inside and (y, next_x) not in inside):
                    horizontal_crossings.append((x, y, is_inside))
                    is_inside = not is_inside
        horizontal_crossings = sorted(horizontal_crossings)
        for i in range(len(horizontal_crossings) - 1):
            x, y, in_to_out = horizontal_crossings[i]
            next_x, next_y, next_in_to_out = horizontal_crossings[i + 1]
            if x != next_x or in_to_out != next_in_to_out or next_y - y != 1:
                sides += 1

        vertical_crossings = []
        is_inside = False
        for x in range(min_x, max_x + 1):
            for y in range(min_y - 1, max_y + 1):
                next_y = y + 1
                if (not is_inside and (next_y, x) in inside) or (is_inside and (next_y, x) not in inside):
                    vertical_crossings.append((y, x, is_inside))
                    is_inside = not is_inside
        vertical_crossings = sorted(vertical_crossings)
        for i in range(len(vertical_crossings) - 1):
            y, x, in_to_out = vertical_crossings[i]
            next_y, next_x, next_in_to_out = vertical_crossings[i + 1]
            if y != next_y or in_to_out != next_in_to_out or next_x - x != 1:
                sides += 1

        sides += 2
        plot['sides'] = sides
        plot['score2'] = plot['area'] * sides


if __name__ == '__main__':
    main()
