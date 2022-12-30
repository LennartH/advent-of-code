import { readFile } from '@util';
import {
  calculateDropletSurfaceArea,
  calculateExposedDropletSurfaceArea, dropletAsString,
  parseDroplet
} from './index';

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
    test('solution is 58 for part 2', () => {
      const droplet = parseDroplet(input);
      const surfaceArea = calculateExposedDropletSurfaceArea(droplet);
      dropletAsString(droplet).forEach((s) => console.log(s));
      expect(surfaceArea).toEqual(58);
    });
  });
  describe('solution is', () => {
    const inputPath = `${__dirname}/input`;
    const input = readFile(inputPath);
    test('3432 for part 1', () => {
      const droplet = parseDroplet(input);
      const surfaceArea = calculateDropletSurfaceArea(droplet);
      expect(surfaceArea).toEqual(3432);

      dropletAsString(droplet).forEach((s) => console.log(s));
    });
    test('2042 for part 2', () => {
      const droplet = parseDroplet(input);
      const surfaceArea = calculateExposedDropletSurfaceArea(droplet);
      expect(surfaceArea).toEqual(2042);
    });
  });
});
