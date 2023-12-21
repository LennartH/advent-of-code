import { ArrayGrid, formatGrid, Grid, manhattanDistance, PlainPoint, pointsEqual, pointToString } from '@util';
import { count, first, pipe } from 'iter-ops';
import { MinPriorityQueue } from 'datastructures-js';

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

export function solvePart2(input: string, numberOfSteps: number): number {
  const grid = ArrayGrid.fromInput(input);
  if (grid.height !== grid.width) {
    throw new Error('Only works for square grids');
  }
  const gridLength = grid.width; // h

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


  const fullGridSteps = Math.floor((numberOfSteps - start.x) / gridLength); // H/2
  const remainingSteps = (numberOfSteps - start.x) % (gridLength);
  console.log('#S', numberOfSteps);
  console.log('H/2:', fullGridSteps)
  console.log('r:', remainingSteps);

  let filledGrids = 1;
  for (let i = 1; i < fullGridSteps - 1; i++) {
    filledGrids += i * 4;
  }
  console.log('Filled Grids:', filledGrids);

  // const startToEdge = findShortestPathLengthsFromStartToEdge(grid);
  // console.log('start to edge:', startToEdge);
  // const edgeToEdge = findShortestPathLengthsFromEdgeToEdge(grid);
  // console.log('edge to edge:', edgeToEdge);

  grid.floodFill(0, 0, '+')
  const gardenPlotCount = pipe(grid.cellValues(), count((v) => v === '+')).first! + 1;
  // const gardenPlotCount = pipe(grid.cellValues(), count((v) => v === '.')).first! + 1;
  console.log('garden plot count', gardenPlotCount);
  console.log(formatGrid(grid));
  return filledGrids * gardenPlotCount;
}

// region Shared Code
function findShortestPathLengthsFromStartToEdge(grid: Grid<string>): Record<string, number> {
  const start = pipe(
    grid.cells(),
    first(({value}) => value === 'S'),
  ).first?.position;
  if (start == null) {
    throw new Error('Unable to find start');
  }

  const pathLengths: Record<string, number> = {};

  // for (const edgePosition of edgePositions(grid)) {
  //   pathLengths[pointToString(edgePosition)] = shortestPathLength(grid, start, edgePosition);
  // }

  const {
    position: closestEdgePosition,
    length: minLength
  } = shortestPathToEdge(grid, start);
  for (const edgePosition of edgePositions(grid)) {
    pathLengths[pointToString(edgePosition)] = minLength + manhattanDistance(closestEdgePosition, edgePosition);
  }

  return pathLengths;
}

function findShortestPathLengthsFromEdgeToEdge(grid: Grid<string>): Record<string, Record<string, number>> {
  const pathLengths: Record<string, Record<string, number>> = {};
  for (const fromEdge of edgePositions(grid)) {
    const fromEdgeKey = pointToString(fromEdge);
    for (const toEdge of edgePositions(grid)) {
      const toEdgeKey = pointToString(toEdge);
      if (pointsEqual(fromEdge, toEdge) || pathLengths[fromEdgeKey]?.[toEdgeKey] != null) {
        continue;
      }
      // const pathLength = shortestPathLength(grid, fromEdge, toEdge);
      const pathLength = manhattanDistance(fromEdge, toEdge);

      let fromTo = pathLengths[fromEdgeKey];
      if (fromTo == null) {
        fromTo = {};
        pathLengths[fromEdgeKey] = fromTo;
      }
      fromTo[toEdgeKey] = pathLength;

      let toFrom = pathLengths[toEdgeKey];
      if (toFrom == null) {
        toFrom = {};
        pathLengths[toEdgeKey] = toFrom;
      }
      toFrom[fromEdgeKey] = pathLength;
    }
  }
  return pathLengths;
}

interface VisitedNode {
  position: PlainPoint;
  length: number;
  distance: number;
}

function shortestPathToEdge(grid: Grid<string>, from: PlainPoint): {position: PlainPoint, length: number} {
  const heuristic = ({x, y}: PlainPoint) => Math.min(x, y, grid.width - x, grid.height - y);

  const visited = new Set<string>();
  const open = new MinPriorityQueue<VisitedNode>(({length, distance}) => length + distance);
  open.push({position: from, length: 0, distance: heuristic(from)});
  while (open.size() > 0) {
    const {position, length} = open.pop()!;
    if (isOnEdge(grid, position)) {
      return {position, length};
    }
    visited.add(pointToString(position));

    for (const neighbour of grid.adjacentFrom(position)) {
      if (neighbour.value === '#' || visited.has(pointToString(neighbour.position))) {
        continue;
      }
      open.push({position: neighbour.position, length: length + 1, distance: heuristic(neighbour.position)});
    }
  }
  throw new Error(`Unable to find path from ${pointToString(from)} to edge`);
}

function shortestPathLength(grid: Grid<string>, from: PlainPoint, to: PlainPoint): number {
  const visited = new Set<string>();
  const open = new MinPriorityQueue<VisitedNode>(({length, distance}) => length + distance);
  open.push({position: from, length: 0, distance: manhattanDistance(from, to)});
  while (open.size() > 0) {
    const {position, length} = open.pop()!;
    if (pointsEqual(position, to)) {
      return length;
    }
    visited.add(pointToString(position));

    for (const neighbour of grid.adjacentFrom(position)) {
      if (neighbour.value === '#' || visited.has(pointToString(neighbour.position))) {
        continue;
      }
      open.push({position: neighbour.position, length: length + 1, distance: manhattanDistance(neighbour.position, to)});
    }
  }
  throw new Error(`Unable to find path from ${pointToString(from)} to ${pointToString(to)}`);
}

function *edgePositions(grid: Grid<any>): Generator<PlainPoint> {
  for (let x = 0; x < grid.width; x++) {
    yield { x, y: 0 };
    yield { x, y: grid.height - 1 };
  }
  for (let y = 1; y < grid.height - 1; y++) {
    yield { x: 0, y };
    yield { x: grid.width - 1, y };
  }
}

function isOnEdge(grid: Grid<string>, {x, y}: PlainPoint): boolean {
  return x === 0 || y === 0 || x === grid.width - 1 || y === grid.height - 1;
}

function doWrapAround({x, y}: PlainPoint, grid: Grid<string>): PlainPoint {
  if (x < 0) {
    return { x: grid.width - 1, y };
  }
  if (x >= grid.width) {
    return { x: 0, y };
  }

  if (y < 0) {
    return { x, y: grid.height - 1 };
  }
  if (y >= grid.width) {
    return { x, y: 0 };
  }

  throw new Error(`Unexpected out of bounds position: ${pointToString(x, y, true)}`);
}
// endregion
