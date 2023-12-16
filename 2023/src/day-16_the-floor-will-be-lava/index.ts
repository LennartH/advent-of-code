import {
  CardinalDirection2D,
  directionFromName,
  isHorizontal,
  isVertical,
  max,
  oppositeOf,
  PlainPoint,
  splitLines,
  translateBy
} from '@util';
import { ArrayGrid, Grid } from '@util/grid';
import { count, map, pipe, reduce } from 'iter-ops';

// region Types and Globals
interface GridCell {
  symbol: string;
  isEnergized: boolean;
}

interface Beam {
  position: PlainPoint;
  direction: CardinalDirection2D;
}
// endregion

export function solvePart1(input: string): number {
  const grid = parseGrid(input);
  const initialBeam: Beam = {
    position: {x: -1, y: 0},
    direction: directionFromName('E'),
  };
  raytrace(grid, initialBeam);
  return pipe(
    grid.cellValues(),
    count(({isEnergized}) => isEnergized),
  ).first!;
}

export function solvePart2(input: string): number {
  const lines = splitLines(input);
  const width = lines[0].length;
  const height = lines.length;
  const initialBeams: Beam[] = [];
  for (let x = 0; x < width; x++) {
    initialBeams.push(
      { position: { x, y: -1 }, direction: directionFromName('S') },
      { position: { x, y: height }, direction: directionFromName('N') },
    );
  }
  for (let y = 0; y < height; y++) {
    initialBeams.push(
      { position: { x: -1, y }, direction: directionFromName('E') },
      { position: { x: width, y }, direction: directionFromName('W') },
    );
  }
  return pipe(
    initialBeams,
    map((beam) => {
      const grid = parseGrid(input);
      raytrace(grid, beam);
      return pipe(
        grid.cellValues(),
        count(({isEnergized}) => isEnergized),
      ).first!;
    }),
    reduce(max, -Infinity)
  ).first!;
}

// region Shared Code
function parseGrid(input: string): Grid<GridCell> {
  const cells: GridCell[][] = splitLines(input)
    .map(
      (row) => row.split('')
        .map((symbol) => ({symbol, isEnergized: false}))
    );
  return new ArrayGrid(cells);
}

function raytrace(grid: Grid<GridCell>, beam: Beam) {
  const visited = new Set<string>();
  const open: Beam[] = [beam];
  while (open.length > 0) {
    const {position, direction} = open.pop()!;
    const nextPosition = translateBy(position, direction);
    if (!grid.contains(nextPosition)) {
      continue;
    }
    const nextCell = grid.get(nextPosition);
    nextCell.isEnergized = true;
    const symbol = nextCell.symbol;

    const nextDirections: CardinalDirection2D[] = [];
    if (symbol === '.' || (symbol === '-' && isHorizontal(direction)) || (symbol === '|' && isVertical(direction))) {
      nextDirections.push(direction);
    } else if (symbol === '-') {
      nextDirections.push(directionFromName('E'), directionFromName('W'));
    } else if (symbol === '|') {
      nextDirections.push(directionFromName('N'), directionFromName('S'));
    } else if (symbol === '/' || symbol === '\\') {
      let nextDirection = direction;
      switch (direction.name) {
        case 'N':
          nextDirection = directionFromName('E');
          break;
        case 'E':
          nextDirection = directionFromName('N');
          break;
        case 'S':
          nextDirection = directionFromName('W');
          break;
        case 'W':
          nextDirection = directionFromName('S');
          break;
      }
      if (symbol === '\\') {
        nextDirection = oppositeOf(nextDirection);
      }
      nextDirections.push(nextDirection);
    }

    for (const direction of nextDirections) {
      const key = `${nextPosition.x},${nextPosition.y}:${direction.name}`;
      if (visited.has(key)) {
        continue;
      }
      visited.add(key);
      open.push({position: nextPosition, direction});
    }
  }
}
// endregion
