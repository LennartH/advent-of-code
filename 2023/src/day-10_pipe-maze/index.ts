import { CardinalDirection2D, directionFromName, formatGrid, getDirections, splitLines } from '@util';
import { ArrayGrid, Grid } from '@util/grid';
import { filter, map, pipe } from 'iter-ops';

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
  return getLoopLength(maze) / 2;
}

export function solvePart2(input: string): number {
  const maze = parseMaze(splitLines(input));
  // Transform every piece of pipe to a 3x3 grid and connect the loop
  const grid = drawLoopToGrid(maze);
  // "Remove" everything outside the loop
  const outerStack = [{x: 0, y: 0}] // 0,0 of grid can't be inside loop
  while (outerStack.length > 0) {
    const position = outerStack.pop()!;
    grid.set(position, ' ');
    outerStack.push(...pipe(
      grid.adjacentFrom(position, {withDiagonals: true}),
      filter(({value}) => value === '.'),
      map(({position}) => position),
    ));
  }
  // Iterate over maze in pipe coordinates and see if the corresponding 3x3 tile is completely empty
  let emptyTilesCount = 0;
  for (let x = 0; x < maze.width; x++) {
    for (let y = 0; y < maze.height; y++) {
      const gridPosition = { x: 1 + (x * 3), y: 1 + (y * 3) };
      const tileCells = [...grid.adjacentFrom(gridPosition, {withDiagonals: true})].map(({value}) => value);
      tileCells.push(grid.get(gridPosition));
      // Everything that's not a . is a pipe or outside the loop
      if (!tileCells.some((v) => v !== '.')) {
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
  let start: Node | null = null;
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
  // My puzzle input has only 2 valid connections to the starting position.
  // So we can just add an edge from start to these points and do not have to
  // determine the actual pipe shape of the starting position.
  const connectedToStart = Object.entries(edges)
    .filter(([k, n]) => n.next.includes(start!.key))
    .map(([k]) => k);
  start.next = connectedToStart as [string, string];
  edges[start.key] = start;
  return {start: start.key, edges, width, height}
}

function getLoopLength({start, edges}: Maze): number {
  let stepCount = 1;
  let currentNode = edges[start].next[0];
  let previousNode = start;
  while (currentNode !== start) {
    const nextNode = edges[currentNode].next.filter((n) => n !== previousNode)[0];
    previousNode = currentNode;
    currentNode = nextNode;
    stepCount++;
  }
  return stepCount;
}

const symbolToPipe: Record<string, string[]> = {
  '|': [
    '.#.',
    '.#.',
    '.#.',
  ],
  '-': [
    '...',
    '###',
    '...',
  ],
  'L': [
    '.#.',
    '.##',
    '...',
  ],
  'J': [
    '.#.',
    '##.',
    '...',
  ],
  '7': [
    '...',
    '##.',
    '.#.',
  ],
  'F': [
    '...',
    '.##',
    '.#.',
  ],
};
const directions = getDirections('cardinal');

function drawLoopToGrid(maze: Maze): Grid<string> {
  // determine start pipe
  const startNode = maze.edges[maze.start];
  const startPipe = Object.keys(pipeConnections).find((symbol) => {
    const nextIfMatch = pipeConnections[symbol].map(
      ({deltaX, deltaY}) => `${startNode.position.x + deltaX},${startNode.position.y + deltaY}`
    );
    return !startNode.next.some((k) => !nextIfMatch.includes(k));
  });
  if (startPipe == null) {
    throw new Error('Unable to determine pipe of starting position');
  }
  startNode.symbol = startPipe;

  // find nodes in loop
  const nodesInLoop: Node[] = [maze.edges[maze.start]];
  let currentNode = maze.edges[maze.start].next[0];
  let previousNode = maze.start;
  while (currentNode !== maze.start) {
    nodesInLoop.push(maze.edges[currentNode]);
    const nextNode = maze.edges[currentNode].next.filter((n) => n !== previousNode)[0];
    previousNode = currentNode;
    currentNode = nextNode;
  }

  // draw loop to grid
  const grid = new ArrayGrid(maze.width * 3, maze.height * 3, '.');
  for (const node of nodesInLoop) {
    const gridPosition = {
      x: 1 + (node.position.x * 3),
      y: 1 + (node.position.y * 3),
    };
    const pipeToDraw = symbolToPipe[node.symbol];
    for (const {deltaX, deltaY} of directions) {
      const templatePosition = {x: 1 + deltaX, y: 1 + deltaY};
      const targetPosition = {x: gridPosition.x + deltaX, y: gridPosition.y + deltaY};
      grid.set(targetPosition, pipeToDraw[templatePosition.y][templatePosition.x]);
    }
    grid.set(gridPosition, pipeToDraw[1][1]);
  }

  return grid;
}
// endregion
