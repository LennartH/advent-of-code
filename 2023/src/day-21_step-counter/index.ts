import { ArrayGrid, PlainPoint, pointToString } from '@util';
import { first, pipe } from 'iter-ops';
import { MinPriorityQueue } from 'datastructures-js';

export function solvePart1(input: string, numberOfSteps: number): number {
  const grid = ArrayGrid.fromInput(input);
  const start = pipe(
    grid.cells(),
    first(({value}) => value === 'S'),
  ).first?.position;
  if (start == null) {
    throw new Error('Unable to find start');
  }

  let count = 0;
  const visited = new Set<string>();
  const open = [{position: start, length: 0}];
  while (open.length > 0) {
    const {position, length} = open.pop()!;
    visited.add(`${pointToString(position)}|${length}`);
    if (length === numberOfSteps) {
      count++;
      continue;
    }

    for (const neighbour of grid.adjacentFrom(position)) {
      if (neighbour.value === '#' || visited.has(`${pointToString(neighbour.position)}|${length + 1}`)) {
        continue;
      }
      open.push({position: neighbour.position, length: length + 1});
    }
  }
  return count;
}

// TODO https://github.com/villuna/aoc23/wiki/A-Geometric-solution-to-advent-of-code-2023,-day-21
export function solvePart2(input: string, numberOfSteps: number): number {
  const grid = ArrayGrid.fromInput(input);
  if (grid.height !== grid.width) {
    throw new Error('Only works for square grids');
  }
  const gridLength = grid.width;

  const start = pipe(
    grid.cells(),
    first(({value}) => value === 'S'),
  ).first?.position;
  if (start == null) {
    throw new Error('Unable to find start');
  }
  if (start.x !== (gridLength - 1) / 2) {
    throw new Error('Only works if start is centered ')
  }

  const distances: {position: PlainPoint, length: number}[] = [];
  const visited = new Set<string>();
  const open = new MinPriorityQueue<{position: PlainPoint, length: number}>(({length}) => length);
  open.push({position: start, length: 0});
  while (open.size() > 0) {
    const current = open.pop()!;
    if (visited.has(pointToString(current.position))) {
      continue;
    }
    visited.add(pointToString(current.position));
    distances.push(current);

    for (const neighbour of grid.adjacentFrom(current.position)) {
      if (neighbour.value === '#' || visited.has(pointToString(neighbour.position))) {
        continue;
      }
      open.push({position: neighbour.position, length: current.length + 1});
    }
  }

  const evenPlots = distances.filter(({length}) => length % 2 === 0).length;
  const oddPlots = distances.filter(({length}) => length % 2 === 1).length;
  const evenCornerPlots = distances.filter(({length}) => length > 65 && length % 2 === 0).length;
  const oddCornerPlots = distances.filter(({length}) => length > 65 && length % 2 === 1).length;

  const fullGridSteps = Math.floor((numberOfSteps - start.x) / gridLength);
  const remainingSteps = (numberOfSteps - start.x) % (gridLength);
  if (fullGridSteps % 2 !== 0) {
    throw new Error('Only works with an even amount of full grid steps (should be 202300 anyway)');
  }
  if (remainingSteps !== 0) {
    throw new Error('Only works if the steps are just enough to reach the end of a grid');
  }

  console.log(fullGridSteps);
  const fullEvenGrids = fullGridSteps * fullGridSteps;
  const fullOddGrids = (fullGridSteps + 1) * (fullGridSteps + 1);

  return (fullOddGrids * oddPlots)
       + (fullEvenGrids * evenPlots)
       - ((fullGridSteps + 1) * oddCornerPlots)
       + (fullGridSteps * evenCornerPlots);
}
