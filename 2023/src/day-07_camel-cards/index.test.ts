import { readFile } from '@util';
import { parseHand, solvePart1, solvePart2 } from './index';

describe('Day 7: Camel Cards', () => {
  describe('Example input', () => {
    const input = `
      32T3K 765
      T55J5 684
      KK677 28
      KTJJT 220
      QQQJA 483
    `;
    const part1Solution = 6440;
    const part2Solution = 5905;

    test(`solution is ${part1Solution ?? '?'} for part 1`, () => {
      const result = solvePart1(input);
      expect(result).toEqual(part1Solution);
    });
    test(`solution is ${part2Solution ?? '?'} for part 2`, () => {
      const result = solvePart2(input);
      expect(result).toEqual(part2Solution);
    });
  });

  describe('Real input', () => {
    const inputPath = `${__dirname}/input`;
    const input = readFile(inputPath);
    const part1Solution = 255048101;
    const part2Solution = 253718286;

    test(`solution is ${part1Solution ?? '?'} for part 1`, () => {
      const result = solvePart1(input);
      expect(result).toEqual(part1Solution);
    });
    test(`solution is ${part2Solution ?? '?'} for part 2`, () => {
      const result = solvePart2(input);
      expect(result).toEqual(part2Solution);
    });
  });

  // region Function Specific Tests
  describe('Make sure that', () => {
    test('jokers do not automatically result in two pairs', () => {
      const hand = parseHand('2345J', 'with jokers');
      expect(hand.rank).toBe(2);
    });
    test('one joker and one pair is three of a kind and not a full house', () => {
      const hand = parseHand('3345J', 'with jokers');
      expect(hand.rank).toBe(4);
    });
    test('AQ9JJ is three of a kind', () => {
      const hand = parseHand('AQ9JJ', 'with jokers');
      expect(hand.rank).toBe(4);
    })
  });
  // endregion
});
