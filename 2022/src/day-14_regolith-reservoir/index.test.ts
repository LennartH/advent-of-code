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
    test('solution is 93 for part 2', () => {
      const sandOrigin = {x: 500, y: 0};
      const cave = parseCave(input);
      cave.hasFloor = true;
      const sandCount = simulateSandfall(cave, sandOrigin);
      console.log(caveAsString(cave));
      expect(sandCount).toEqual(93);
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
    test('30367 for part 2', () => {
      const sandOrigin = {x: 500, y: 0};
      const cave = parseCave(readFile(`${__dirname}/input`));
      cave.hasFloor = true;
      const sandCount = simulateSandfall(cave, sandOrigin);
      console.log(caveAsString(cave));
      expect(sandCount).toEqual(30367);
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
