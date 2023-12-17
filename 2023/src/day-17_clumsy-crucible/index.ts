import {
  ArrayGrid,
  getDirections,
  Grid,
  oppositeOf,
  PlainPoint,
  pointsEqual,
  pointToString,
  StraightCardinalDirectionName,
  translateBy
} from '@util';
import { MinPriorityQueue } from 'datastructures-js';

export function solvePart1(input: string): number {
  const grid = ArrayGrid.fromInput(input, Number);
  return findHeatLossMinimum(grid, 1, 3);
}

export function solvePart2(input: string): number {
  const grid = ArrayGrid.fromInput(input, Number);
  return findHeatLossMinimum(grid, 4, 10);
}

// region Shared Code
interface VisitedNode {
  readonly position: PlainPoint;
  readonly cost: number;
  readonly straightCount: number;
  readonly direction: StraightCardinalDirectionName;
}
function findHeatLossMinimum(grid: Grid<number>, minStraightMoves: number, maxStraightMoves: number): number {
  const nodeKey = (node: VisitedNode) => `${pointToString(node.position)}|${node.direction},${node.straightCount}`;

  const start = {x: 0, y: 0};
  const target = {x: grid.width - 1, y: grid.height - 1};
  const visited = new Set<string>();
  const openNodes = new MinPriorityQueue<VisitedNode>(({cost}) => cost);
  openNodes.push({
    position: {x: 1, y: 0},
    cost: grid.get(1, 0),
    straightCount: 1,
    direction: 'E',
  });
  openNodes.push({
    position: {x: 0, y: 1},
    cost: grid.get(0, 1),
    straightCount: 1,
    direction: 'S',
  });

  const possibleDirections = getDirections('cardinal', {withDiagonals: false});
  let finalNode: VisitedNode | null = null;
  do {
    const node = openNodes.pop()!;
    if (pointsEqual(node.position, target)) {
      if (node.straightCount < minStraightMoves) {
        continue
      }
      finalNode = node;
      break;
    }
    const key = nodeKey(node);
    if (visited.has(key)) {
      continue;
    }
    visited.add(key);

    for (const direction of possibleDirections) {
      const nextPosition = translateBy(node.position, direction);
      if (
        !grid.contains(nextPosition) ||
        (direction.name === node.direction && node.straightCount >= maxStraightMoves) ||
        (direction.name !== node.direction && node.straightCount < minStraightMoves) ||
        oppositeOf(direction).name === node.direction
      ) {
        continue;
      }

      const nextNode: VisitedNode = {
        position: nextPosition,
        cost: node.cost + grid.get(nextPosition),
        straightCount: direction.name === node.direction ? node.straightCount + 1 : 1,
        direction: direction.name as StraightCardinalDirectionName,
      }
      openNodes.push(nextNode);
    }
  } while (openNodes.front() !== null);

  if (finalNode == null) {
    throw new Error(`Unable to find path from ${pointToString(start)} to ${pointToString(target)}`)
  }
  return finalNode.cost;
}
// endregion
