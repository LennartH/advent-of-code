

export enum Direction {
  Up = 'U',
  Right = 'R',
  Down = 'D',
  Left = 'L',
}
export const directions = [Direction.Up, Direction.Right, Direction.Down, Direction.Left] as const;
const directionDelta: Record<Direction, { deltaX: number, deltaY: number }> = {
  [Direction.Up]: { deltaX: 0, deltaY: -1 },
  [Direction.Right]: { deltaX: 1, deltaY: 0 },
  [Direction.Down]: { deltaX: 0, deltaY: 1 },
  [Direction.Left]: { deltaX: -1, deltaY: 0 },
};

export function getDirectionDelta(direction: Direction): {deltaX: number, deltaY: number} {
  return directionDelta[direction];
}

export interface Point {
  x: number;
  y: number;
}

export interface Size {
  width: number;
  height: number;
}

export type PointLike = Point | {deltaX: number, deltaY: number} | {dx: number, dy: number} | [number, number];

export function asPoint(data: PointLike): Point {
  let x: number | null = null;
  let y: number | null = null;
  if (Array.isArray(data)) {
    x = data[0];
    y = data[1];
  } else {
    const _data = data as any;
    x = _data.x ?? _data.deltaX ?? _data.dx;
    y = _data.y ?? _data.deltaY ?? _data.dy;
  }
  if (x == null || y == null) {
    throw new Error('Invalid translation delta');
  }
  return { x, y };
}

export function pointAsString(point: PointLike, pretty = false): string {
  const { x, y } = asPoint(point);
  return pretty ? `(${x}, ${y})` : `${x},${y}`;
}

export function distanceToPoint(from: Point, to: Point): number {
  const { x: fromX, y: fromY } = from;
  const { x: toX, y: toY } = to
  const deltaX = toX - fromX;
  const deltaY = toY - fromY;
  return Math.sqrt((deltaX * deltaX) + (deltaY * deltaY));
}

export function directionToPoint(from: Point, to: Point): Direction {
  const vector = { x: to.x - from.x, y: to.y - from.y };
  if (vector.y === 0) {
    return vector.x < 0 ? Direction.Left : Direction.Right;
  }
  if (vector.x === 0) {
    return vector.y < 0 ? Direction.Up : Direction.Down;
  }
  throw new Error(`No straight line from ${pointAsString(from, true)} to ${pointAsString(to, true)}`);
}

export interface Rect {
  x: number;
  y: number;
  width: number;
  height: number;
}

export type RectLike = Rect | {width: number, height: number} | unknown[][];

export function translate(point: Point, by: PointLike): Point {
  const delta = asPoint(by);
  return {
    x: point.x + delta.x,
    y: point.y + delta.y,
  }
}

export function containsPoint(rect: RectLike, point: Point): boolean {
  let rectMinX = 0;
  let rectMinY = 0;
  let width: number;
  let height: number;
  if (Array.isArray(rect)) {
    width = rect[0].length;
    height = rect.length;
  } else {
    ({ width, height } = rect);
    if ('x' in rect && 'y' in rect) {
      rectMinX = rect.x;
      rectMinY = rect.y;
    }
  }
  const rectMaxX = rectMinX + width;
  const rectMaxY = rectMinY + height;
  const { x, y } = point;
  return x >= rectMinX && x < rectMaxX && y >= rectMinY && y < rectMaxY;
}

export function overlap(a: RectLike, b: RectLike): boolean {
  const { x: aX1, y: aY1, width: aWidth, height: aHeight } = asRect(a);
  const aX2 = aX1 + aWidth - 1;
  const aY2 = aY1 + aHeight - 1;
  const { x: bX1, y: bY1, width: bWidth, height: bHeight } = asRect(b);
  const bX2 = bX1 + bWidth - 1;
  const bY2 = bY1 + bHeight - 1;

  return aX1 < bX2 && aX2 >= bX1
      && aY1 < bY2 && aY2 >= bY1;
}

function asRect(rect: RectLike): Rect {
  let x = 0;
  let y = 0;
  let width: number;
  let height: number;
  if (Array.isArray(rect)) {
    width = rect[0].length;
    height = rect.length;
  } else {
    ({ width, height } = rect);
    if ('x' in rect && 'y' in rect) {
      x = rect.x;
      y = rect.y;
    }
  }
  return { x, y, width, height };
}

