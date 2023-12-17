import {
  ArrayGrid, formatGrid,
  getDirections,
  Grid,
  manhattanDistance, oppositeOf,
  PlainPoint,
  pointsEqual,
  pointToString,
  splitLines,
  StraightCardinalDirectionName
} from '@util';

// region Types and Globals

// endregion

export function solvePart1(input: string): number {
  const grid = ArrayGrid.fromInput(input, Number);
  return findHeatLossMinimum(grid, 3);
}

export function solvePart2(input: string): number {
  const lines = splitLines(input);
  // TODO Implement solution
  return Number.NaN;
}

// region Shared Code
interface VisitedNode {
  readonly position: PlainPoint;
  readonly cost: number;
  readonly distance: number;
  readonly straightCount: number;
  readonly direction: StraightCardinalDirectionName;
  readonly predecessor?: VisitedNode;
}
function findHeatLossMinimum(grid: Grid<number>, maxStraightMoves: number): number {
  const nodeKey = (node: VisitedNode) => `${pointToString(node.position)}|${node.direction},${node.straightCount}`;
  const calculateDistance = (from: PlainPoint, to: PlainPoint) => manhattanDistance(from, to);

  const start = {x: 0, y: 0};
  const target = {x: grid.width - 1, y: grid.height - 1};
  const visited = new Set<string>();
  const openNodes: VisitedNode[] = [{
    position: start,
    cost: 0,
    distance: calculateDistance(start, target),
    straightCount: 0,
    direction: 'E',
  }];

  let debugStep = 0;
  const possibleDirections = getDirections('cardinal', {withDiagonals: false});
  let finalNode: VisitedNode | null = null;
  do {
    const node = openNodes.pop()!;
    if (debugStep % 1000 === 0) {
      console.log(
        `Step ${debugStep}`.padStart(20, ' '),
        '- Current best:', `(${node.position.x.toString().padStart(3, ' ')}, ${node.position.y.toString().padStart(3, ' ')})`,
        '| cost:', node.cost.toString().padStart(4, ' '),
        'distance:', node.distance.toString().padStart(3, ' ')
      );
    }
    if (pointsEqual(node.position, target)) {
      console.log(
        `Step ${debugStep}`.padStart(20, ' '),
        '-     Solution:', `(${node.position.x.toString().padStart(3, ' ')}, ${node.position.y.toString().padStart(3, ' ')})`,
        '| cost:', node.cost.toString().padStart(4, ' '),
        'distance:', node.distance.toString().padStart(3, ' ')
      );
      finalNode = node;
      break;
      // if (finalNode == null || node.cost < finalNode.cost) {
      //   finalNode = node;
      // }
      // continue;
    }
    visited.add(nodeKey(node));

    const directions = node.straightCount < maxStraightMoves ?
      possibleDirections.filter(({name}) => name !== oppositeOf(node.direction).name) :
      possibleDirections.filter(({name}) => name !== node.direction && name !== oppositeOf(node.direction).name);
    for (const {position: nextPosition, value, direction} of grid.adjacentFrom(node.position, {directions})) {
      const nextStraightCount = direction.name === node.direction ? node.straightCount + 1 : 1;
      const nextNode: VisitedNode = {
        position: nextPosition,
        cost: node.cost + value,
        distance: calculateDistance(nextPosition, target),
        straightCount: nextStraightCount,
        direction: direction.name as StraightCardinalDirectionName,
        predecessor: node,
      };
      if (visited.has(nodeKey(nextNode))) {
        continue;

      }

      const index = openNodes.findIndex((node) => nodeKey(node) === nodeKey(nextNode));
      if (index === -1) {
        openNodes.push(nextNode);
      } else if (nextNode.cost < openNodes[index].cost) {
        openNodes[index] = nextNode;
      }
    }

    openNodes.sort((n1, n2) => (n2.cost + n2.distance) - (n1.cost + n1.distance));
    debugStep++;
  } while (openNodes.length > 0);

  if (finalNode == null) {
    throw new Error(`Unable to find path from ${pointToString(start)} to ${pointToString(target)}`)
  }


  const debug = new ArrayGrid(grid.width, grid.height, '.');
  for (const {position, value} of grid.cells()) {
    debug.set(position, value.toString());
  }
  let node = finalNode;
  while (node.predecessor != null) {
    const {position, direction} = node;
    if (direction == null) {
      throw Error('mawp');
    }
    let marker = '';
    if (direction === 'N') {
      marker = '^';
    } else if (direction === 'E') {
      marker = '>';
    } else if (direction === 'S') {
      marker = 'v';
    } else {
      marker = '<';
    }
    debug.set(position, marker);
    node = node.predecessor;
  }
  console.log(formatGrid(debug));


  return finalNode.cost;
}
// endregion
