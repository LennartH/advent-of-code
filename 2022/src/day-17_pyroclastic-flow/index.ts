import { Direction, getDirectionDelta, overlap, Point, Rect, Size } from '@util/misc';

export interface CaveChamber {
  width: number;
  jetPattern: (Direction.Left | Direction.Right)[];
  rockPattern: RockShape[];
  rockSpawner: Point;

  stoppedRocksHeight: number;
  stoppedRocks: Rock[];
}

export enum RockShape {
  Bar = '_',
  Cross = '+',
  Elbow = 'e',
  Pillar = '|',
  Box = 'o',
}
const shapeSprite: Record<RockShape, boolean[][]> = {
  [RockShape.Bar]: [
    [true, true, true, true],
  ],
  [RockShape.Cross]: [
    [false, true, false],
    [ true, true, true],
    [false, true, false],
  ],
  [RockShape.Elbow]: [
    [false, false, true],
    [false, false, true],
    [ true,  true, true],
  ],
  [RockShape.Pillar]: [
    [true],
    [true],
    [true],
    [true],
  ],
  [RockShape.Box]: [
    [true, true],
    [true, true],
  ],
}
const shapeSize: Record<RockShape, Size> = {
  [RockShape.Bar]: { width: 4, height: 1},
  [RockShape.Cross]: { width: 3, height: 3 },
  [RockShape.Elbow]: { width: 3, height: 3 },
  [RockShape.Pillar]: { width: 1, height: 4 },
  [RockShape.Box]: { width: 2, height: 2 },
}

export interface Rock {
  boundingBox: Rect;
  shape: RockShape;
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
    rockPattern: [RockShape.Bar, RockShape.Cross, RockShape.Elbow, RockShape.Pillar, RockShape.Box],
    rockSpawner: {x: 2, y: -3},
    stoppedRocksHeight: 0,
    stoppedRocks: [],
  }
}

export function processFallingRocks(chamber: CaveChamber, amount: number) {
  const { width, jetPattern, rockPattern } = chamber;

  let step = 0;
  for (let i = 0; i < amount; i++) {
    console.log(`Rock ${i+1}/${amount}`)
    const shape = rockPattern[i % rockPattern.length];
    const fallingRock = initializeRock(chamber, shape);
    let isFalling = true;
    while (isFalling) {
      const jetDirection = jetPattern[step % jetPattern.length];
      step++;

      let nextX = fallingRock.boundingBox.x + getDirectionDelta(jetDirection).deltaX;
      if (nextX >= 0 && nextX + fallingRock.boundingBox.width - 1 < width) {
        fallingRock.boundingBox.x = nextX;
      }
      const hasContact = (chamber.stoppedRocks.length === 0 || fallingRock.boundingBox.y + fallingRock.boundingBox.height - 1 >= chamber.stoppedRocks[0].boundingBox.y) && rockHasContact(chamber, fallingRock);
      if (hasContact) {
        chamber.stoppedRocks.unshift(fallingRock);
        chamber.stoppedRocks.sort((a, b) => a.boundingBox.y - b.boundingBox.y);
        chamber.stoppedRocksHeight = Math.max(chamber.stoppedRocksHeight, -1 * fallingRock.boundingBox.y);
        isFalling = false;
      } else {
        fallingRock.boundingBox.y++;
      }
    }
  }
}

function initializeRock(chamber: CaveChamber, shape: RockShape): Rock {
  const { rockSpawner, stoppedRocksHeight } = chamber;
  const size = shapeSize[shape];
  return {
    boundingBox: {
      x: rockSpawner.x,
      y: -stoppedRocksHeight - size.height + rockSpawner.y,
      ...size,
    },
    shape,
  }
}

function rockHasContact(chamber: CaveChamber, rock: Rock): boolean {
  const sprite = shapeSprite[rock.shape];
  const nextBoundingBox = { ...rock.boundingBox, y: rock.boundingBox.y + 1 };
  if (nextBoundingBox.y + nextBoundingBox.height > 0) {
    return true;
  }
  for (const other of chamber.stoppedRocks) {
    if (!overlap(nextBoundingBox, other.boundingBox)) {
      continue;
    }
    const otherSprite = shapeSprite[other.shape];
    for (let y = nextBoundingBox.y + nextBoundingBox.height - 1; y > nextBoundingBox.y; y--) {
      for (let x = nextBoundingBox.x; x < nextBoundingBox.x + nextBoundingBox.width; x++) {
        const localX = x - nextBoundingBox.x;
        const localY = y - nextBoundingBox.y;
        const otherX = x - other.boundingBox.x;
        const otherY = y - other.boundingBox.y;
        if (sprite[localY][localX] && otherSprite[otherY]?.[otherX]) {
          return true;
        }
      }
    }
  }
  return false;
}
