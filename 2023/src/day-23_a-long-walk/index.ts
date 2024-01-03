import {
  ArrayGrid,
  directionFromName,
  getDirections,
  pointsEqual,
  pointToString,
  StraightArrowDirectionName
} from '@util';
import { first, pipe } from 'iter-ops';

// region Types and Globals
interface Graph {
  start: string;
  exit: string;

  edges: Map<string, Map<string, number>>;
}

const cardinalDirections = getDirections('cardinal', {withDiagonals: false});
// endregion

export function solvePart1(input: string): number {
  const graph = gridToGraph(input);
  return longestPath(graph);
}

export function solvePart2(input: string): number {
  const withoutSlopes = input.replace(/[<>^v]/g, '.');
  const graph = gridToGraph(withoutSlopes);
  return longestPath(graph);
}

// region Shared Code
export function gridToGraph(input: string): Graph {
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

  const edges: Graph['edges'] = new Map();
  const visited = new Set<string>();
  const open = [{
    position: start,
    distance: 0,
    previousPosition: start,
    previous: { position: start, distance: 0 },
  }];
  while (open.length > 0) {
    const current = open.pop()!;
    const key = pointToString(current.position);
    if (pointsEqual(current.position, exit)) {
      const previous = current.previous;
      const fromKey = pointToString(previous.position);
      const delta = current.distance - previous.distance;

      let fromTo = edges.get(fromKey);
      if (fromTo == undefined) {
        fromTo = new Map();
        edges.set(fromKey, fromTo);
      }
      fromTo.set(key, Math.max(delta, fromTo.get(key) || 0));

      let toFrom = edges.get(key);
      if (toFrom == undefined) {
        toFrom = new Map();
        edges.set(key, toFrom);
      }
      toFrom.set(fromKey, Math.max(delta, toFrom.get(fromKey) || 0));
    }
    if (visited.has(key)) {
      continue;
    }
    visited.add(key);

    const cellValue = grid.get(current.position);
    const directions = cellValue === '.' ? cardinalDirections : [directionFromName(cellValue as StraightArrowDirectionName)];
    const nextCells = [...grid.adjacentFrom(current.position, {directions})].filter((next) => {
      return next.value !== '#' && !pointsEqual(current.previousPosition, next.position);
    });
    if (nextCells.length === 1) {
      const next = nextCells[0];
      const nextKey = pointToString(next.position);
      if (edges.has(nextKey)) {
        const previous = current.previous;
        const fromKey = pointToString(previous.position);
        const delta = current.distance - previous.distance + 1;

        let fromTo = edges.get(fromKey);
        if (fromTo == undefined) {
          fromTo = new Map();
          edges.set(fromKey, fromTo);
        }
        fromTo.set(nextKey, Math.max(delta, fromTo.get(nextKey) || 0));

        let toFrom = edges.get(nextKey);
        if (toFrom == undefined) {
          toFrom = new Map();
          edges.set(nextKey, toFrom);
        }
        toFrom.set(fromKey, Math.max(delta, toFrom.get(fromKey) || 0));
      }
      open.push({
        position: next.position,
        distance: current.distance + 1,
        previousPosition: current.position,
        previous: current.previous,
      });
    } else if (nextCells.length > 1) {
      const previous = current.previous;
      const fromKey = pointToString(previous.position);
      const delta = current.distance - previous.distance;

      let fromTo = edges.get(fromKey);
      if (fromTo == undefined) {
        fromTo = new Map();
        edges.set(fromKey, fromTo);
      }
      fromTo.set(key, Math.max(delta, fromTo.get(key) || 0));

      let toFrom = edges.get(key);
      if (toFrom == undefined) {
        toFrom = new Map();
        edges.set(key, toFrom);
      }
      toFrom.set(fromKey, Math.max(delta, toFrom.get(fromKey) || 0));

      for (const next of nextCells) {
        open.push({
          position: next.position,
          distance: current.distance + 1,
          previousPosition: current.position,
          previous: current,
        });
      }
    }
  }

  return {
    start: pointToString(start),
    exit: pointToString(exit),
    edges,
  }
}

interface VisitedNode {
  key: string;
  distance: number;
  visited: Set<string>;
}

function longestPath(graph: Graph): number {
  const open: VisitedNode[] = [{key: graph.start, distance: 0, visited: new Set()}];

  let maxLength = 0;
  while (open.length > 0) {
    const current = open.pop()!;
    const visited = current.visited;
    if (visited.has(current.key)) {
      continue;
    }
    if (current.key === graph.exit) {
      maxLength = Math.max(current.distance, maxLength);
      continue;
    }
    visited.add(current.key);

    const adjacent = [...(graph.edges.get(current.key)?.entries() || [])];
    for (const [nextKey, distance] of adjacent) {
      open.push({
        key: nextKey,
        distance: current.distance + distance,
        visited: new Set(visited),
      });
    }
  }
  return maxLength;
}
// endregion
