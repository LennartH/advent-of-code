import { readFile } from '@util';
import { solvePart1, solvePart2 } from './index';

describe('Day 21: Step Counter', () => {
  describe('Example input', () => {
    const input = `
      ...........
      .....###.#.
      .###.##..#.
      ..#.#...#..
      ....#.#....
      .##..S####.
      .##..#...#.
      .......##..
      .##.#.####.
      .##..##.##.
      ...........
    `;
    const part1Solution = 16;

    test(`solution is ${part1Solution ?? '?'} for part 1`, () => {
      const result = solvePart1(input, 6);
      expect(result).toEqual(part1Solution);
    });
  });

  describe('Real input', () => {
    const inputPath = `${__dirname}/input`;
    const input = readFile(inputPath);
    const part1Solution = 3572;
    const part2Solution = 594606492802848;

    test(`solution is ${part1Solution ?? '?'} for part 1`, () => {
      const result = solvePart1(input, 64);
      expect(result).toEqual(part1Solution);
    });
    test(`solution is ${part2Solution ?? '?'} for part 2`, () => {
      const result = solvePart2(input, 26501365);
      expect(result).toEqual(part2Solution);
    });
  });
});
