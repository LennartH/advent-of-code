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

  previous?: VisitedNode;
  finalNode?: VisitedNode;
}

function longestPath(from: PlainPoint, to: PlainPoint, grid: Grid<string>): number {
  const pathNodes = new Map<string, VisitedNode>();
  const open: VisitedNode[] = [{position: from, distance: 0, visited: new Set()}];

  let maxLength = 0;
  while (open.length > 0) {
    const current = open.pop()!;
    const visited = current.visited;
    const key = pointToString(current.position);
    if (visited.has(key)) {
      throw new Error('Moo')
    }

    if (pointsEqual(current.position, to)) {
      maxLength = Math.max(current.distance, maxLength);
      let node = current;
      while (node.previous != null) {
        node = node.previous;
        node.finalNode = current;
        pathNodes.set(pointToString(node.position), node);
      }
      continue;
    }
    if (pathNodes.has(key)) {
      const pathNode = pathNodes.get(key)!;
      const delta = current.distance - pathNode.distance;
      if (delta > 0) {
        const finalNode = pathNode.finalNode;
        if (finalNode == null) {
          throw new Error('Mawp')
        }
        let node = current;
        while (node.previous != null) {
          node.finalNode = finalNode;
          pathNodes.set(pointToString(node.position), node);
          node = node.previous;
        }

        finalNode.distance += delta;
        maxLength = Math.max(finalNode.distance, maxLength);

        let previous = finalNode.previous;
        while (previous != null && !pointsEqual(previous.position, current.position)) {
          previous.distance += delta;
          previous = previous.previous;
        }
      }
      continue;
    }

    visited.add(key);

    const cellValue = grid.get(current.position);
    const directions = cellValue === '.' ? cardinalDirections : [directionFromName(cellValue as StraightArrowDirectionName)];
    const nextCells = [...grid.adjacentFrom(current.position, {directions})].filter((next) => {
      const nextKey = pointToString(next.position);
      return next.value !== '#' && !visited.has(nextKey);
    });
    const branch = nextCells.length > 1;
    for (const next of nextCells) {
      const nextNode = {
        position: next.position,
        distance: current.distance + 1,
        visited: branch ? new Set(visited) : visited,
        previous: current,
      };
      open.push(nextNode);
    }
  }
  return maxLength;
}
// endregion
