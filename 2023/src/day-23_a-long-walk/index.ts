import {
  ArrayGrid,
  directionFromName,
  formatGrid,
  getDirections,
  PlainPoint,
  pointsEqual,
  pointToString,
  splitLines
} from '@util';
import { first, pipe } from 'iter-ops';
import { MinPriorityQueue } from 'datastructures-js';

// region Types and Globals
const cardinalDirections = getDirections('cardinal', {withDiagonals: false});

interface VisitedNode {
  position: PlainPoint;
  steps: number;

  pathLength?: number;
  previous?: VisitedNode;
}
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

  let maxLength = 0;
  const visited = new Map<string, VisitedNode>();
  const open = new MinPriorityQueue<VisitedNode>(({steps}) => -steps);
  open.push({position: start, steps: 0});
  while (open.size()) {
    const current = open.pop();
    const {position, steps} = current;
    if (pointsEqual(position, exit)) {
      const copy = ArrayGrid.fromInput(input);

      const pathLength = steps;
      let previous = current.previous;
      while (previous != null) {
        copy.set(previous.position, 'O');

        if (previous.pathLength == null || previous.pathLength < pathLength) {
          previous.pathLength = pathLength;
        }
        previous = previous.previous;
      }
      if (maxLength < pathLength) {
        maxLength = pathLength;
      }
      console.log(pathLength);
      // console.log(formatGrid(copy));
      // console.log()
      continue;
    }
    const key = pointToString(position);
    if (visited.has(key)) {
      continue;
    }
    visited.set(key, current);

    const cellValue = grid.get(position);
    const directions = cellValue !== '.' ? [directionFromName(cellValue as never)] : cardinalDirections;
    for (const {position: next, value} of grid.adjacentFrom(position, {directions})) {
      if (value === '#') {
        continue;
      }
      const known = visited.get(pointToString(next));
      if (known != null) {
        if (known.pathLength != null) {
          const currentPath = new Set<string>();
          let foo: VisitedNode | undefined = current;
          while (foo != null) {
            currentPath.add(pointToString(foo.position));
            foo = foo.previous;
          }
          const knownPath = new Set<string>();
          foo = known;
          while (foo != null) {
            knownPath.add(pointToString(foo.position));
            foo = foo.previous;
          }
          if (![...currentPath].some((k) => knownPath.has(k))) {
            const remainingSteps = known.pathLength - known.steps;
            open.push({position: exit, steps: steps + 1 + remainingSteps, previous: current});
          }
        }
        continue;
      }
      open.push({position: next, steps: steps + 1, previous: current});
    }
  }

  return maxLength;
}

export function solvePart2(input: string): number {
  const lines = splitLines(input);
  // TODO Implement solution
  return Number.NaN;
}

// region Shared Code

// endregion
