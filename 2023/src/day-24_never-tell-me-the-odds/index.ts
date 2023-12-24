import { allPairs, PlainPoint, splitLines, translateBy } from '@util';
import { count, pipe } from 'iter-ops';

// region Types and Globals
interface Vector3 {
  x: number;
  y: number;
  z: number;
}

interface Hailstone {
  position: Vector3;
  velocity: Vector3;

  line: string; // For debug messages
}
// endregion

const verbose = false;

export function solvePart1(input: string, lowerBound: number, upperBound: number): number {
  const hailstones = splitLines(input).map(parseHailstone);
  return pipe(
    allPairs(hailstones),
    count(([a, b]) => intersect2d(a, b, lowerBound, upperBound)),
  ).first!;
}

export function solvePart2(input: string): number {
  const lines = splitLines(input);
  // TODO Implement solution
  return Number.NaN;
}

// region Shared Code
function parseHailstone(line: string): Hailstone {
  const [position, velocity] = line.split('@').map((p) => p.trim());
  const [px, py, pz] = position.split(',').map((v) => Number(v.trim()));
  const [vx, vy, vz] = velocity.split(',').map((v) => Number(v.trim()));

  if (vx === 0 || vy === 0) {
    console.log(line);
  }
  return {
    position: {x: px, y: py, z: pz},
    velocity: {x: vx, y: vy, z: vz},
    line,
  }
}

function intersect2d(a: Hailstone, b: Hailstone, lowerBound: number, upperBound: number): boolean {
  const intersection = intersection2d(a, b);
  if (intersection == null) {
    return false;
  }

  const {x, y} = intersection;
  const inBounds = x >= lowerBound && x <= upperBound && y >= lowerBound && y <= upperBound;
  const inFutureA = isInFuture(a, intersection);
  const inFutureB = isInFuture(b, intersection);

  return inBounds && inFutureA && inFutureB;
}

// https://en.wikipedia.org/wiki/Line%E2%80%93line_intersection#Given_two_points_on_each_line
function intersection2d(a: Hailstone, b: Hailstone): PlainPoint | null {
  const {x: x1, y: y1} = a.position as PlainPoint;
  const {x: x2, y: y2} = translateBy(a.position, a.velocity);
  const {x: x3, y: y3} = b.position as PlainPoint;
  const {x: x4, y: y4} = translateBy(b.position, b.velocity);

  const denominator = (x1 - x2)*(y3 - y4) - (y1 - y2)*(x3 - x4);
  if (denominator === 0) {
    // Parallel or coincident
    return null;
  }

  const coefficient1 = x1*y2 - y1*x2;
  const coefficient2 = x3*y4 - y3*x4;
  const intersectionX = (coefficient1*(x3 - x4) - coefficient2*(x1 - x2)) / denominator;
  const intersectionY = (coefficient1*(y3 - y4) - coefficient2*(y1 - y2)) / denominator;

  return { x: intersectionX, y: intersectionY };
}

function isInFuture(hailstone: Hailstone, { x }: PlainPoint): boolean {
  return Math.sign(hailstone.position.x - x) !== Math.sign(hailstone.velocity.x);
}
// endregion
