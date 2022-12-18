import { Point, Rect, translate } from '@util/misc';
import { splitLines } from '@util';

export enum CellType {
  Rock = '#',
  Air = '.',
  SandOrigin = '+',
  Sand = 'o',
  SandFlow = '~',
}

export interface Cave {
  readonly grid: CellType[][];
  readonly rockOutline: Rect;
  hasFloor: boolean;
}

export function parseCave(input: string): Cave {
  const grid: CellType[][] = [];
  const outlineTopLeft = { x: Number.MAX_SAFE_INTEGER, y: 0 };
  const outlineBottomRight = { x: Number.MIN_SAFE_INTEGER, y: Number.MIN_SAFE_INTEGER };

  const lines = splitLines(input);
  for (const line of lines) {
    const points: Point[] = line.split(' -> ').map((point) => {
      const parts = point.split(',');
      return { x: Number(parts[0]), y: Number(parts[1]) };
    });
    while (points.length >= 2) {
      let current = points.shift()!;
      const target = points[0];
      outlineTopLeft.x = Math.min(current.x, target.x, outlineTopLeft.x);
      outlineTopLeft.y = Math.min(current.y, target.y, outlineTopLeft.y);
      outlineBottomRight.x = Math.max(current.x, target.x, outlineBottomRight.x);
      outlineBottomRight.y = Math.max(current.y, target.y, outlineBottomRight.y);

      const delta = {
        x: Math.min(1, Math.max(target.x - current.x, -1)),
        y: Math.min(1, Math.max(target.y - current.y, -1)),
      };
      do {
        let row = grid[current.y];
        if (row == null) {
          row = [];
          grid[current.y] = row;
        }
        row[current.x] = CellType.Rock;
        current = translate(current, delta);
      } while (current.x !== target.x || current.y !== target.y);
    }

    let row = grid[points[0].y];
    if (row == null) {
      row = [];
      grid[points[0].y] = row;
    }
    row[points[0].x] = CellType.Rock;
  }

  const rockOutline = {
    ...outlineTopLeft,
    width: outlineBottomRight.x - outlineTopLeft.x + 1,
    height: outlineBottomRight.y - outlineTopLeft.y + 1,
  };
  const cave = { grid, rockOutline, hasFloor: false };
  fillCaveWithAir(cave);
  return cave;
}

function fillCaveWithAir(cave: Cave) {
  const { grid, rockOutline } = cave;
  for (let y = 0; y < grid.length; y++) {
    let row = grid[y];
    if (row == null) {
      row = [];
      grid[y] = row;
    }
    row.length = rockOutline.x + rockOutline.width;
    for (let x = rockOutline.x; x < row.length; x++) {
      if (row[x] == null) {
        row[x] = CellType.Air;
      }
    }
  }
}

export function caveAsString(cave: Cave): string {
  return cave.grid.map((r) => r.join('')).join('\n');
}

export function simulateSandfall(cave: Cave, sandOrigin: Point): number {
  const fallDeltas = [
    { x: 0, y: 1 },
    { x: -1, y: 1 },
    { x: 1, y: 1 },
  ];
  const { grid, hasFloor } = cave;
  const floorY = hasFloor ? grid.length + 1 : -1;

  let sandCount = 0;
  let equilibrium = false;
  while (!equilibrium) {
    let position = { ...sandOrigin };
    let sandMoved = false;
    do {
      sandMoved = false;
      for (const delta of fallDeltas) {
        const nextPosition = translate(position, delta);
        let nextCell = grid[nextPosition.y]?.[nextPosition.x];
        if (nextCell == null) {
          if (!hasFloor) {
            equilibrium = true;
            break;
          } else {
            if (grid[nextPosition.y] == null) {
              grid[nextPosition.y] = [];
            }
            nextCell = nextPosition.y === floorY ? CellType.Rock : CellType.Air;
            grid[nextPosition.y][nextPosition.x] = nextCell;
          }
        }
        if (nextCell === CellType.Air || nextCell === CellType.SandFlow) {
          grid[position.y][position.x] = CellType.SandFlow;
          position = nextPosition;
          sandMoved = true;
          break;
        }
      }
    } while (sandMoved);

    if (grid[sandOrigin.y][sandOrigin.x] === CellType.Sand) {
      equilibrium = true;
    }

    if (!equilibrium) {
      grid[position.y][position.x] = CellType.Sand;
      sandCount++;
    } else {
      grid[position.y][position.x] = CellType.SandFlow;
    }
  }

  if (hasFloor) {
    const floor = grid[grid.length - 1];
    cave.rockOutline.x = floor.indexOf(CellType.Rock);
    floor.fill(CellType.Rock, cave.rockOutline.x);
    cave.rockOutline.height += 2;
    cave.rockOutline.width = floor.lastIndexOf(CellType.Rock) - cave.rockOutline.x;
    fillCaveWithAir(cave);
    grid[sandOrigin.y][sandOrigin.x] = CellType.Sand;
  } else {
    grid[sandOrigin.y][sandOrigin.x] = CellType.SandOrigin;
  }

  return sandCount;
}
