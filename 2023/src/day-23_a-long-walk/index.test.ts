import { readFile } from '@util';
import { gridToGraph, solvePart1, solvePart2 } from './index';

describe('Day 23: A Long Walk', () => {
  describe('Example input', () => {
    const input = `
      #.#####################
      #.......#########...###
      #######.#########.#.###
      ###.....#.>.>.###.#.###
      ###v#####.#v#.###.#.###
      ###.>...#.#.#.....#...#
      ###v###.#.#.#########.#
      ###...#.#.#.......#...#
      #####.#.#.#######.#.###
      #.....#.#.#.......#...#
      #.#####.#.#.#########v#
      #.#...#...#...###...>.#
      #.#.#v#######v###.###v#
      #...#.>.#...>.>.#.###.#
      #####v#.#.###v#.#.###.#
      #.....#...#...#.#.#...#
      #.#########.###.#.#.###
      #...###...#...#...#.###
      ###.###.#.###v#####v###
      #...#...#.#.>.>.#.>.###
      #.###.###.#.###.#.#v###
      #.....###...###...#...#
      #####################.#
    `;
    const part1Solution = 94;
    const part2Solution = 154;

    test(`solution is ${part1Solution ?? '?'} for part 1`, () => {
      const result = solvePart1(input);
      expect(result).toEqual(part1Solution);
    });
    test(`solution is ${part2Solution ?? '?'} for part 2`, () => {
      const result = solvePart2(input);
      expect(result).toEqual(part2Solution);
    });
  });
  describe('My input', () => {
    const input = `
      #.#########
      #.#...#...#
      #.#.#.#.#.#
      #..^..<.#.#
      #.###.###.#
      #.........#
      #########.#
    `;
    const part1Solution = 18;
    const part2Solution = 22;

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
    const part1Solution = 2310;
    const part2Solution = 6738;

    test(`solution is ${part1Solution ?? '?'} for part 1`, () => {
      const result = solvePart1(input);
      expect(result).toEqual(part1Solution);
    });
    test(`solution is ${part2Solution ?? '?'} for part 2`, () => {
      const result = solvePart2(input);
      expect(result).toEqual(part2Solution);
    });
  });

  // region Function Specific Tests
  describe('Make sure that', () => {
    test('graph from input works', () => {
      const input = `
        #.#########
        #.#.......#
        #.#.#####.#
        #..x.....x#
        ###.#####.#
        ###......x#
        #########.#
      `;
      // '1,0','3,3','9,3','9,5','9,6'
      const expectedEdges = new Set([
        '1,0--3,3 = 5',
        '3,3--1,0 = 5',

        // Only longest edge survives
        // '3,3--9,3 = 6',
        // '9,3--3,3 = 6',
        '3,3--9,3 = 10',
        '9,3--3,3 = 10',
        '3,3--9,5 = 8',
        '9,5--3,3 = 8',

        '9,3--9,5 = 2',
        '9,5--9,3 = 2',

        '9,5--9,6 = 1',
        '9,6--9,5 = 1',
      ]);

      const graph = gridToGraph(input.replaceAll('x', '.'));
      const edges = new Set<string>();
      for (const [from, toNodes] of graph.edges.entries()) {
        for (const [to, distance] of toNodes.entries()) {
          edges.add(`${from}--${to} = ${distance}`);
        }
      }
      expect(edges).toEqual(expectedEdges);
    })
  });
  // endregion
});
