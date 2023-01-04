import { formatGrid, readFile } from '@util';
import { followInstructions, parseTreasureMap } from './index';

describe('Day 22', () => {
  describe('example input', () => {
    const input = `
        ...#
        .#..
        #...
        ....
...#.......#
........#...
..#....#....
..........#.
        ...#....
        .....#..
        .#......
        ......#.

10R5L5R10L4R5L5`.substring(1);

    test('solution is 6032 for part 1', () => {
      const map = parseTreasureMap(input);
      const password = followInstructions(map);
      expect(password).toEqual(6032);
    });
    test.skip('solution is ? for part 2', () => {
      throw new Error('Not implemented')
    });
  });
  describe('solution is', () => {
    const inputPath = `${__dirname}/input`;
    const input = readFile(inputPath, false);
    test('88268 for part 1', () => {
      const map = parseTreasureMap(input);
      const password = followInstructions(map);
      expect(password).toEqual(88268);
    });
    test.skip('? for part 2', () => {
      throw new Error('Not implemented')
    });
  });

  // region Tests for smaller parts
  describe('test', () => {
    test('parse map', () => {
      const map = parseTreasureMap(`
   #...
   ....
......#.
...#....
..#.....

10R5L5`.substring(1));

      expect(map.start).toEqual({x: 3, y: 0});
      expect(map.instructions).toEqual([10, 'R', 5, 'L', 5]);
      expect(formatGrid(map.grid, { valueFormatter: (v) => v ?? ' ' }))
        .toEqual(cleanExpectedString(`
          ---#...-
          ---....-
          ......#.
          ...#....
          ..#.....
        `));
    })

    function cleanExpectedString(expected: string): string {
      return expected
        .trim().split('\n')
        .map((l) => l.trim()).join('\n')
        .replaceAll('-', ' ');
    }
  })
  // endregion
});
