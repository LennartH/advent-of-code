import { readFile } from '@util';
import { solvePart1, solvePart2 } from './index';

describe('Day 8: Haunted Wasteland', () => {
  describe('Example input', () => {
    const part1Input = `
      LLR

      AAA = (BBB, BBB)
      BBB = (AAA, ZZZ)
      ZZZ = (ZZZ, ZZZ)
    `;
    const part1Solution = 6;

    const part2Input = `
      LR
      
      11A = (11B, XXX)
      11B = (XXX, 11Z)
      11Z = (11B, XXX)
      22A = (22B, XXX)
      22B = (22C, 22C)
      22C = (22Z, 22Z)
      22Z = (22B, 22B)
      XXX = (XXX, XXX)
    `;
    const part2Solution = 6;

    test(`solution is ${part1Solution ?? '?'} for part 1`, () => {
      const result = solvePart1(part1Input);
      expect(result).toEqual(part1Solution);
    });
    test(`solution is ${part2Solution ?? '?'} for part 2`, () => {
      const result = solvePart2(part2Input);
      expect(result).toEqual(part2Solution);
    });
  });

  describe('Real input', () => {
    const inputPath = `${__dirname}/input`;
    const input = readFile(inputPath);
    const part1Solution = 21883;
    const part2Solution = 12833235391111;

    test(`solution is ${part1Solution ?? '?'} for part 1`, () => {
      const result = solvePart1(input);
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
