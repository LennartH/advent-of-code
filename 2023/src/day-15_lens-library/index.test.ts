import { readFile } from '@util';
import { solvePart1, solvePart2 } from './index';

describe('Day 15: Lens Library', () => {
  describe('Example input', () => {
    const input = `
      rn=1,cm-,qp=3,cm=2,qp-,pc=4,ot=9,ab=5,pc-,pc=6,ot=7
    `;
    const part1Solution = 1320;
    const part2Solution = 145;

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
    const part1Solution = 514394;
    const part2Solution = 236358;

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
