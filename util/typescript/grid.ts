import { asPlainPoint, PointLike } from './geometry-2d';

export interface Grid<V> {
  get width(): number;
  get height(): number;

  get(x: number, y: number): V;
  get(point: PointLike): V;

  set(x: number, y: number, value: V): void;
  set(point: PointLike, value: V): void;
}

export abstract class AbstractGrid<V> implements Grid<V> {
  abstract get height(): number;
  abstract get width(): number;

  get(x: number, y: number): V
  get(point: PointLike): V
  get(pointOrX: PointLike | number, yValue?: number): V {
    const {x, y} = asPlainPoint(pointOrX, yValue);
    return this._get(x, y);
  }
  protected abstract _get(x: number, y: number): V;

  set(x: number, y: number, value: V): void
  set(point: PointLike, value: V): void
  set(...args: [number, number, V] | [PointLike, V]): void {
    let x, y: number; let v: V;
    if (args.length === 3) {
      x = args[0];
      y = args[1];
      v = args[2];
    } else {
      ({x, y} = asPlainPoint(args[0]));
      v = args[1];
    }
    return this._set(x, y, v);
  }
  protected abstract _set(x: number, y: number, value: V): void;
}

export class ArrayGrid<V> extends AbstractGrid<V> {
  data: V[][];

  get height(): number {
    return this.data.length;
  }

  get width(): number {
    return this.data[0].length;
  }

  constructor(width: number, height: number, defaultValue?: V)
  constructor(data: V[][])
  constructor(dataOrWidth: number | V[][], height?: number, defaultValue?: V) {
    super();
    if (Array.isArray(dataOrWidth)) {
      this.data = dataOrWidth;
    } else {
      this.data = new Array(height);
      for (let y = 0; y < this.data.length; y++) {
        this.data[y] = new Array(dataOrWidth);
        if (defaultValue !== undefined) {
          this.data[y].fill(defaultValue);
        }
      }
    }
  }

  protected _get(x: number, y: number): V {
    return this.data[y][x];
  }

  protected _set(x: number, y: number, value: V) {
    this.data[y][x] = value;
  }
}
