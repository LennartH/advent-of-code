import { formatGrid, readFile } from '@util';
import { Direction, FaceDefinition, followInstructions, parseTreasureMap } from './index';

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

    const cubeFaces: FaceDefinition[] = [
      {
        id: '1',
        position: { x: 8, y: 0 },
        size: { width: 4, height: 4 },
        neighbours: {
          [Direction.Left]: '3',
          [Direction.Up]: '2',
          [Direction.Right]: '6',
        },
      },

      {
        id: '2',
        position: { x: 0, y: 4 },
        size: { width: 4, height: 4 },
        neighbours: {
          [Direction.Left]: '6',
          [Direction.Up]: '1',
          [Direction.Down]: '5',
        },
      },
      {
        id: '3',
        position: { x: 4, y: 4 },
        size: { width: 4, height: 4 },
        neighbours: {
          [Direction.Up]: '1',
          [Direction.Down]: '5',
        },
      },
      {
        id: '4',
        position: { x: 8, y: 4 },
        size: { width: 4, height: 4 },
        neighbours: {
          [Direction.Right]: '6',
        },
      },

      {
        id: '5',
        position: { x: 8, y: 8 },
        size: { width: 4, height: 4 },
        neighbours: {
          [Direction.Left]: '3',
          [Direction.Down]: '2',
        },
      },
      {
        id: '6',
        position: { x: 12, y: 8 },
        size: { width: 4, height: 4 },
        neighbours: {
          [Direction.Up]: '4',
          [Direction.Right]: '1',
          [Direction.Down]: '2',
        },
      },
    ]

    test('solution is 6032 for part 1', () => {
      const map = parseTreasureMap(input);
      const password = followInstructions(map);
      expect(password).toEqual(6032);
    });
    test('solution is 5031 for part 2', () => {
      const map = parseTreasureMap(input);
      const password = followInstructions(map, cubeFaces);
      expect(password).toEqual(5031);
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
    test('? for part 2', () => {
      const map = parseTreasureMap(input);
      const password = followInstructions(map, []);
      expect(password).toEqual(5031);
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
