import { readFile } from '@util';
import { solvePart1, solvePart2 } from './index';

describe('Day 2', () => {
  describe('example input', () => {
    const input = `
      Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green
      Game 2: 1 blue, 2 green; 3 green, 4 blue, 1 red; 1 green, 1 blue
      Game 3: 8 green, 6 blue, 20 red; 5 blue, 4 red, 13 green; 5 green, 1 red
      Game 4: 1 green, 3 red, 6 blue; 3 green, 6 red; 3 green, 15 blue, 14 red
      Game 5: 6 red, 1 blue, 3 green; 2 blue, 1 red, 2 green
    `;

    test('solution is 8 for part 1', () => {
      const result = solvePart1(input);
      expect(result).toEqual(8);
    });
    test('solution is 2286 for part 2', () => {
      const result = solvePart2(input);
      expect(result).toEqual(2286);
    });
  });
  describe('solution is', () => {
    const inputPath = `${__dirname}/input`;
    const input = readFile(inputPath);
    test('1853 for part 1', () => {
      const result = solvePart1(input);
      expect(result).toEqual(1853);
    });
    test('72706 for part 2', () => {
      const result = solvePart2(input);
      expect(result).toEqual(72706);
    });
  });

  // region Tests for smaller parts
  // endregion
});
