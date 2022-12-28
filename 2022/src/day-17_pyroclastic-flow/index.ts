import { Direction, getDirectionDelta, Point } from '@util/misc';
import { formatGrid, Point2D } from '@util';

export interface CaveChamber {
  width: number;
  jetPattern: (Direction.Left | Direction.Right)[];
  rockPattern: RockType[];
  rockSpawnOffset: Point;

  rockCount: number;
  jetIndex: number;
  stoppedRocksHeight: number;
  grid: boolean[][];
  stateCache: Map<string, {rockCount: number, rockHeight: number}>[];
  cycleFound: boolean;
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

    rockCount: 0,
    jetIndex: 0,
    stoppedRocksHeight: 0,
    grid: [],
    stateCache: [new Map()],
    cycleFound: false,
  }
}

export function processFallingRocks(chamber: CaveChamber, amount: number) {
  const { jetPattern, rockPattern } = chamber;

  while (chamber.rockCount < amount) {
    const fallingRock = spawnRock(chamber, rockPattern[chamber.rockCount % rockPattern.length]);

    let isFalling = true;
    while (isFalling) {
      const jetDirection = jetPattern[chamber.jetIndex];
      chamber.jetIndex = (chamber.jetIndex + 1) % jetPattern.length;

      if (canShift(chamber, fallingRock, jetDirection)) {
        fallingRock.position.x += getDirectionDelta(jetDirection).deltaX;
      }
      isFalling = canFall(chamber, fallingRock);
      if (isFalling) {
        fallingRock.position.y++;
      }
    }
    stopRock(chamber, fallingRock, amount);
    chamber.rockCount++;
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
      break;
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
      break;
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

function stopRock(chamber: CaveChamber, rock: Rock, targetRockCount: number) {
  const { width: chamberWidth, rockCount, jetIndex, grid, stateCache, cycleFound } = chamber;
  const { position: { x: rockX, y: rockY }, size: { width, height }, sprite } = rock;
  for (let y = rockY + height - 1; y >= rockY; y--) {
    const row: boolean[] = y >= 0 ? grid[y] : new Array(chamberWidth);
    for (let x = 0; x < width; x++) {
      if (sprite[y - rockY][x]) {
        row[x + rockX] = true;
      }
    }
    if (y < 0) {
      grid.unshift(row);
      chamber.stoppedRocksHeight++;
    }
  }

  const columnDepth: number[] = new Array(chamberWidth);
  for (let x = 0; x < chamberWidth; x++) {
    let hitRock = false;
    for (let y = 0; y < grid.length; y++) {
      if (grid[y][x]) {
        columnDepth[x] = y;
        hitRock = true;
        break;
      }
    }
    if (!hitRock) {
      columnDepth[x] = grid.length - 1;
    }
  }
  const maxY = columnDepth.reduce((m, v) => v > m ? v : m, 0);
  if (maxY < grid.length - 1) {
    grid.splice(maxY + 1);
  }

  if (cycleFound) {
    return;
  }

  const currentState = `${rock.type}|${jetIndex}|${columnDepth.join(',')}`;
  const cacheEntry = stateCache.find((c) => c.has(currentState))?.get(currentState);
  if (!cacheEntry) {
    try {
      stateCache[stateCache.length - 1].set(currentState, {rockCount, rockHeight: chamber.stoppedRocksHeight})
    } catch (error) {
      if (!(error instanceof RangeError)) {
        throw error;
      }
      const nextCache = new Map();
      nextCache.set(currentState, {rockCount, rockHeight: chamber.stoppedRocksHeight});
      stateCache.push(nextCache);
    }
  } else {
    chamber.cycleFound = true;

    const rocksPerCycle = rockCount - cacheEntry.rockCount;
    const heightPerCycle = chamber.stoppedRocksHeight - cacheEntry.rockHeight;
    const remainingRocks = targetRockCount - rockCount;

    const cyclesCount = Math.floor(remainingRocks / rocksPerCycle);
    const remainingRocksAfterCycles = remainingRocks % rocksPerCycle;

    chamber.stoppedRocksHeight += heightPerCycle * cyclesCount;
    chamber.rockCount = targetRockCount - remainingRocksAfterCycles;
    console.log(`Cycle found, skipping from ${rockCount} to ${chamber.rockCount} rocks`);
  }
}

export function chamberAsString(chamber: CaveChamber, fallingRock?: Rock): string {
  const wasReduced = chamber.stoppedRocksHeight > chamber.grid.length;
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
    columnSuffix: wasReduced ? '~' : '-',
    outsideCorner: wasReduced ? undefined : '+',
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
