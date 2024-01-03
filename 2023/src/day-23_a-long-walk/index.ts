import {
  ArrayGrid,
  directionFromName,
  getDirections,
  Grid,
  PlainPoint,
  pointsEqual,
  pointToString,
  StraightArrowDirectionName
} from '@util';
import { first, pipe } from 'iter-ops';

// region Types and Globals
const cardinalDirections = getDirections('cardinal', {withDiagonals: false});
// endregion

export function solvePart1(input: string): number {
  const grid = ArrayGrid.fromInput(input);
  const start = pipe(
    grid.row(0),
    first(({value}) => value === '.'),
  ).first?.position;
  if (start == null) {
    throw new Error('Start could not be found');
  }
  const exit = pipe(
    grid.row(grid.height - 1),
    first(({value}) => value === '.'),
  ).first?.position;
  if (exit == null) {
    throw new Error('Start could not be found');
  }
  return longestPath(start, exit, grid);
}

export function solvePart2(input: string): number {
  const withoutSlopes = input.replace(/[<>^v]/g, '.');
  const grid = ArrayGrid.fromInput(withoutSlopes);
  const start = pipe(
    grid.row(0),
    first(({value}) => value === '.'),
  ).first?.position;
  if (start == null) {
    throw new Error('Start could not be found');
  }
  const exit = pipe(
    grid.row(grid.height - 1),
    first(({value}) => value === '.'),
  ).first?.position;
  if (exit == null) {
    throw new Error('Start could not be found');
  }
  return longestPath(start, exit, grid);
}

// region Shared Code
interface VisitedNode {
  position: PlainPoint;
  distance: number;
  visited: Set<string>;
}

function longestPath(from: PlainPoint, to: PlainPoint, grid: Grid<string>): number {
  // const distances = new Map<string, number>();
  const open: VisitedNode[] = [{position: from, distance: 0, visited: new Set()}];

  let maxLength = 0;
  while (open.length > 0) {
    const current = open.pop()!;
    const visited = current.visited;
    const key = pointToString(current.position);
    if (visited.has(key)) { // || (distances.get(key) || -1) >= current.distance) {
      continue;
    }
    if (pointsEqual(current.position, to)) {
      maxLength = Math.max(current.distance, maxLength);
      continue;
    }
    visited.add(key);
    // distances.set(key, current.distance);

    const cellValue = grid.get(current.position);
    const directions = cellValue === '.' ? cardinalDirections : [directionFromName(cellValue as StraightArrowDirectionName)];
    const nextCells = [...grid.adjacentFrom(current.position, {directions})].filter((next) => {
      const nextKey = pointToString(next.position);
      return next.value !== '#' && !visited.has(nextKey); // && (distances.get(nextKey) || -1) < current.distance + 1;
    });
    const branch = nextCells.length > 1;
    for (const next of nextCells) {
      open.push({
        position: next.position,
        distance: current.distance + 1,
        visited: branch ? new Set(visited) : visited,
      });
    }
  }
  return maxLength;
}
// endregion
