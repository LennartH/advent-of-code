import { clamp } from '../number';
import { PlainSize } from './size';

// TODO Rename to Vector2

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
