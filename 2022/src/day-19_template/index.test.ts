import { readFile } from '@util';
import { calculateFactoryQuality, parseRobotFactory } from './index';

describe('Day 19', () => {
  describe('example input', () => {
    // Blueprint 1:
    //   Each ore robot costs 4 ore.
    //   Each clay robot costs 2 ore.
    //   Each obsidian robot costs 3 ore and 14 clay.
    //   Each geode robot costs 2 ore and 7 obsidian.
    //
    // Blueprint 2:
    //   Each ore robot costs 2 ore.
    //   Each clay robot costs 3 ore.
    //   Each obsidian robot costs 3 ore and 8 clay.
    //   Each geode robot costs 3 ore and 12 obsidian.
    const input = `
      Blueprint 1: Each ore robot costs 4 ore. Each clay robot costs 2 ore. Each obsidian robot costs 3 ore and 14 clay. Each geode robot costs 2 ore and 7 obsidian.
      Blueprint 2: Each ore robot costs 2 ore. Each clay robot costs 3 ore. Each obsidian robot costs 3 ore and 8 clay. Each geode robot costs 3 ore and 12 obsidian.
    `;

    test('parse robot factory', () => {
      const factory = parseRobotFactory(input);
      expect(factory).toEqual({
        blueprints: [
          {
            ore: { ore: 4 },
            clay: { ore: 2 },
            obsidian: { ore: 3, clay: 14 },
            geode: { ore: 2, obsidian: 7 },
          },
          {
            ore: { ore: 2 },
            clay: { ore: 3 },
            obsidian: { ore: 3, clay: 8 },
            geode: { ore: 3, obsidian: 12 },
          },
        ],
      })
    })
    test('solution is 33 for part 1', () => {
      const factory = parseRobotFactory(input);
      const quality = calculateFactoryQuality(factory, 24);
      expect(quality).toEqual({
        total: 33,
        byBlueprint: [9, 12],
      });
    });
    test.skip('solution is ? for part 2', () => {
      throw new Error('Not implemented')
    });
  });
  describe('solution is', () => {
    const inputPath = `${__dirname}/input`;
    const input = readFile(inputPath);
    test('? for part 1', () => {
      const factory = parseRobotFactory(input);
      const quality = calculateFactoryQuality(factory, 24);
      expect(quality.total).toEqual(33);
    });
    test.skip('? for part 2', () => {
      throw new Error('Not implemented')
    });
  });

  // region Tests for smaller parts
  // endregion
});
