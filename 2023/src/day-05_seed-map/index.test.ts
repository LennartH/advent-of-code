import { readFile } from '@util';
import { solvePart1, solvePart2 } from './index';

describe('Day 5: Seed Map', () => {
  describe('example input', () => {
    const input = `
      seeds: 79 14 55 13
      
      seed-to-soil map:
      50 98 2
      52 50 48
      
      soil-to-fertilizer map:
      0 15 37
      37 52 2
      39 0 15
      
      fertilizer-to-water map:
      49 53 8
      0 11 42
      42 0 7
      57 7 4
      
      water-to-light map:
      88 18 7
      18 25 70
      
      light-to-temperature map:
      45 77 23
      81 45 19
      68 64 13
      
      temperature-to-humidity map:
      0 69 1
      1 0 69
      
      humidity-to-location map:
      60 56 37
      56 93 4
    `;
    const part1Solution = 35;
    const part2Solution = 46;

    test(`solution is ${part1Solution ?? '?'} for part 1`, () => {
      const result = solvePart1(input);
      expect(result).toEqual(part1Solution);
    });
    test(`solution is ${part2Solution ?? '?'} for part 2`, () => {
      const result = solvePart2(input);
      expect(result).toEqual(part2Solution);
    });
  });

  describe('solution is', () => {
    const inputPath = `${__dirname}/input`;
    const input = readFile(inputPath);
    const part1Solution = 218513636;
    const part2Solution = 81956384;

    test(`${part1Solution ?? '?'} for part 1`, () => {
      const result = solvePart1(input);
      expect(result).toEqual(part1Solution);
    });
    test(`${part2Solution ?? '?'} for part 2`, () => {
      const result = solvePart2(input);
      expect(result).toEqual(part2Solution);
    });
  });

  // region Function Specific Tests

  // endregion
});
