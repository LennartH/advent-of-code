import { createCaveChamber, processFallingRocks } from './index';

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
    test('? for part 1', () => {
      throw new Error('Not implemented')
    });
    test.skip('? for part 2', () => {
      throw new Error('Not implemented')
    });
  });

  // region Tests for smaller parts
  test('height is 7 for example after 4 rocks', () => {
    const chamber = createCaveChamber('>>><<><>><<<>><>>><<<>>><<<><<<>><>><<>>');
    processFallingRocks(chamber, 4);
    expect(chamber.stoppedRocksHeight).toEqual(7);
  })
  // endregion
});
