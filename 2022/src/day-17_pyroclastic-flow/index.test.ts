import { chamberAsString, createCaveChamber, processFallingRocks } from './index';
import { readFile } from '@util';

describe('Day 17', () => {
  describe('example input', () => {
    const input = '>>><<><>><<<>><>>><<<>>><<<><<<>><>><<>>';

    test('solution is 3068 for part 1', () => {
      const chamber = createCaveChamber(input);
      processFallingRocks(chamber, 2022);
      expect(chamber.stoppedRocksHeight).toEqual(3068);
    });
    test('solution is 1514285714288 for part 2', () => {
      const chamber = createCaveChamber(input);
      processFallingRocks(chamber, 1000000000000);
      expect(chamber.stoppedRocksHeight).toEqual(1514285714288);
    });
  });
  describe('solution is', () => {
    const inputPath = `${__dirname}/input`;
    test('3191 for part 1', () => {
      const chamber = createCaveChamber(readFile(inputPath));
      processFallingRocks(chamber, 2022);
      expect(chamber.stoppedRocksHeight).toEqual(3191);
    });
    test('1572093023267 for part 2', () => {
      const chamber = createCaveChamber(readFile(inputPath));
      processFallingRocks(chamber, 1000000000000);
      expect(chamber.stoppedRocksHeight).toEqual(1572093023267);
    });
  });

  // region Tests for smaller parts
  describe('chamber after 3 rocks', () => {
    const chamber = createCaveChamber('>>><<><>><<<>><>>><<<>>><<<><<<>><>><<>>');
    processFallingRocks(chamber, 3);

    test('looks correct', () => {
      expect(chamberAsString(chamber)).toEqual(`
        |..#....|
        |..#....|
        |####...|
        |..###..|
        |...#...|
        |..####.|
        +-------+
      `.trim().split('\n').map((l) => l.trim()).join('\n'));
    })
    test('has height of 6', () => {
      expect(chamber.stoppedRocksHeight).toEqual(6);
    })
  })
  describe('chamber after 10 rocks', () => {
    const chamber = createCaveChamber('>>><<><>><<<>><>>><<<>>><<<><<<>><>><<>>');
    processFallingRocks(chamber, 10);
    test('looks correct', () => {
      expect(chamberAsString(chamber)).toEqual(`
        |....#..|
        |....#..|
        |....##.|
        |##..##.|
        |######.|
        |.###...|
        |..#....|
        |.####..|
        |....##.|
        |....##.|
        |....#..|
        |..#.#..|
        |..#.#..|
        |#####..|
        |..###..|
        |...#...|
        |..####.|
        +-------+
      `.trim().split('\n').map((l) => l.trim()).join('\n'));
    })
    test('has height of 17', () => {
      expect(chamber.stoppedRocksHeight).toEqual(17);
    })
  })
  describe('chamber after 11 rocks', () => {
    const chamber = createCaveChamber('>>><<><>><<<>><>>><<<>>><<<><<<>><>><<>>');
    processFallingRocks(chamber, 11);

    test('looks correct', () => {
      expect(chamberAsString(chamber)).toEqual(`
        |...####|
        |....#..|
        |....#..|
        |....##.|
        |##..##.|
        |######.|
        |~~~~~~~|
      `.trim().split('\n').map((l) => l.trim()).join('\n'));
    })
    test('has height of 18', () => {
      expect(chamber.stoppedRocksHeight).toEqual(18);
    })
  })
  describe('chamber after 35 rocks', () => {
    const chamber = createCaveChamber('>>><<><>><<<>><>>><<<>>><<<><<<>><>><<>>');
    processFallingRocks(chamber, 35);

    test('looks correct', () => {
      expect(chamberAsString(chamber)).toEqual(`
        |....#..|
        |....#..|
        |....#..|
        |....#..|
        |.##.#..|
        |.##.#..|
        |..###..|
        |....#..|
        |...###.|
        |#...#..|
        |#####..|
        |#.#....|
        |#.#....|
        |####...|
        |..#####|
        |~~~~~~~|
      `.trim().split('\n').map((l) => l.trim()).join('\n'));
    })
    test('has height of 60', () => {
      expect(chamber.stoppedRocksHeight).toEqual(60);
    })
  })
  describe('chamber after 100 rocks', () => {
    const chamber = createCaveChamber('>>><<><>><<<>><>>><<<>>><<<><<<>><>><<>>');

    test('looks correct', () => {
      processFallingRocks(chamber, 100);
      expect(chamberAsString(chamber)).toEqual(`
        |#......|
        |#......|
        |#.#....|
        |#.#....|
        |####...|
        |..#####|
        |~~~~~~~|
      `.trim().split('\n').map((l) => l.trim()).join('\n'));
    })
    test('has height of 157', () => {
      processFallingRocks(chamber, 100);
      expect(chamber.stoppedRocksHeight).toEqual(157);
    })
  })
  // endregion
});
