import { ArrayGrid, getDirections, Grid, PlainPoint, pointToString, splitLines, translateBy } from '@util';
import { first, map, pipe } from 'iter-ops';

// region Types and Globals

// endregion

export function solvePart1(input: string, numberOfSteps: number): number {
  const grid = ArrayGrid.fromInput(input);
  const start = pipe(
    grid.cells(),
    first(({value}) => value === 'S'),
  ).first?.position;
  if (start == null) {
    throw new Error('Unable to find start');
  }
  return countPathsWithLengthFromPosition(grid, start, numberOfSteps);
}

export function solvePart2(input: string): number {
  const lines = splitLines(input);
  // TODO Implement solution
  return Number.NaN;
}

// region Shared Code
function countPathsWithLengthFromPosition(grid: Grid<string>, start: PlainPoint, targetLength: number): number {
  let count = 0;
  const visited = new Set<string>();
  const open = [{position: start, length: 0}];
  while (open.length > 0) {
    const {position, length} = open.pop()!;
    const key = `${pointToString(position)}|${length}`;
    if (visited.has(key)) {
      continue;
    }
    visited.add(key);
    if (length === targetLength) {
      count++;
      continue;
    }

    for (const neighbour of grid.adjacentFrom(position)) {
      if (neighbour.value === '#') {
        continue;
      }
      open.push({position: neighbour.position, length: length + 1});
    }
  }
  return count;
}
// endregion
