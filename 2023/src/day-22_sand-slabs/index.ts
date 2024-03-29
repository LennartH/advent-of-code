import { ArrayGrid, max, PlainPoint, pointsEqual, splitLines, sum } from '@util';

// region Types and Globals
interface Vector3 {
  x: number;
  y: number;
  z: number;
}

interface Brick {
  from: Vector3;
  to: Vector3;

  line: string;
}

type BrickTree = Record<string, Node>;
interface Node {
  above: Node[];
  brick: Brick;
  below: Node[];
}
// endregion

export function solvePart1(input: string): number {
  const bricks = splitLines(input)
    .map(parseBrick)
    .sort((a, b) => Math.min(a.from.z, a.to.z) - Math.min(b.from.z, b.to.z));

  settleBricks(bricks);
  const tree = buildBrickTree(bricks);

  return bricks
    .map(({line}) => numberOfFallingBricksIfDisintegrated(tree[line]))
    .filter((n) => n === 0)
    .length;
}

export function solvePart2(input: string): number {
  const bricks = splitLines(input)
    .map(parseBrick)
    .sort((a, b) => Math.min(a.from.z, a.to.z) - Math.min(b.from.z, b.to.z));

  settleBricks(bricks);
  const tree = buildBrickTree(bricks);

  return bricks
    .map(({line}) => numberOfFallingBricksIfDisintegrated(tree[line]))
    .reduce(sum);
}

// region Shared Code
function parseBrick(line: string): Brick {
  const [from, to] = line.split('~');
  const [x1, y1, z1] = from.split(',').map(Number);
  const [x2, y2, z2] = to.split(',').map(Number);
  return {
    from: {x: x1, y: y1, z: z1},
    to: {x: x2, y: y2, z: z2},
    line,
  };
}

function settleBricks(bricks: Brick[]) {
  const groundDimensions = bricks.reduce((acc, {from, to}) => {
    acc.maxX = Math.max(from.x, to.x, acc.maxX);
    acc.maxY = Math.max(from.y, to.y, acc.maxY);
    return acc;
  }, {maxX: 0, maxY: 0});
  const groundLevel = new ArrayGrid(groundDimensions.maxX + 1, groundDimensions.maxY + 1, 0);

  for (const brick of bricks) {
    const shadowPoints = brickShadowPoints(brick);
    const maxGroundLevel = shadowPoints.map((p) => groundLevel.get(p)).reduce(max);

    const deltaZ = Math.abs(brick.from.z - brick.to.z);
    brick.from.z = maxGroundLevel + 1;
    brick.to.z = brick.from.z + deltaZ;

    shadowPoints.forEach((p) => groundLevel.set(p, brick.to.z));
  }
}

function buildBrickTree(bricks: Brick[]): BrickTree {
  const tree = Object.fromEntries<Node>(bricks.map((brick) => {
    return [
      brick.line,
      { above: [], brick, below: [], },
    ]
  }));

  const bricksByZ = new Array(bricks.map(({to: {z}}) => z).reduce(max) + 2)
    .fill(0).map<Brick[]>(() => []);
  bricks.forEach((brick) => {
    bricksByZ[brick.from.z].push(brick);
    if (brick.from.z !== brick.to.z) {
      bricksByZ[brick.to.z].push(brick);
    }
  });
  for (const node of Object.values(tree)) {
    node.below = bricksByZ[node.brick.from.z - 1]
      .filter((o) => bricksAreTouching(node.brick, o))
      .map(({line}) => tree[line]);
    node.above = bricksByZ[node.brick.to.z + 1]
      .filter((o) => bricksAreTouching(node.brick, o))
      .map(({line}) => tree[line]);
  }

  return tree;
}

function numberOfFallingBricksIfDisintegrated(node: Node): number {
  const visited = new Set<string>();
  const open = node.above.filter(({below}) => below.length === 1);
  const falling = new Set(open.map(({brick}) => brick.line));
  while (open.length > 0) {
    const current = open.pop()!;
    const key = current.brick.line;
    if (visited.has(key)) {
      continue;
    }
    visited.add(key);

    for (const next of current.above.filter(({below}) => below.every(({brick}) => falling.has(brick.line)))) {
      const key = next.brick.line;
      if (visited.has(key)) {
        continue;
      }
      open.push(next);
      falling.add(key);
    }
  }
  return falling.size;
}

function brickShadowPoints(brick: Brick): PlainPoint[] {
  const points: PlainPoint[] = [];

  const {x: x1, y: y1} = brick.from;
  const {x: x2, y: y2} = brick.to;
  if (x1 === x2 && y1 === y2) {
    points.push({x: x1, y: y1});
  } else if (y1 === y2) {
    const deltaX = Math.sign(x2 - x1);
    for (let x = x1; x <= x2; x += deltaX) {
      points.push({x, y: y1});
    }
  } else {
    const deltaY = Math.sign(y2 - y1);
    for (let y = y1; y <= y2; y += deltaY) {
      points.push({x: x1, y});
    }
  }

  return points;
}

function bricksAreTouching(a: Brick, b: Brick): boolean {
  const pointsA = brickShadowPoints(a);
  const pointsB = brickShadowPoints(b);
  return pointsA.some((p1) => pointsB.some((p2) => pointsEqual(p1, p2)))
}
// endregion
