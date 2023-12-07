import { readFile } from '@util';
import { solvePart1, solvePart2 } from './index';

describe('Day 7: Camel Cards', () => {
  describe('Example input', () => {
    const input = `
      32T3K 765
      T55J5 684
      KK677 28
      KTJJT 220
      QQQJA 483
    `;
    const part1Solution = 6440;
    const part2Solution = null;

    test(`solution is ${part1Solution ?? '?'} for part 1`, () => {
      const result = solvePart1(input);
      expect(result).toEqual(part1Solution);
    });
    test.skip(`solution is ${part2Solution ?? '?'} for part 2`, () => {
      const result = solvePart2(input);
      expect(result).toEqual(part2Solution);
    });
  });

  describe('Real input', () => {
    const inputPath = `${__dirname}/input`;
    const input = readFile(inputPath);
    const part1Solution = 255048101;
    const part2Solution = null;

    test(`solution is ${part1Solution ?? '?'} for part 1`, () => {
      const result = solvePart1(input);
      expect(result).toEqual(part1Solution);
    });
    test.skip(`solution is ${part2Solution ?? '?'} for part 2`, () => {
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
