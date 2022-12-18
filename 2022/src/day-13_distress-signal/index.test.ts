import { calculateDecoderKey, calculateOrderliness, isInOrder, orderPackets, PacketPair, parsePackets } from './index';
import { readFile, splitLines } from '@util';

describe('day-13', () => {
  describe('example input', () => {
    const input = `
      [1,1,3,1,1]
      [1,1,5,1,1]
      
      [[1],[2,3,4]]
      [[1],4]
      
      [9]
      [[8,7,6]]
      
      [[4,4],4,4]
      [[4,4],4,4,4]
      
      [7,7,7,7]
      [7,7,7]
      
      []
      [3]
      
      [[[]]]
      [[]]
      
      [1,[2,[3,[4,[5,6,7]]]],8,9]
      [1,[2,[3,[4,[5,6,0]]]],8,9]
    `;

    test('solution is 13 for part 1', () => {
      const packetPairs = parsePackets(input);
      const orderliness = calculateOrderliness(packetPairs);
      expect(orderliness).toEqual(13);
    });
    test('solution is 140 for part 2', () => {
      const packetPairs = parsePackets(input);
      const decoderKey = calculateDecoderKey(packetPairs);
      expect(decoderKey).toEqual(140);
    });

    test('parse input', () => {
      const packetPairs = parsePackets(input);
      expect(packetPairs).toEqual([
        [
          [1, 1, 3, 1, 1],
          [1, 1, 5, 1, 1],
        ],
        [
          [[1], [2, 3, 4]],
          [[1], 4],
        ],
        [[9], [[8, 7, 6]]],
        [
          [[4, 4], 4, 4],
          [[4, 4], 4, 4, 4],
        ],
        [
          [7, 7, 7, 7],
          [7, 7, 7],
        ],
        [[], [3]],
        [[[[]]], [[]]],
        [
          [1, [2, [3, [4, [5, 6, 7]]]], 8, 9],
          [1, [2, [3, [4, [5, 6, 0]]]], 8, 9],
        ],
      ]);
    });
    test('check ordered pair indices', () => {
      const packetPairs = parsePackets(input);
      const orderedIndices = packetPairs.map((p, i) => (isInOrder(p) ? i + 1 : -1)).filter((v) => v !== -1);
      expect(orderedIndices).toEqual([1, 2, 4, 6]);
    });
    test('check ordered packets', () => {
      const packetPairs = parsePackets(input);
      const orderedPackets = orderPackets(packetPairs);
      const expectedOutput = splitLines(`
        []
        [[]]
        [[[]]]
        [1,1,3,1,1]
        [1,1,5,1,1]
        [[1],[2,3,4]]
        [1,[2,[3,[4,[5,6,0]]]],8,9]
        [1,[2,[3,[4,[5,6,7]]]],8,9]
        [[1],4]
        [[2]]
        [3]
        [[4,4],4,4]
        [[4,4],4,4,4]
        [[6]]
        [7,7,7]
        [7,7,7,7]
        [[8,7,6]]
        [9]
      `).join('\n');
      expect(orderedPackets.map((p) => JSON.stringify(p)).join('\n')).toEqual(expectedOutput);
    });
  });
  describe('solution is', () => {
    test('5605 for part 1', () => {
      const packetPairs = parsePackets(readFile(`${__dirname}/input`));
      const orderliness = calculateOrderliness(packetPairs);
      expect(orderliness).toEqual(5605);
    });
    test('24969 for part 2', () => {
      const packetPairs = parsePackets(readFile(`${__dirname}/input`));
      const decoderKey = calculateDecoderKey(packetPairs);
      expect(decoderKey).toEqual(24969);
    });
  });

  describe('parse input', () => {
    test('of 1-dimensional packets', () => {
      const [packetPair] = parsePackets(`
          [1,1,3,1,1]
          [1,1,5,1,1]
        `);
      expect(packetPair).toEqual([
        [1, 1, 3, 1, 1],
        [1, 1, 5, 1, 1],
      ]);
    });
    test('of packet with large numbers', () => {
      const [packetPair] = parsePackets(`
          [123,1000]
          [9999,12345677]
        `);
      expect(packetPair).toEqual([
        [123, 1000],
        [9999, 12345677],
      ]);
    });
    test('of mixed packets', () => {
      const [packetPair] = parsePackets(`
          [[1],[2,3,4]]
          [[1],4]
        `);
      expect(packetPair).toEqual([
        [[1], [2, 3, 4]],
        [[1], 4],
      ]);
    });
    test('with empty packet', () => {
      const [packetPair] = parsePackets(`
          []
          [3]
        `);
      expect(packetPair).toEqual([[], [3]]);
    });
    test('of deep empty packets', () => {
      const [packetPair] = parsePackets(`
          [[[]]]
          [[]]
        `);
      expect(packetPair).toEqual([[[[]]], [[]]]);
    });
    test('of deep nested packets', () => {
      const [packetPair] = parsePackets(`
          [1,[2,[3,[4,[5,6,7]]]],8,9]
          [1,[2,[3,[4,[5,6,0]]]],8,9]
        `);
      expect(packetPair).toEqual([
        [1, [2, [3, [4, [5, 6, 7]]]], 8, 9],
        [1, [2, [3, [4, [5, 6, 0]]]], 8, 9],
      ]);
    });
  });
  describe('is in order', () => {
    test('pair starting with lists', () => {
      const pair: PacketPair = [
        [[4, 4], 4, 4],
        [[4, 4], 4, 4, 4],
      ];
      expect(isInOrder(pair)).toBe(true);
    });
  });
});
