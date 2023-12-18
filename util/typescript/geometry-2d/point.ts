import { clamp } from '../number';
import { PlainSize } from './size';

// TODO Utility functions should also work with plain points

export interface PlainPoint {
  x: number;
  y: number;
}

export type PointLike =
  | PlainPoint
  | { deltaX: number, deltaY: number }
  | { dx: number, dy: number }
  | PlainSize
  | [ number, number ];

export class Point2D {
  x: number;
  y: number;

  constructor()
  constructor(x: number, y: number)
  constructor(data: PointLike)
  constructor(dataOrX?: number | PointLike, yValue?: number) {
    if (dataOrX !== undefined) {
      const { x, y } = asPlainPoint(dataOrX, yValue);
      this.x = x;
      this.y = y;
    } else {
      this.x = 0;
      this.y = 0;
    }
  }

  translateBy(scalar: number): Point2D
  translateBy(x: number, y: number): Point2D
  translateBy(data: PointLike): Point2D
  translateBy(scalarOrDataOrX: number | PointLike, yValue?: number): Point2D {

    const { x, y } = asPlainPoint(scalarOrDataOrX, yValue);
    this.x += x;
    this.y += y;
    return this;
  }

  scaleBy(scalar: number): Point2D
  scaleBy(x: number, y: number): Point2D
  scaleBy(data: PointLike): Point2D
  scaleBy(scalarOrDataOrX: number | PointLike, yValue?: number): Point2D {
    const { x, y } = asPlainPoint(scalarOrDataOrX, yValue);
    this.x *= x;
    this.y *= y;
    return this;
  }

  clamp(min: number | PointLike, max: number | PointLike): Point2D {
    const {x: minX, y: minY} = asPlainPoint(min);
    const {x: maxX, y: maxY} = asPlainPoint(max);
    this.x = clamp(this.x, minX, maxX);
    this.y = clamp(this.y, minY, maxY);
    return this;
  }

  euclideanDistanceTo(x: number, y: number): number
  euclideanDistanceTo(data: PointLike): number
  euclideanDistanceTo(dataOrX: number | PointLike, yValue?: number): number {
    return Math.sqrt(this.euclideanDistanceSquaredTo(asPlainPoint(dataOrX, yValue)));
  }

  euclideanDistanceSquaredTo(x: number, y: number): number
  euclideanDistanceSquaredTo(data: PointLike): number
  euclideanDistanceSquaredTo(dataOrX: number | PointLike, yValue?: number): number {
    const { x: fromX, y: fromY } = this;
    const { x: toX, y: toY } = asPlainPoint(dataOrX, yValue);
    const deltaX = toX - fromX;
    const deltaY = toY - fromY;
    return (deltaX * deltaX) + (deltaY * deltaY);
  }

  manhattanDistanceTo(x: number, y: number): number
  manhattanDistanceTo(data: PointLike): number
  manhattanDistanceTo(dataOrX: number | PointLike, yValue?: number): number {
    const { x: fromX, y: fromY } = this;
    const { x: toX, y: toY } = asPlainPoint(dataOrX, yValue);
    const deltaX = toX - fromX;
    const deltaY = toY - fromY;
    return Math.abs(deltaX) + Math.abs(deltaY);
  }

  clone(): Point2D {
    return new Point2D(this);
  }

  toString(pretty = false): string {
    return pretty ? `(${this.x}, ${this.y})` : `${this.x},${this.y}`;
  }
}

export function translateBy(point: PointLike, byValue: number): PlainPoint
export function translateBy(point: PointLike, by: PointLike): PlainPoint
export function translateBy(point: PointLike, byX: number, byY: number): PlainPoint
export function translateBy(x: number, y: number, byValue: number): PlainPoint
export function translateBy(x: number, y: number, by: PointLike): PlainPoint
export function translateBy(x: number, y: number, byX: number, byY: number): PlainPoint
export function translateBy(...args: GenericOperationArgs): PlainPoint {
  const {a, b: by} = getPointsFromArgs(args);
  return {
    x: a.x + by.x,
    y: a.y + by.y,
  };
}

export function scaleBy(point: PointLike, byValue: number): PlainPoint
export function scaleBy(point: PointLike, by: PointLike): PlainPoint
export function scaleBy(point: PointLike, byX: number, byY: number): PlainPoint
export function scaleBy(x: number, y: number, byValue: number): PlainPoint
export function scaleBy(x: number, y: number, by: PointLike): PlainPoint
export function scaleBy(x: number, y: number, byX: number, byY: number): PlainPoint
export function scaleBy(...args: GenericOperationArgs): PlainPoint {
  const {a, b: by} = getPointsFromArgs(args);
  return {
    x: a.x * by.x,
    y: a.y * by.y,
  };
}

