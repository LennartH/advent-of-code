import { CardinalDirection2D, directionFromName, formatGrid, splitLines } from '@util';
import { ArrayGrid, Grid } from '@util/grid';

// TODO Different solutions described here: https://www.reddit.com/r/adventofcode/comments/18ey1s7/2023_day_10_part_2_stumped_on_how_to_approach_this/

// region Types and Globals
interface Maze {
  start: string;
  edges: Record<string, Node>;
  width: number;
  height: number;
}

interface Node {
  symbol: string;
  key: string;
  position: {x: number, y: number};
  next: [string, string];
}

const pipeConnections: Record<string, [CardinalDirection2D, CardinalDirection2D]> = {
  '|': [directionFromName('N'), directionFromName('S')],
  '-': [directionFromName('E'), directionFromName('W')],
  'L': [directionFromName('N'), directionFromName('E')],
  'J': [directionFromName('N'), directionFromName('W')],
  '7': [directionFromName('S'), directionFromName('W')],
  'F': [directionFromName('S'), directionFromName('E')],
}
// endregion

export function solvePart1(input: string): number {
  const maze = parseMaze(splitLines(input));
  return findLoop(maze).length / 2;
}

export function solvePart2(input: string): number {
  const maze = parseMaze(splitLines(input));
  // Transform every piece of pipe to a 3x3 grid and connect the loop
  const grid = drawLoopToGrid(maze);
  // "Remove" everything outside the loop
  grid.floodFill(0, 0, ' ');
  // Iterate over maze in pipe coordinates and see if the corresponding 3x3 tile is completely empty
  let emptyTilesCount = 0;
  for (let x = 0; x < maze.width; x++) {
    for (let y = 0; y < maze.height; y++) {
      const gridPosition = { x: 1 + (x * 3), y: 1 + (y * 3) };
      if (grid.get(gridPosition) === '.') {
        emptyTilesCount++;
      }
    }
  }

  // What the drawn loop looks like after everything outside was removed
  console.log(formatGrid(grid, {columnSeparator: ' '}));
  return emptyTilesCount;
}

// region Shared Code
function parseMaze(lines: string[]): Maze {
  let start: Node = null as never;
  const edges: Record<string, Node> = {};

  const height = lines.length;
  const width = lines[0].length;
  for (let y = 0; y < height; y++) {
    for (let x = 0; x < width; x++) {
      const key = `${x},${y}`;
      const symbol = lines[y][x];
      if (symbol === '.') {
        continue;
      }
      if (symbol === 'S') {
        start = {
          key,
          symbol,
          position: {x, y},
          next: ['', ''],
        };
        continue;
      }

      edges[key] = {
        key,
        symbol,
        position: {x, y},
        next: pipeConnections[symbol].map(({deltaX, deltaY}) => `${x + deltaX},${y + deltaY}`) as [string, string]
      };
    }
  }

  if (start == null) {
    throw new Error('Start not found');
  }
  const connectedToStart = Object.entries(edges)
    .filter(([_, n]) => n.next.includes(start!.key))
    .map(([k]) => k);
  const startPipe = Object.keys(pipeConnections).find((symbol) => {
    const nextIfMatch = pipeConnections[symbol].map(
      ({deltaX, deltaY}) => `${start.position.x + deltaX},${start.position.y + deltaY}`
    );
    return !connectedToStart.some((k) => !nextIfMatch.includes(k));
  });
  if (startPipe == null) {
    throw new Error('Unable to determine pipe of starting position');
  }
  start.symbol = startPipe;
  start.next = connectedToStart as [string, string];
  edges[start.key] = start;

  return {start: start.key, edges, width, height}
}

function drawLoopToGrid(maze: Maze): Grid<string> {
  const grid = new ArrayGrid(maze.width * 3, maze.height * 3, '.');
  for (const node of findLoop(maze)) {
    const gridPosition = {
      x: 1 + (node.position.x * 3),
      y: 1 + (node.position.y * 3),
    };
    grid.set(gridPosition, '#');
    for (const {deltaX, deltaY} of pipeConnections[node.symbol]) {
      grid.set(gridPosition.x + deltaX, gridPosition.y + deltaY, '#');
    }
  }
  return grid;
}

function findLoop({start, edges}: Maze): Node[] {
  const nodesInLoop: Node[] = [edges[start]];
  let currentNode = edges[start].next[0];
  let previousNode = start;
  while (currentNode !== start) {
    nodesInLoop.push(edges[currentNode]);
    const nextNode = edges[currentNode].next.filter((n) => n !== previousNode)[0];
    previousNode = currentNode;
    currentNode = nextNode;
  }
  return nodesInLoop;
}
// endregion
