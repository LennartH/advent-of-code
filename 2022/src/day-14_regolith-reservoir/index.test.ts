import { readFile, splitLines } from '../../../util/util';
import { caveAsString, parseCave, simulateSandfall } from './index';

describe('day-14', () => {
  describe('example input', () => {
    const input = `
      498,4 -> 498,6 -> 496,6
      503,4 -> 502,4 -> 502,9 -> 494,9
    `;

    test('solution is 24 for part 1', () => {
      const sandOrigin = {x: 500, y: 0};
      const cave = parseCave(input);
      const sandCount = simulateSandfall(cave, sandOrigin);
      console.log(caveAsString(cave));
      expect(sandCount).toEqual(24);
    });
    test.skip('solution is ? for part 2', () => {
      const cave = parseCave(input);
      throw new Error('Not implemented')
    });
  });
  describe('solution is', () => {
    test('592 for part 1', () => {
      const sandOrigin = {x: 500, y: 0};
      const cave = parseCave(readFile(`${__dirname}/input`));
      const sandCount = simulateSandfall(cave, sandOrigin);
      console.log(caveAsString(cave));
      expect(sandCount).toEqual(592);
    });
    test.skip('? for part 2', () => {
      const cave = parseCave(readFile(`${__dirname}/input`));
      throw new Error('Not implemented')
    });
  });

  // region Tests for smaller parts
  describe('parse cave', () => {
    const input = `
      498,4 -> 498,6 -> 496,6
      503,4 -> 502,4 -> 502,9 -> 494,9
    `;
    const cave = parseCave(input);

    test('matches string representation', () => {
      const expectedOutput = splitLines(`
        ..........
        ..........
        ..........
        ..........
        ....#...##
        ....#...#.
        ..###...#.
        ........#.
        ........#.
        #########.
      `).join('\n');
      expect(caveAsString(cave)).toEqual(expectedOutput);
    })
  })
  // endregion
})