export function manhattanDistance(from: PointLike, to: PointLike): number
export function manhattanDistance(from: PointLike, toX: number, toY: number): number
export function manhattanDistance(fromX: number, fromY: number, to: PointLike): number
export function manhattanDistance(fromX: number, fromY: number, toX: number, toY: number): number
export function manhattanDistance(...args: GenericOperationArgs): number {
  const {
    a: { x: fromX, y: fromY},
    b: { x: toX, y: toY}
  } = getPointsFromArgs(args);
  return Math.abs(toX - fromX) + Math.abs(toY - fromY);
}

export function crossProduct(p1: PointLike, p2: PointLike): number
export function crossProduct(p1: PointLike, x2: number, y2: number): number
export function crossProduct(x1: number, y1: number, p2: PointLike): number
export function crossProduct(x1: number, y1: number, x2: number, y2: number): number
export function crossProduct(...args: GenericOperationArgs): number {
  const {
    a: { x: x1, y: y1},
    b: { x: x2, y: y2}
  } = getPointsFromArgs(args);
  return (x1 * y2) - (x2 * y1);
}

export function pointsEqual(p1: PointLike, p2: PointLike): boolean
export function pointsEqual(p1: PointLike, x2: number, y2: number): boolean
export function pointsEqual(x1: number, y1: number, p2: PointLike): boolean
export function pointsEqual(x1: number, y1: number, x2: number, y2: number): boolean
export function pointsEqual(...args: GenericOperationArgs): boolean {
  const {
    a: { x: x1, y: y1},
    b: { x: x2, y: y2}
  } = getPointsFromArgs(args);
  return x1 === x2 && y1 === y2;
}

type GenericOperationArgs =
  [PointLike, number | PointLike] |
  [PointLike, number, number] |
  [number, number, number] |
  [number, number, PointLike] |
  [number, number, number, number];
function getPointsFromArgs(args: GenericOperationArgs): {a: PlainPoint, b: PlainPoint} {
  if (args.length === 4) {
    const [x1, y1, x2, y2] = args;
    return {
      a: {x: x1, y: y1},
      b: {x: x2, y: y2},
    }
  }
  if (typeof args[0] === 'object') {
    const { x: x1, y: y1 } = asPlainPoint(args[0]);
    const { x: x2, y: y2} = asPlainPoint(args[1], args[2] as never);
    return {
      a: {x: x1, y: y1},
      b: {x: x2, y: y2},
    }
  }
  if (typeof args[0] === 'number') {
    const [x1, y1] = args as number[];
    const { x: x2, y: y2} = asPlainPoint(args[2]);
    return {
      a: {x: x1, y: y1},
      b: {x: x2, y: y2},
    }
  }
  throw Error(`Unexpected arguments: ${JSON.stringify(args)}`);
}

export function pointToString(scalar: number, pretty?: boolean): string
export function pointToString(x: number, y: number, pretty?: boolean): string
export function pointToString(point: PointLike, pretty?: boolean): string
export function pointToString(scalarOrXOrPoint: number | PointLike, yOrPretty: number | boolean | undefined, pretty?: boolean): string {
  const { x, y } = typeof yOrPretty === 'boolean' ? asPlainPoint(scalarOrXOrPoint) : asPlainPoint(scalarOrXOrPoint, yOrPretty);
  pretty = pretty ?? (typeof yOrPretty === 'boolean' ? yOrPretty : false);
  return pretty ? `(${x}, ${y})` : `${x},${y}`;
}

export function asPlainPoint(scalar: number): PlainPoint
export function asPlainPoint(x: number, y: number): PlainPoint
export function asPlainPoint(data: PointLike): PlainPoint
export function asPlainPoint(scalarOrDataOrX?: number | PointLike, yValue?: number): PlainPoint
export function asPlainPoint(scalarOrDataOrX?: number | PointLike, yValue?: number): PlainPoint {
  if (scalarOrDataOrX instanceof Point2D) {
    return scalarOrDataOrX;
  }

  let x: number;
  let y: number;
  if (typeof scalarOrDataOrX === 'number') {
    x = scalarOrDataOrX;
    if (yValue !== undefined) {
      y = yValue;
    } else {
      y = scalarOrDataOrX;
    }
  } else {
    const data = scalarOrDataOrX as PointLike;
    if (Array.isArray(data)) {
      x = data[0];
      y = data[1];
    } else {
      const _data = data as any;
      x = _data.x ?? _data.deltaX ?? _data.dx ?? _data.width;
      y = _data.y ?? _data.deltaY ?? _data.dy ?? _data.height;
    }
  }
  return { x, y };
}
