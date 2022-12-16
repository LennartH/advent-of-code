import { readFile, splitLines } from '../../../util/util';
import { countExclusionSizeInRow, findDistressTuningFrequency, parseSensors } from './index';

describe('day-15', () => {
  describe('example input', () => {
    const input = `
      Sensor at x=2, y=18: closest beacon is at x=-2, y=15
      Sensor at x=9, y=16: closest beacon is at x=10, y=16
      Sensor at x=13, y=2: closest beacon is at x=15, y=3
      Sensor at x=12, y=14: closest beacon is at x=10, y=16
      Sensor at x=10, y=20: closest beacon is at x=10, y=16
      Sensor at x=14, y=17: closest beacon is at x=10, y=16
      Sensor at x=8, y=7: closest beacon is at x=2, y=10
      Sensor at x=2, y=0: closest beacon is at x=2, y=10
      Sensor at x=0, y=11: closest beacon is at x=2, y=10
      Sensor at x=20, y=14: closest beacon is at x=25, y=17
      Sensor at x=17, y=20: closest beacon is at x=21, y=22
      Sensor at x=16, y=7: closest beacon is at x=15, y=3
      Sensor at x=14, y=3: closest beacon is at x=15, y=3
      Sensor at x=20, y=1: closest beacon is at x=15, y=3
    `;

    test('solution is 26 for part 1', () => {
      const sensors = parseSensors(input);
      const exclusionSize = countExclusionSizeInRow(sensors, 10);
      expect(exclusionSize).toEqual(26);
    });
    test('solution is 56000011 for part 2', () => {
      const sensors = parseSensors(input);
      const tuningFrequency = findDistressTuningFrequency(sensors, 0, 20);
      expect(tuningFrequency).toEqual(56000011);
    });
  });
  describe('solution is', () => {
    test('5838453 for part 1', () => {
      const sensors = parseSensors(readFile(`${__dirname}/input`));
      const exclusionSize = countExclusionSizeInRow(sensors, 2000000);
      expect(exclusionSize).toEqual(5838453);
    });
    test('12413999391794 for part 2', () => {
      const sensors = parseSensors(readFile(`${__dirname}/input`));
      const tuningFrequency = findDistressTuningFrequency(sensors, 0, 4000000);
      expect(tuningFrequency).toEqual(12413999391794);
    });
  });

  // region Tests for smaller parts
  describe('parse input', () => {
    test('simple input', () => {
      const input = `
        Sensor at x=2, y=18: closest beacon is at x=-2, y=15
        Sensor at x=9, y=16: closest beacon is at x=10, y=16
      `;
      const sensors = parseSensors(input);
      const expectedSensors = [
        { position: {x: 2, y: 18}, closestBeacon: {x: -2, y: 15}, detectionRadius: 7 },
        { position: {x: 9, y: 16}, closestBeacon: {x: 10, y: 16}, detectionRadius: 1 },
      ];
      expect(sensors).toEqual(expectedSensors);
    })
  })
  // endregion
})
