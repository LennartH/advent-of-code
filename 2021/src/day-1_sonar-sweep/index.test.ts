import { countValueIncrements } from './index';
import { readLines, splitLines } from '../../../util/util';

describe('day 1', () => {
  describe('example input', () => {
    const values = splitLines(`
    199
    200
    208
    210
    200
    207
    240
    269
    260
    263
  `).map((l) => Number(l));

    test('returns 7 for part 1', () => {
      expect(countValueIncrements(values)).toEqual(7);
    });
    test('returns 5 for part 2', () => {
      expect(countValueIncrements(values, 3)).toEqual(5);
    });
  });

  describe('solution is', () => {
    const values = readLines(`${__dirname}/input`).map((l) => Number(l));
    test('1696 for part 1', () => {
      expect(countValueIncrements(values)).toEqual(1696);
    });
    test('1737 for part 2', () => {
      expect(countValueIncrements(values, 3)).toEqual(1737);
    });
  });
});
