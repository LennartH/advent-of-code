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
    test.skip('solution is ? for part 2', () => {
      throw new Error('Not implemented')
    });
  });
  describe('solution is', () => {
    const inputPath = `${__dirname}/input`;
    test('3191 for part 1', () => {
      const chamber = createCaveChamber(readFile(inputPath));
      processFallingRocks(chamber, 2022);
      expect(chamber.stoppedRocksHeight).toEqual(3191);
    });
    test.skip('? for part 2', () => {
      throw new Error('Not implemented')
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
  // endregion
});
