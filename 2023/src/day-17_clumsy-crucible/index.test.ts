import { readFile } from '@util';
import { solvePart1, solvePart2 } from './index';

describe('Day 17: Clumsy Crucible', () => {
  describe('Example input', () => {
    const input = `
      2413432311323
      3215453535623
      3255245654254
      3446585845452
      4546657867536
      1438598798454
      4457876987766
      3637877979653
      4654967986887
      4564679986453
      1224686865563
      2546548887735
      4322674655533
    `;
    const part1Solution = 102;
    const part2Solution = 94;

    const additionalPart2Input = `
      111111111111
      999999999991
      999999999991
      999999999991
      999999999991
    `;
    const additionalPart2Solution = 71;

    test(`solution is ${part1Solution ?? '?'} for part 1`, () => {
      const result = solvePart1(input);
      expect(result).toEqual(part1Solution);
    });
    test(`solution is ${part2Solution ?? '?'} for part 2`, () => {
      const result = solvePart2(input);
      expect(result).toEqual(part2Solution);
    });
    test(`additional solution is ${additionalPart2Solution ?? '?'} for part 2`, () => {
      const result = solvePart2(additionalPart2Input);
      expect(result).toEqual(additionalPart2Solution);
    });
  });

  describe('Real input', () => {
    const inputPath = `${__dirname}/input`;
    const input = readFile(inputPath);
    const part1Solution = 1065;
    const part2Solution = 1249;

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
