import { CardinalDirection2D, directionFromName, getDirections, splitLines } from '@util';

// region Types and Globals
interface Maze {
  start: string;

  edges: Record<string, [string, string]>;
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
  const lines = splitLines(input);
  // TODO Implement solution
  return Number.NaN;
}

// region Shared Code
function parseMaze(lines: string[]): Maze {
  let start: string = '';
  const edges: Record<string, [string, string]> = {};

  const height = lines.length;
  const width = lines[0].length;
  for (let y = 0; y < height; y++) {
    for (let x = 0; x < width; x++) {
      const key = `${x},${y}`;
      const value = lines[y][x];
      if (value === '.') {
        continue;
      }
      if (value === 'S') {
        start = key;
        continue;
      }

      edges[key] = pipeConnections[value].map(({deltaX, deltaY}) => `${x + deltaX},${y + deltaY}`) as [string, string];
    }
  }

  if (start.length === 0) {
    throw new Error('Start not found');
  }
  // My puzzle input has only 2 valid connections to the starting position.
  // So we can just add an edge from start to these points and do not have to
  // determine the actual pipe shape of the starting position.
  const connectedToStart = Object.entries(edges)
    .filter(([k, to]) => to.includes(start))
    .map(([k]) => k);
  edges[start] = connectedToStart as [string, string];
  return {start, edges}
}

function getLoopLength({start, edges}: Maze): number {
  let stepCount = 1;
  let currentNode = edges[start][0];
  let previousNode: string = start;
  while (currentNode !== start) {
    const nextNode = edges[currentNode].filter((n) => n !== previousNode)[0];
    previousNode = currentNode;
    currentNode = nextNode;
    stepCount++;
  }
  return stepCount;
}
// endregion
