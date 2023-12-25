import { readFile } from '@util';
import { solvePart1, solvePart2 } from './index';

describe('Day 24: Never Tell Me The Odds', () => {
  describe('Example input', () => {
    const input = `
      19, 13, 30 @ -2,  1, -2
      18, 19, 22 @ -1, -1, -2
      20, 25, 34 @ -2, -2, -4
      12, 31, 28 @ -1, -2, -1
      20, 19, 15 @  1, -5, -3
    `;
    const lowerBound = 7;
    const upperbound = 27;

    const part1Solution = 2;
    const part2Solution = 47;

    test(`solution is ${part1Solution ?? '?'} for part 1`, () => {
      const result = solvePart1(input, lowerBound, upperbound);
      expect(result).toEqual(part1Solution);
    });
    test(`solution is ${part2Solution ?? '?'} for part 2`, () => {
      const result = solvePart2(input);
      expect(result).toEqual(part2Solution);
    });
  });

  describe('Real input', () => {
    const inputPath = `${__dirname}/input`;
    const input = readFile(inputPath);
    const lowerBound = 200000000000000;
    const upperbound = 400000000000000;

    const part1Solution = 19976;
    const part2Solution = null;

    test(`solution is ${part1Solution ?? '?'} for part 1`, () => {
      const result = solvePart1(input, lowerBound, upperbound);
      expect(result).toEqual(part1Solution);
    });
    test(`solution is ${part2Solution ?? '?'} for part 2`, () => {
      const result = solvePart2(input);
      expect(result).toEqual(part2Solution);
    });
  });

  // region Function Specific Tests
  describe.skip('Make sure that', () => {
    // Add tests if all hope is lost (it's okay to cry)
  });
  // endregion
});
