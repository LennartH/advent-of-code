import { calculateCalibrationSum } from './index';
import { readFile } from '@util';

describe('Day 1', () => {
  describe('example input', () => {
    test('solution is 142 for part 1', () => {
      const input = `
        1abc2
        pqr3stu8vwx
        a1b2c3d4e5f
        treb7uchet
      `;
      const calibrationSum = calculateCalibrationSum(input);
      expect(calibrationSum).toEqual(142);
    });
    test('solution is 281 for part 2', () => {
      const input = `
        two1nine
        eightwothree
        abcone2threexyz
        xtwone3four
        4nineeightseven2
        zoneight234
        7pqrstsixteen
      `;
      const calibrationSum = calculateCalibrationSum(input, true);
      expect(calibrationSum).toEqual(281);
    });
  });
  describe('solution is', () => {
    const inputPath = `${__dirname}/input`;
    const input = readFile(inputPath);
    test('56049 for part 1', () => {
      const calibrationSum = calculateCalibrationSum(input);
      expect(calibrationSum).toEqual(56049);
    });
    test('54530 for part 2', () => {
      const calibrationSum = calculateCalibrationSum(input, true);
      expect(calibrationSum).toEqual(54530);
    });
  });

  // region Tests for smaller parts
  test('2twone is 21', () => {
    const input = '2twone';
    const calibrationSum = calculateCalibrationSum(input, true);
    expect(calibrationSum).toEqual(21);
  })
  // endregion
});
