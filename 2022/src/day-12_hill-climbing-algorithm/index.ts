import {
  Direction,
  directions,
  distanceToPoint,
  getDirectionDelta,
  lowerCaseAlphabet,
  Point,
  pointAsString,
  shuffle,
  translate,
} from '../../../util/util';

export interface Node {
  readonly symbol: string;
  readonly elevation: number;
  readonly position: Point;

  readonly isStart: boolean;
  readonly isEnd: boolean;
}

export type Grid = Node[][];
export type Edges = Direction[][][];

export function readGrid(lines: string[]): Grid {
  return lines.map((line, y) => {
    const row: Node[] = [];
    for (let x = 0; x < line.length; x++) {
      const symbol = line[x];
      const isStart = symbol === 'S';
      const isEnd = symbol === 'E';
      let elevation = lowerCaseAlphabet.indexOf(symbol);
      if (isStart) {
        elevation = 0;
      }
      if (isEnd) {
        elevation = 25;
      }
      row.push({ symbol, elevation, position: { x, y }, isStart, isEnd });
    }
    return row;
  });
}

export function gridAsString(grid: Grid): string {
  return grid.map((r) => r.map((c) => c.symbol).join('')).join('\n');
}

export function getEdges(grid: Grid): Edges {
  return grid.map((row, y) =>
    row.map((cell, x) => {
      return shuffle([...directions]).reduce((edges, direction) => {
        const neighbourPoint = translate({ x, y }, getDirectionDelta(direction));
        const neighbour = grid[neighbourPoint.y]?.[neighbourPoint.x];
        if (neighbour && neighbour.elevation - cell.elevation <= 1) {
          edges.push(direction);
        }
        return edges;
      }, [] as Direction[]);
    })
  );
}

export interface VisitedNode {
  readonly point: Point;
  readonly cost: number;
  readonly distance: number;
  readonly predecessor?: VisitedNode;
  readonly fromDirection?: Direction;
}

export function findShortestPath(grid: Grid, from?: Point, to?: Point): Direction[] {
  from ||= grid.flat().find((c) => c.isStart)?.position;
  to ||= grid.flat().find((c) => c.isEnd)?.position;
  if (!from || !to) {
    throw new Error('Unable to find start and end in grid and no from and to were given');
  }
  const edges = getEdges(grid);
  const openNodes: VisitedNode[] = [];
  const visited: boolean[][] = [];
  grid.forEach(() => visited.push(new Array(grid[0].length).fill(false)));

  let finalNode: VisitedNode | undefined = undefined;
  openNodes.push({
    point: from,
    cost: 0,
    distance: distanceToPoint(from, to),
  });
  do {
    const node = openNodes.pop()!;
    visited[node.point.y][node.point.x] = true;
    if (node.point.x === to.x && node.point.y === to.y) {
      finalNode = node;
      break;
    }

    for (const direction of edges[node.point.y][node.point.x]) {
      const successorPoint = translate(node.point, getDirectionDelta(direction));
      if (!visited[successorPoint.y][successorPoint.x]) {
        const index = openNodes.findIndex((n) => n.point.x === successorPoint.x && n.point.y === successorPoint.y);
        const successorNode: VisitedNode = {
          point: successorPoint,
          cost: node.cost + 1,
          distance: distanceToPoint(node.point, to),
          predecessor: node,
          fromDirection: direction,
        };
        if (index === -1) {
          openNodes.push(successorNode);
        } else if (node.cost + 1 < openNodes[index].cost) {
          openNodes[index] = successorNode;
        }
      }
    }
    openNodes.sort((a, b) => (a.cost + a.distance - (b.cost + b.distance)) * -1);
  } while (openNodes.length > 0);

  if (finalNode == null) {
    throw new Error(`No path could be found from ${pointAsString(from, true)} to ${pointAsString(to, true)}`);
  }
  const path: Direction[] = [];
  let currentNode: VisitedNode = finalNode;
  while (currentNode.predecessor != null) {
    path.unshift(currentNode.fromDirection!);
    currentNode = currentNode.predecessor;
  }
  return path;
}

export function printRoute(grid: Grid, path: Direction[]): string {
  const output = grid.map(() => new Array(grid[0].length).fill('.'));
  const start = grid.flat().find((c) => c.isStart)!.position;
  const end = grid.flat().find((c) => c.isEnd)!.position;
  output[end.y][end.x] = 'E';

  let current = start;
  for (const direction of path) {
    let symbol = '';
    if (direction === Direction.Top) {
      symbol = '^';
    }
    if (direction === Direction.Right) {
      symbol = '>';
    }
    if (direction === Direction.Bottom) {
      symbol = 'v';
    }
    if (direction === Direction.Left) {
      symbol = '<';
    }
    output[current.y][current.x] = symbol;
    current = translate(current, getDirectionDelta(direction));
  }

  return output.map((r) => r.join('')).join('\n');
}
