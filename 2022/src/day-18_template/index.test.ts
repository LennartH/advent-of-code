import { readFile } from '@util';
import { calculateDropletSurfaceArea, parseDroplet } from './index';

describe('Day 18', () => {
  describe('example input', () => {
    const input = `
      2,2,2
      1,2,2
      3,2,2
      2,1,2
      2,3,2
      2,2,1
      2,2,3
      2,2,4
      2,2,6
      1,2,5
      3,2,5
      2,1,5
      2,3,5
    `;

    test('solution is 64 for part 1', () => {
      const droplet = parseDroplet(input);
      const surfaceArea = calculateDropletSurfaceArea(droplet);
      expect(surfaceArea).toEqual(64);
    });
    test.skip('solution is ? for part 2', () => {
      throw new Error('Not implemented')
    });
  });
  describe('solution is', () => {
    const inputPath = `${__dirname}/input`;
    const input = readFile(inputPath);
    test('3432 for part 1', () => {
      const droplet = parseDroplet(input);
      const surfaceArea = calculateDropletSurfaceArea(droplet);
      expect(surfaceArea).toEqual(3432);
    });
    test.skip('? for part 2', () => {
      throw new Error('Not implemented')
    });
  });

  // region Tests for smaller parts
  describe('test', () => {
    test('parse droplet with 2 voxel', () => {
      const input = '1,1,1\n2,1,1';
      const droplet = parseDroplet(input);
      expect(droplet).toEqual({
        voxel: [{x: 1, y: 1, z: 1}, {x: 2, y: 1, z: 1}],
        isOccupied: [, [, [, true, true] ] ]
      })
    })
    test('droplet with 2 voxel has a surface area of 10', () => {
      const input = '1,1,1\n2,1,1';
      const droplet = parseDroplet(input);
      const surfaceArea = calculateDropletSurfaceArea(droplet);
      expect(surfaceArea).toEqual(10);
    })
  })
  // endregion
});
