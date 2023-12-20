import { readFile } from '@util';
import { solvePart1, solvePart2 } from './index';

describe('Day 20: Pulse Propagation', () => {
  // region Example Inputs
  describe('Example input 1', () => {
    const input = `
      broadcaster -> a, b, c
      %a -> b
      %b -> c
      %c -> inv
      &inv -> a
    `;
    const part1Solution = 32000000;

    test(`solution is ${part1Solution ?? '?'} for part 1`, () => {
      const result = solvePart1(input);
      expect(result).toEqual(part1Solution);
    });
  });
  describe('Example input 2', () => {
    const input = `
      broadcaster -> a
      %a -> inv, con
      &inv -> b
      %b -> con
      &con -> output
    `;
    const part1Solution = 11687500;

    test(`solution is ${part1Solution ?? '?'} for part 1`, () => {
      const result = solvePart1(input);
      expect(result).toEqual(part1Solution);
    });
  });
  describe('Example input 3', () => {
    const input = `
      broadcaster -> a, b
      %a -> con
      %b -> con
      &con -> output
    `;
    const part1Solution = 11250000;

    /*
    * Should send the following signals for the first button push:
    *   button -low-> broadcaster
    *   broadcaster -low-> a
    *   broadcaster -low-> b
    *   a -high-> con
    *   b -high-> con
    *   con -high-> output
    *   con -low-> output
    * 3 high, 4 low => 12
    * */
    test(`solution is ${part1Solution ?? '?'} for part 1`, () => {
      const result = solvePart1(input);
      expect(result).toEqual(part1Solution);
    });
  });
  // endregion

  describe('Real input', () => {
    const inputPath = `${__dirname}/input`;
    const input = readFile(inputPath);
    const part1Solution = 949764474;
    const part2Solution = 243221023462303;

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
