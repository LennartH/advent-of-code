import { readFile } from '@util';
import { solvePart1, solvePart2 } from './index';

describe('Day 10: Pipe Maze', () => {
  describe('Example input 1', () => {
    const input1 = `
      -L|F7
      7S-7|
      L|7||
      -L-J|
      L|-JF
    `;
    const part1Solution = 4;

    const input2 = `
      ..........
      .S------7.
      .|F----7|.
      .||....||.
      .||....||.
      .|L-7F-J|.
      .|..||..|.
      .L--JL--J.
      ..........
    `
    const part2Solution = 4;

    test(`solution is ${part1Solution ?? '?'} for part 1`, () => {
      const result = solvePart1(input1);
      expect(result).toEqual(part1Solution);
    });
    test(`solution is ${part2Solution ?? '?'} for part 2`, () => {
      // const result = solvePart2(input2);
      const result = solvePart2(input2);
      expect(result).toEqual(part2Solution);
    });
  });
  describe('Example input 2', () => {
    const input1 = `
      7-F7-
      .FJ|7
      SJLL7
      |F--J
      LJ.LJ
    `;
    const part1Solution = 8;

    const input2 = `
      FF7FSF7F7F7F7F7F---7
      L|LJ||||||||||||F--J
      FL-7LJLJ||||||LJL-77
      F--JF--7||LJLJ7F7FJ-
      L---JF-JLJ.||-FJLJJ7
      |F|F-JF---7F7-L7L|7|
      |FFJF7L7F-JF7|JL---7
      7-L-JL7||F7|L7F-7F7|
      L.L7LFJ|||||FJL7||LJ
      L7JLJL-JLJLJL--JLJ.L
    `
    const part2Solution = 10;

    test(`solution is ${part1Solution ?? '?'} for part 1`, () => {
      const result = solvePart1(input1);
      expect(result).toEqual(part1Solution);
    });
    test(`solution is ${part2Solution ?? '?'} for part 2`, () => {
      const result = solvePart2(input2);
      expect(result).toEqual(part2Solution);
    });
  });

  describe('Real input', () => {
    const inputPath = `${__dirname}/input`;
    const input = readFile(inputPath);
    const part1Solution = 6907;
    const part2Solution = 541;

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
