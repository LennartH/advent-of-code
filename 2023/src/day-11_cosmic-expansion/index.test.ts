import { readFile } from '@util';
import { solvePart1, solvePart2, solveWithExpansionFactor } from './index';

describe('Day 11: Cosmic Expansion', () => {
  describe('Example input', () => {
    const input = `
      ...#......
      .......#..
      #.........
      ..........
      ......#...
      .#........
      .........#
      ..........
      .......#..
      #...#.....
    `;
    const part1Solution = 374;

    const solutionWithExpansion10 = 1030;
    const solutionWithExpansion100 = 8410;

    test(`solution is ${part1Solution ?? '?'} for part 1`, () => {
      const result = solvePart1(input);
      expect(result).toEqual(part1Solution);
    });
    test.skip(`solution is ${solutionWithExpansion10} for with expansion factor 10`, () => {
      const result = solveWithExpansionFactor(input, 10);
      expect(result).toEqual(solutionWithExpansion10);
    });
    test.skip(`solution is ${solutionWithExpansion100} for with expansion factor 100`, () => {
      const result = solveWithExpansionFactor(input, 100);
      expect(result).toEqual(solutionWithExpansion100);
    });
  });

  describe('Real input', () => {
    const inputPath = `${__dirname}/input`;
    const input = readFile(inputPath);
    const part1Solution = 10289334;
    const part2Solution = 649862989626;

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
