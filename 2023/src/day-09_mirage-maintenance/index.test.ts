import { readFile } from '@util';
import { solvePart1, solvePart2 } from './index';

describe('Day 9: Mirage Maintenance', () => {
  describe('Example input', () => {
    const input = `
      0 3 6 9 12 15
      1 3 6 10 15 21
      10 13 16 21 30 45
    `;
    const part1Solution = 114;
    const part2Solution = 2;

    test(`solution is ${part1Solution ?? '?'} for part 1`, () => {
      const result = solvePart1(input);
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
    const part1Solution = 1696140818;
    const part2Solution = 1152;

    test(`solution is ${part1Solution ?? '?'} for part 1`, () => {
      const result = solvePart1(input);
      expect(result).toEqual(part1Solution);
    });
    test(`solution is ${part2Solution ?? '?'} for part 2`, () => {
      const result = solvePart2(input);
      expect(result).toEqual(part2Solution);
    });
  });
});
