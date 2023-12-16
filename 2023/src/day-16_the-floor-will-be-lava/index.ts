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
import { count, flatMap, pipe, reduce } from 'iter-ops';

// region Types and Globals
interface GridCell {
  symbol: string;
  energizedBy: Record<string, boolean>;
}

interface Beam {
  origin: string;
  position: PlainPoint;
  direction: CardinalDirection2D;
}
// endregion

export function solvePart1(input: string): number {
  const grid = parseGrid(input);
  const initialBeam: Beam = {
    origin: 'solo',
    position: {x: -1, y: 0},
    direction: directionFromName('E'),
  };
  raytrace(grid, [initialBeam]);
  return pipe(
    grid.cellValues(),
    count(({energizedBy: {solo: isEnergized}}) => isEnergized),
  ).first!;
}

export function solvePart2(input: string): number {
  const grid = parseGrid(input);
  let beamKey = 0;
  const initialBeams: Beam[] = [];
  for (let x = 0; x < grid.width; x++) {
    initialBeams.push(
      { origin: `${beamKey++}`, position: { x, y: -1 }, direction: directionFromName('S') },
      { origin: `${beamKey++}`, position: { x, y: grid.height }, direction: directionFromName('N') },
    );
  }
  for (let y = 0; y < grid.height; y++) {
    initialBeams.push(
      { origin: `${beamKey++}`, position: { x: -1, y }, direction: directionFromName('E') },
      { origin: `${beamKey++}`, position: { x: grid.width, y }, direction: directionFromName('W') },
    );
  }
  raytrace(grid, initialBeams);
  return pipe(
    grid.cellValues(),
    flatMap(({energizedBy}) => Object.keys(energizedBy)),
    reduce((counts, origin) => {
      if (!counts[origin]) {
        counts[origin] = 0;
      }
      counts[origin]++;
      return counts;
    }, {} as Record<string, number>),
    flatMap((counts) => Object.values(counts)),
    reduce(max),
  ).first!;
}

// region Shared Code
function parseGrid(input: string): Grid<GridCell> {
  const cells: GridCell[][] = splitLines(input)
    .map(
      (row) => row.split('')
        .map((symbol) => ({symbol, energizedBy: {}}))
    );
  return new ArrayGrid(cells);
}

function raytrace(grid: Grid<GridCell>, beams: Beam[]) {
  const visited = new Set<string>();
  const open: Beam[] = [...beams];
  while (open.length > 0) {
    const {origin, position, direction} = open.pop()!;
    const nextPosition = translateBy(position, direction);
    if (!grid.contains(nextPosition)) {
      continue;
    }
    const nextCell = grid.get(nextPosition);
    nextCell.energizedBy[origin] = true;
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
      const key = `${origin}|${nextPosition.x},${nextPosition.y}:${direction.name}`;
      if (visited.has(key)) {
        continue;
      }
      visited.add(key);
      open.push({origin, position: nextPosition, direction});
    }
  }
}
// endregion
