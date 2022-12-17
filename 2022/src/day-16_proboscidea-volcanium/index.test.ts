import { readFile } from '../../../util/util';
import { parseGraph, releasePressure } from './index';

describe('day-16', () => {
  describe('example input', () => {
    const input = `
      Valve AA has flow rate=0; tunnels lead to valves DD, II, BB
      Valve BB has flow rate=13; tunnels lead to valves CC, AA
      Valve CC has flow rate=2; tunnels lead to valves DD, BB
      Valve DD has flow rate=20; tunnels lead to valves CC, AA, EE
      Valve EE has flow rate=3; tunnels lead to valves FF, DD
      Valve FF has flow rate=0; tunnels lead to valves EE, GG
      Valve GG has flow rate=0; tunnels lead to valves FF, HH
      Valve HH has flow rate=22; tunnel leads to valve GG
      Valve II has flow rate=0; tunnels lead to valves AA, JJ
      Valve JJ has flow rate=21; tunnel leads to valve II
    `;

    test('solution is 1651 for part 1', () => {
      const graph = parseGraph(input);
      const releasedPressure = releasePressure(graph, 30);
      expect(releasedPressure).toEqual(1651);
    });
    test.skip('solution is ? for part 2', () => {
      throw new Error('Not implemented');
    });
  });
  describe('solution is', () => {
    test('? for part 1', () => {
      const graph = parseGraph(readFile(`${__dirname}/input`));
      const releasedPressure = releasePressure(graph, 30);
      expect(releasedPressure).toEqual(1651);
    });
    test.skip('? for part 2', () => {
      throw new Error('Not implemented');
    });
  });

  // region Tests for smaller parts
  // endregion
})
