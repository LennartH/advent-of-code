import { readFile } from '../../../util/util';
import { collectPossiblePaths, parseGraph, releasePressure } from './index';

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
    test('2359 for part 1', () => {
      const graph = parseGraph(readFile(`${__dirname}/input`));
      const releasedPressure = releasePressure(graph, 30);
      expect(releasedPressure).toEqual(2359);
    });
    test.skip('? for part 2', () => {
      throw new Error('Not implemented');
    });
  });

  // region Tests for smaller parts
  describe('possible paths of puzzle input', () => {
    test.each<[number, string[]]>([[5, ['AY', 'GJ', 'HX', 'PB', 'PH']]])('for time %s', (time, expected) => {
      const graph = parseGraph(readFile(`${__dirname}/input`));
      const paths = collectPossiblePaths(graph, time)
        .map((p) => p.map((n) => n.label).join('-'))
        .sort();
      expect(paths).toEqual(expected);
    });
  });

  test('collect possible paths with enough time', () => {
    const input = `
      Valve AA has flow rate=0; tunnels lead to valves BB, CC, DD
      Valve BB has flow rate=1; tunnels lead to valves AA, DD
      Valve CC has flow rate=1; tunnels lead to valves AA, DD
      Valve DD has flow rate=0; tunnels lead to valves AA, BB, CC, EE, FF
      Valve EE has flow rate=1; tunnels lead to valves DD, FF
      Valve FF has flow rate=1; tunnels lead to valves DD, EE
    `;
    const graph = parseGraph(input);
    const paths = collectPossiblePaths(graph, Number.MAX_SAFE_INTEGER).map((p) => p.map((n) => n.label).join('-'));
    expect(paths).toEqual([
      'BB-CC-EE-FF',
      'BB-CC-FF-EE',
      'BB-EE-CC-FF',
      'BB-EE-FF-CC',
      'BB-FF-CC-EE',
      'BB-FF-EE-CC',

      'CC-BB-EE-FF',
      'CC-BB-FF-EE',
      'CC-EE-BB-FF',
      'CC-EE-FF-BB',
      'CC-FF-BB-EE',
      'CC-FF-EE-BB',

      'EE-BB-CC-FF',
      'EE-BB-FF-CC',
      'EE-CC-BB-FF',
      'EE-CC-FF-BB',
      'EE-FF-BB-CC',
      'EE-FF-CC-BB',

      'FF-BB-CC-EE',
      'FF-BB-EE-CC',
      'FF-CC-BB-EE',
      'FF-CC-EE-BB',
      'FF-EE-BB-CC',
      'FF-EE-CC-BB',
    ]);
  });
  describe('collect possible paths reaching all nodes', () => {
    const input = `
      Valve AA has flow rate=0; tunnels lead to valves BB, CC, DD
      Valve BB has flow rate=1; tunnels lead to valves AA, DD
      Valve CC has flow rate=1; tunnels lead to valves AA, DD
      Valve DD has flow rate=0; tunnels lead to valves AA, BB, CC, EE, FF
      Valve EE has flow rate=1; tunnels lead to valves DD, FF, GG
      Valve FF has flow rate=1; tunnels lead to valves DD, EE, GG
      Valve GG has flow rate=1; tunnels lead to valves EE, FF, HH
      Valve HH has flow rate=0; tunnels lead to valves GG, II
      Valve II has flow rate=0; tunnels lead to valves HH, JJ
      Valve JJ has flow rate=1; tunnels lead to valves II
    `;

    test('for time 12', () => {
      const graph = parseGraph(input);
      const paths = collectPossiblePaths(graph, 12)
        .map((p) => p.map((n) => n.label).join('-'))
        .sort();
      expect(paths).toEqual([
        'BB-CC-EE-FF',
        'BB-CC-EE-GG',
        'BB-CC-FF-EE',
        'BB-CC-FF-GG',
        'BB-CC-GG-EE',
        'BB-CC-GG-FF',
        'BB-EE-CC-FF',
        'BB-EE-FF-CC',
        'BB-EE-FF-GG',
        'BB-EE-GG-CC',
        'BB-EE-GG-FF',
        'BB-EE-GG-JJ',
        'BB-EE-JJ',
        'BB-FF-CC-EE',
        'BB-FF-EE-CC',
        'BB-FF-EE-GG',
        'BB-FF-GG-CC',
        'BB-FF-GG-EE',
        'BB-FF-GG-JJ',
        'BB-FF-JJ',
        'BB-GG-CC',
        'BB-GG-EE-CC',
        'BB-GG-EE-FF',
        'BB-GG-FF-CC',
        'BB-GG-FF-EE',
        'BB-GG-JJ',
        'BB-JJ',
        'CC-BB-EE-FF',
        'CC-BB-EE-GG',
        'CC-BB-FF-EE',
        'CC-BB-FF-GG',
        'CC-BB-GG-EE',
        'CC-BB-GG-FF',
        'CC-EE-BB-FF',
        'CC-EE-FF-BB',
        'CC-EE-FF-GG',
        'CC-EE-GG-BB',
        'CC-EE-GG-FF',
        'CC-EE-GG-JJ',
        'CC-EE-JJ',
        'CC-FF-BB-EE',
        'CC-FF-EE-BB',
        'CC-FF-EE-GG',
        'CC-FF-GG-BB',
        'CC-FF-GG-EE',
        'CC-FF-GG-JJ',
        'CC-FF-JJ',
        'CC-GG-BB',
        'CC-GG-EE-BB',
        'CC-GG-EE-FF',
        'CC-GG-FF-BB',
        'CC-GG-FF-EE',
        'CC-GG-JJ',
        'CC-JJ',
        'EE-BB-CC',
        'EE-BB-FF-GG',
        'EE-BB-GG',
        'EE-CC-BB',
        'EE-CC-FF-GG',
        'EE-CC-GG',
        'EE-FF-BB-CC',
        'EE-FF-CC-BB',
        'EE-FF-GG-BB',
        'EE-FF-GG-CC',
        'EE-FF-GG-JJ',
        'EE-FF-JJ',
        'EE-GG-BB',
        'EE-GG-CC',
        'EE-GG-FF-BB',
        'EE-GG-FF-CC',
        'EE-GG-JJ',
        'EE-JJ',
        'FF-BB-CC',
        'FF-BB-EE-GG',
        'FF-BB-GG',
        'FF-CC-BB',
        'FF-CC-EE-GG',
        'FF-CC-GG',
        'FF-EE-BB-CC',
        'FF-EE-CC-BB',
        'FF-EE-GG-BB',
        'FF-EE-GG-CC',
        'FF-EE-GG-JJ',
        'FF-EE-JJ',
        'FF-GG-BB',
        'FF-GG-CC',
        'FF-GG-EE-BB',
        'FF-GG-EE-CC',
        'FF-GG-JJ',
        'FF-JJ',
        'GG-BB-CC',
        'GG-BB-EE',
        'GG-BB-FF',
        'GG-CC-BB',
        'GG-CC-EE',
        'GG-CC-FF',
        'GG-EE-BB',
        'GG-EE-CC',
        'GG-EE-FF-BB',
        'GG-EE-FF-CC',
        'GG-EE-JJ',
        'GG-FF-BB',
        'GG-FF-CC',
        'GG-FF-EE-BB',
        'GG-FF-EE-CC',
        'GG-FF-JJ',
        'GG-JJ',
        'JJ-GG',
      ]);
    });
  });
  describe('collect possible paths with unreachable nodes', () => {
    const input = `
      Valve AA has flow rate=0; tunnels lead to valves BB, CC, DD
      Valve BB has flow rate=1; tunnels lead to valves AA, DD
      Valve CC has flow rate=1; tunnels lead to valves AA, DD
      Valve DD has flow rate=0; tunnels lead to valves AA, BB, CC, EE, FF
      Valve EE has flow rate=1; tunnels lead to valves DD, FF, GG
      Valve FF has flow rate=1; tunnels lead to valves DD, EE, GG
      Valve GG has flow rate=1; tunnels lead to valves EE, FF, HH
      Valve HH has flow rate=0; tunnels lead to valves GG, II
      Valve II has flow rate=0; tunnels lead to valves HH, JJ
      Valve JJ has flow rate=1; tunnels lead to valves II
    `;

    test('for time 4', () => {
      const graph = parseGraph(input);
      const paths = collectPossiblePaths(graph, 4).map((p) => p.map((n) => n.label).join('-'));
      expect(paths).toEqual(['BB', 'CC', 'EE', 'FF']);
    });
    test('for time 5', () => {
      const graph = parseGraph(input);
      const paths = collectPossiblePaths(graph, 5).map((p) => p.map((n) => n.label).join('-'));
      expect(paths).toEqual(['BB', 'CC', 'EE', 'FF', 'GG']);
    });
    test('for time 6', () => {
      const graph = parseGraph(input);
      const paths = collectPossiblePaths(graph, 6).map((p) => p.map((n) => n.label).join('-'));
      expect(paths).toEqual([
        'GG',
        'BB-CC',
        'BB-EE',
        'BB-FF',
        'CC-BB',
        'CC-EE',
        'CC-FF',
        'EE-FF',
        'EE-GG',
        'FF-EE',
        'FF-GG',
      ]);
    });
    test('for time 8', () => {
      const graph = parseGraph(input);
      const paths = collectPossiblePaths(graph, 8).map((p) => p.map((n) => n.label).join('-'));
      expect(paths).toEqual([
        'JJ',
        'BB-CC',
        'BB-GG',
        'CC-BB',
        'CC-GG',
        'EE-BB',
        'EE-CC',
        'FF-BB',
        'FF-CC',
        'GG-EE',
        'GG-FF',
        'BB-EE-FF',
        'BB-EE-GG',
        'BB-FF-EE',
        'BB-FF-GG',
        'CC-EE-FF',
        'CC-EE-GG',
        'CC-FF-EE',
        'CC-FF-GG',
        'EE-FF-GG',
        'EE-GG-FF',
        'FF-EE-GG',
        'FF-GG-EE',
      ]);
    });
  });
  // endregion
});
