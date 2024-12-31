# region Types and Globals

# endregion


def solve_part1(input: str) -> int:
    lines = [line.strip() for line in input.splitlines()]
    # TODO implement solution
    return None


def solve_part2(input: str) -> int:
    lines = [line.strip() for line in input.splitlines()]
    # TODO implement solution
    return None


# region Shared Code

# endregion


if __name__ == '__main__':
    input = Path(__file__).parent.joinpath('input').read_text()
    print(f'Part 1: {solve_part1(input)}')
    print(f'Part 2: {solve_part2(input)}')
