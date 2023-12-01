import { calculateCalibrationSum } from './index';
import { readFile } from '@util';

describe('Day 1', () => {
  describe('example input', () => {
    const input = `
      1abc2
      pqr3stu8vwx
      a1b2c3d4e5f
      treb7uchet
    `;

    test('solution is 142 for part 1', () => {
      const calibrationSum = calculateCalibrationSum(input);
      expect(calibrationSum).toEqual(142);
    });
    test.skip('solution is ? for part 2', () => {
      throw new Error('Not implemented')
    });
  });
  describe('solution is', () => {
    const inputPath = `${__dirname}/input`;
    const input = readFile(inputPath);
    test('56049 for part 1', () => {
      const calibrationSum = calculateCalibrationSum(input);
      expect(calibrationSum).toEqual(56049);
    });
    test.skip('? for part 2', () => {
      const calibrationSum = calculateCalibrationSum(input);
      expect(calibrationSum).toEqual(142);
    });
  });

  // region Tests for smaller parts
  // endregion
});
