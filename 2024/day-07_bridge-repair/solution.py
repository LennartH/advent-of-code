import math

from pathlib import Path
from collections.abc import Callable

# region Types and Globals
type Calibration = tuple[int, list[int]]
# endregion


def solve_part1(input: str) -> int:
    calibrations = parse_calibrations(input)
    return sum(c[0] for c in calibrations if r2l_is_valid_calibration(c, with_concatenation=False))


def solve_part2(input: str) -> int:
    calibrations = parse_calibrations(input)
    return sum(c[0] for c in calibrations if r2l_is_valid_calibration(c, with_concatenation=True))


# region Shared Code
def parse_calibrations(input: str) -> list[Calibration]:
    lines = [line.strip() for line in input.splitlines()]
    calibrations = []
    for line in lines:
        target, *operands = line.split()
        calibrations.append((
            int(target[:-1]),
            list(map(int, operands)),
        ))
    return calibrations


# ~0.08s, using string instead of math operations doesn't really change runtime
def r2l_is_valid_calibration(calibration: Calibration, with_concatenation: bool) -> bool:
    target, operands = calibration
    tallies = [target]
    for operand in reversed(operands[1:]):
        next_tallies = []
        for tally in tallies:
            if (next_tally := tally - operand) > 0:
                next_tallies.append(next_tally)
            if tally % operand == 0:
                next_tallies.append(tally // operand)
            if with_concatenation:
                tally_length = math.floor(math.log10(tally)) + 1
                operand_length = math.floor(math.log10(operand)) + 1
                if tally_length > operand_length and (tally % 10**operand_length) == operand:
                    next_tallies.append(tally // 10**operand_length)
        tallies = next_tallies
    return operands[0] in tallies


# ~2.3s
def pruned_is_valid_calibration(calibration: Calibration, with_concatenation: bool) -> bool:
    target, operands = calibration
    tallies = [operands[0]]
    for operand in operands[1:]:
        next_tallies = []
        for tally in tallies:
            if (next_tally := tally + operand) <= target:
                next_tallies.append(next_tally)
            if (next_tally := tally * operand) <= target:
                next_tallies.append(next_tally)
            if with_concatenation and (next_tally := concatenation(tally, operand)) <= target:
                next_tallies.append(next_tally)
        tallies = next_tallies
    return target in tallies


# ~4s
def is_valid_calibration(calibration: Calibration, with_concatenation: bool) -> bool:
    target, operands = calibration
    tallies = [operands[0]]
    for operand in operands[1:]:
        next_tallies = []
        for tally in tallies:
            next_tallies.append(tally + operand)
            next_tallies.append(tally * operand)
            if with_concatenation:
                next_tallies.append(concatenation(tally, operand))
        tallies = next_tallies
    return target in tallies

# string concatenation: naive ~7.4s, pruned ~4s
#                 math: naive ~4s,   pruned ~2.3s
def concatenation(a: int, b: int) -> int:
    digits = math.floor(math.log10(b)) + 1
    return (a * 10**digits) + b
# endregion


if __name__ == '__main__':
    input = Path(__file__).parent.joinpath('input').read_text()
    print(f'Part 1: {solve_part1(input)}')
    print(f'Part 2: {solve_part2(input)}')
