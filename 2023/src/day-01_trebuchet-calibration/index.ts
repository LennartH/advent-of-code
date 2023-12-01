import { splitLines } from '@util';

export function calculateCalibrationSum(calibrationDocument: string): number {
  return splitLines(calibrationDocument).map(findCalibrationValue).reduce((s, v) => s + v, 0);
}

function findCalibrationValue(line: string): number {
  const numbers = line.match(/\d/g)?.map(Number);
  if (numbers == null || numbers.length === 0) {
    throw new Error(`Unable to find calibration value in line: ${line}`);
  }
  return numbers[0] * 10 + numbers.at(-1)!;
}
