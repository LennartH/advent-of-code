import { Direction, getDirectionDelta, Point } from '@util/misc';
import { formatGrid, Point2D } from '@util';

export interface CaveChamber {
  width: number;
  jetPattern: (Direction.Left | Direction.Right)[];
  rockPattern: RockType[];
  rockSpawnOffset: Point;

  stoppedRocksHeight: number;
  grid: boolean[][];
}

export enum RockType {
  Bar = '_',
  Cross = '+',
  Elbow = 'e',
  Pillar = '|',
  Box = 'o',
}

export class Rock {

  readonly type: RockType;
  readonly position: Point2D;
  readonly sprite: boolean[][];
  readonly size: {width: number, height: number};

  get topLeft(): Point2D {
    return this.position.clone();
  }

  get bottomRight(): Point2D {
    return this.position.clone().translateBy(this.size.width - 1, this.size.height - 1);
  }

  constructor(type: RockType, position: Point2D) {
    this.type = type;
    this.position = position;
    if (type === RockType.Bar) {
      this.sprite = [[true, true, true, true]];
      this.size = { width: 4, height: 1};
    } else if (type === RockType.Cross) {
      this.sprite = [
        [false, true, false],
        [ true, true, true],
        [false, true, false],
      ];
      this.size = { width: 3, height: 3};
    } else if (type === RockType.Elbow) {
      this.sprite = [
        [false, false, true],
        [false, false, true],
        [ true,  true, true],
      ];
      this.size = { width: 3, height: 3};
    } else if (type === RockType.Pillar) {
      this.sprite = [[true], [true], [true], [true]];
      this.size = { width: 1, height: 4};
    } else if (type === RockType.Box) {
      this.sprite = [[true, true], [true, true]];
      this.size = { width: 2, height: 2};
    } else {
      throw new Error(`Unknown rock type ${type}`);
    }
  }
}

export function createCaveChamber(input: string): CaveChamber {
  const jetPattern: CaveChamber['jetPattern'] = []
  input = input.trim();
  for (let i = 0; i < input.length; i++) {
    jetPattern.push(input[i] === '>' ? Direction.Right : Direction.Left);
  }

  return {
    width: 7,
    jetPattern,
    rockPattern: [RockType.Bar, RockType.Cross, RockType.Elbow, RockType.Pillar, RockType.Box],
    rockSpawnOffset: {x: 2, y: -3},
    stoppedRocksHeight: 0,
    grid: [],
  }
}

export function processFallingRocks(chamber: CaveChamber, amount: number) {
  const { jetPattern, rockPattern } = chamber;

  let step = 0;
  for (let i = 0; i < amount; i++) {
    // console.log(`Rock ${i+1}/${amount} Step ${step}`);
    const fallingRock = spawnRock(chamber, rockPattern[i % rockPattern.length]);
    // console.log(chamberAsString(chamber, fallingRock) + '\n');

    let isFalling = true;
    while (isFalling) {
      const jetDirection = jetPattern[step % jetPattern.length];
      step++;

      if (canShift(chamber, fallingRock, jetDirection)) {
        fallingRock.position.x += getDirectionDelta(jetDirection).deltaX;
      }
      isFalling = canFall(chamber, fallingRock);
      if (isFalling) {
        fallingRock.position.y++;
      }
    }
    stopRock(chamber, fallingRock);
  }
}

function canShift(chamber: CaveChamber, rock: Rock, direction: Direction.Left | Direction.Right): boolean {
  const grid = chamber.grid;
  const { position, size: { width, height }, sprite } = rock;
  const deltaX = getDirectionDelta(direction).deltaX;
  if (position.x + deltaX < 0 || position.x + deltaX + width > chamber.width) {
    return false;
  }

  for (let y = height - 1; y >= 0; y--) {
    const caveY = position.y + y;
    const row = grid[caveY];
    if (!row) {
      continue; // TODO Break instead?
    }

    for (let x = 0; x < width; x++) {
      if (!sprite[y][x]) {
        continue;
      }
      const caveX = position.x + x + deltaX;
      if (row[caveX]) {
        return false;
      }
    }
  }
  return true;
}

function canFall(chamber: CaveChamber, rock: Rock): boolean {
  const grid = chamber.grid;
  const { position, size: { width, height }, sprite } = rock;
  if (position.y + height >= grid.length) {
    return false;
  }

  for (let y = height - 1; y >= 0; y--) {
    const caveY = position.y + y + 1;
    const row = grid[caveY];
    if (!row) {
      continue; // TODO Break instead?
    }

    for (let x = 0; x < width; x++) {
      if (!sprite[y][x]) {
        continue;
      }
      const caveX = position.x + x;
      if (row[caveX]) {
        return false;
      }
    }
  }
  return true;
}

function spawnRock(chamber: CaveChamber, type: RockType): Rock {
  const { rockSpawnOffset } = chamber;
  const rock = new Rock(type, new Point2D(rockSpawnOffset));
  rock.position.y -= rock.size.height;
  return rock;
}

function stopRock(chamber: CaveChamber, rock: Rock) {
  const { position: { x: rockX, y: rockY }, size: { width, height }, sprite } = rock;
  for (let y = rockY + height - 1; y >= rockY; y--) {
    const row: boolean[] = y >= 0 ? chamber.grid[y] : new Array(chamber.width);
    for (let x = 0; x < width; x++) {
      if (sprite[y - rockY][x]) {
        row[x + rockX] = true;
      }
    }
    if (y < 0) {
      chamber.grid.unshift(row);
    }
  }

  // TODO Update rock height
  chamber.stoppedRocksHeight = chamber.grid.length;
  // TODO Reduce cave grid
}

export function chamberAsString(chamber: CaveChamber, fallingRock?: Rock): string {
  let result = formatGrid(chamber.grid, {
    valueFormatter: (isRock, x, y) => {
      if (fallingRock) {
        const { position: { x: leftX, y: topY }, sprite } = fallingRock;
        if (sprite[y - topY]?.[x - leftX]) {
          return '@';
        }
      }
      if (isRock) {
        return '#';
      }
      return '.';
    },
    rowPrefix: '|', rowSuffix: '|',
    columnSuffix: '-',
    outsideCorner: '+',
  });
  if (fallingRock && fallingRock.position.y < 0) {
    const aboveGrid = [];
    for (let y = fallingRock.position.y; y < 0; y++) {
      const row: boolean[] = new Array(chamber.width);
      for (let x = 0; x < fallingRock.size.width; x++) {
        if (fallingRock.sprite[y - fallingRock.position.y]?.[x]) {
          row[x + fallingRock.position.x] = true;
        }
      }
      aboveGrid.push(row);
    }
    result = formatGrid(aboveGrid, {
      valueFormatter: (v) => v ? '@' : '.',
      rowPrefix: '|', rowSuffix: '|',
      columnSuffix: result === '' ? '-' : undefined,
      outsideCorner: result === '' ? '+' : undefined,
    }) + (result !== '' ? '\n' + result : '');
  }
  return result;
}
