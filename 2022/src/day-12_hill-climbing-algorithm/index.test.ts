import { Direction, readLines, splitLines } from '../../../util/util';
import { Node, findShortestPath, getEdges, gridAsString, readGrid, printRoute } from './index';

describe('day 12', () => {
  describe('example input', () => {
    const input = `
      Sabqponm
      abcryxxl
      accszExk
      acctuvwj
      abdefghi
    `;
    const lines = splitLines(input);

    test('returns 31 for part 1', () => {
      const grid = readGrid(lines);
      const shortestPath = findShortestPath(grid);
      console.log(printRoute(grid, shortestPath));
      expect(shortestPath.length).toEqual(31);
    });

    describe('read input', () => {
      const lines = ['Sa', 'cE'];
      const grid = readGrid(lines);

      test('start has elevation 0', () => {
        const start = grid[0][0];
        expect(start.elevation).toEqual(0);
      });
      test('end has elevation 25', () => {
        const start = grid[1][1];
        expect(start.elevation).toEqual(25);
      });
      test('creates expected grid', () => {
        expect(gridAsString(grid)).toEqual('Sa\ncE');
      });
    });
    describe('get edges', () => {
      const lines = ['Sb', 'cz'];
      const grid = readGrid(lines);
      const edges = getEdges(grid);
      test('can go up if difference is 1 at most', () => {
        const edgesOfStart = edges[0][0];
        expect(edgesOfStart).toEqual([Direction.Right]);
      });
      test('can go down anytime', () => {
        const edgesOfHighestPoint = edges[1][1];
        expect(edgesOfHighestPoint).toEqual([Direction.Top, Direction.Left]);
      });
    });
  });

  describe('solution is', () => {
    const grid = readGrid(readLines(`${__dirname}/input`));
    test('449 for part 1', () => {
      const shortestPath = findShortestPath(grid);
      console.log(printRoute(grid, shortestPath));
      expect(shortestPath.length).toEqual(449);
    });
  });
});
