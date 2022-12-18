import { parseGraph, releasePressure } from './index';
import { readFile } from '@util';

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
      const releasedPressure = releasePressure(graph, 30, 1);
      expect(releasedPressure).toEqual(1651);
    });
    test('solution is 1707 for part 2', () => {
      const graph = parseGraph(input);
      const releasedPressure = releasePressure(graph, 26, 2);
      expect(releasedPressure).toEqual(1707);
    });
  });
  describe('solution is', () => {
    test('2359 for part 1', () => {
      const graph = parseGraph(readFile(`${__dirname}/input`));
      const releasedPressure = releasePressure(graph, 30, 1);
      expect(releasedPressure).toEqual(2359);
    });
    test('2999 for part 2', () => {
      const graph = parseGraph(readFile(`${__dirname}/input`));
      const releasedPressure = releasePressure(graph, 26, 2);
      expect(releasedPressure).toEqual(2999);
    });
  });

  // region Tests for smaller parts
  // endregion
});
