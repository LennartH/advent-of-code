import { asPlainPoint, PlainPoint, Point2D, PointLike } from './point';
import { PlainSize } from './size';

export interface PlainRect {
  position: PlainPoint;
  size: PlainSize;
}

export type RectLike =
  | PlainRect
  | (PlainPoint & PlainSize)
  | PlainSize;

export class Rect2D {
  position: Point2D;
  size: PlainSize;

  get topLeft(): Point2D {
    return this.position.clone();
  }

  get bottomRight(): Point2D {
    return this.topLeft.translateBy(this.size).translateBy(-1, -1);
  }

  constructor(size: number)
  constructor(width: number, height: number)
  constructor(data: RectLike)
  constructor(sizeOrWidthOrData: RectLike | number, height?: number) {
    const { position, size } = asPlainRect(sizeOrWidthOrData, height);
    this.position = new Point2D(position);
    this.size = size;
  }

  toLocalPosition(x: number, y: number): Point2D
  toLocalPosition(point: PointLike): Point2D
  toLocalPosition(xOrData: PointLike | number, yValue?: number): Point2D {
    const localPosition = new Point2D(xOrData as never, yValue as never);
    if (!this.containsPoint(localPosition)) {
      throw new Error(`Given point ${localPosition.toString(true)} not contained by rectangle`);
    }
    return localPosition.translateBy(this.position.clone().scaleBy(-1));
  }

  containsPoint(x: number, y: number): boolean
  containsPoint(point: PointLike): boolean
  containsPoint(xOrData: PointLike | number, yValue?: number): boolean {
    const { x, y } = asPlainPoint(xOrData, yValue);
    const { x: minX, y: minY } = this.position;
    const maxX = minX + this.size.width;
    const maxY = minY + this.size.height;
    return x >= minX && x < maxX && y >= minY && y < maxY;
  }

  isOverlapping(other: RectLike): boolean {
    const { x: minX, y: minY } = this.position;
    const { x: maxX, y: maxY } = this.bottomRight;
    const { position: { x: otherX1, y: otherY1 }, size: { width: otherWidth, height: otherHeight} } = asPlainRect(other);
    const otherX2 = otherX1 + otherWidth - 1;
    const otherY2 = otherY1 + otherHeight - 1;

    return minX < otherX2 && maxX >= otherX1
        && minY < otherY2 && maxY >= otherY1;
  }

}

export function asPlainRect(size: number): PlainRect
export function asPlainRect(width: number, height: number): PlainRect
export function asPlainRect(data: RectLike): PlainRect
export function asPlainRect(sizeOrWidthOrData: RectLike | number, height?: number): PlainRect
export function asPlainRect(sizeOrWidthOrData: RectLike | number, heightValue?: number): PlainRect {
  if (sizeOrWidthOrData instanceof Rect2D) {
    return sizeOrWidthOrData;
  }

  let x: number, y: number, width: number, height: number;
  if (typeof sizeOrWidthOrData === 'number') {
    x = 0;
    y = 0;
    width = sizeOrWidthOrData;
    if (heightValue !== undefined) {
      height = heightValue;
    } else {
      height = sizeOrWidthOrData;
    }
  } else {
    const data = sizeOrWidthOrData as RectLike;
    if ('width' in data) {
      x = 'x' in data ? data.x : 0;
      y = 'y' in data ? data.y : 0;
      width = data.width;
      height = data.height;
    } else {
      ({ x, y } = data.position);
      ({ width, height } = data.size);
    }
  }
  return { position: { x, y }, size: { width, height }};
}
