import { revertString, splitLines } from '@util';

export function calculateCalibrationSum(calibrationDocument: string, parseWords = false): number {
  return splitLines(calibrationDocument)
    .map(v => findCalibrationValue(v, parseWords))
    .reduce((s, v) => s + v, 0);
}

function findCalibrationValue(line: string, parseWords: boolean): number {
  const firstMatcher = parseWords ? firstDigitWordMatcher : numberMatcher;
  const lastMatcher = parseWords ? lastDigitWordMatcher : numberMatcher;
  const toNumber = parseWords ? (v: string) => wordToNumber[v] || Number(v) : Number;

  const firstMatch = line.match(firstMatcher);
  const lastMatch = revertString(line).match(lastMatcher);
  if (firstMatch == null || lastMatch == null) {
    throw new Error(`Unable to find calibration value in line: ${line}`);
  }

  const firstDigit = firstMatch[0];
  const lastDigit = revertString(lastMatch[0]);
  return toNumber(firstDigit) * 10 + toNumber(lastDigit);
}

const numberMatcher = /\d/;
const wordToNumber: Record<string, number> = {
  one: 1,
  two: 2,
  three: 3,
  four: 4,
  five: 5,
  six: 6,
  seven: 7,
  eight: 8,
  nine: 9,
}
const firstDigitWordMatcher = new RegExp(`\\d|${Object.keys(wordToNumber).join('|')}`, '')
const lastDigitWordMatcher = new RegExp(`\\d|${Object.keys(wordToNumber).map(revertString).join('|')}`, '')
