import { asPlainPoint, Direction2D, getDirections, PlainPoint, PointLike } from './geometry-2d';
import { splitLines } from './string';

export interface Grid<V> {
  get width(): number;
  get height(): number;

  cells(): Generator<GridCell<V>>;

  get(x: number, y: number): V;
  get(point: PointLike): V;

  set(x: number, y: number, value: V): void;
  set(point: PointLike, value: V): void;

  contains(x: number, y: number): boolean;
  contains(point: PointLike): boolean;

  adjacentFrom(x: number, y: number, options?: AdjacentFromOptions<V>): Generator<GridCell<V>>;
  adjacentFrom(point: PointLike, options?: AdjacentFromOptions<V>): Generator<GridCell<V>>;
  adjacentFrom(x: number, y: number, options?: AdjacentFromOptions<V>): Generator<GridCell<V>>;
  adjacentFrom(point: PointLike, options?: AdjacentFromOptions<V>): Generator<GridCell<V>>;
}

export interface GridCell<V> {
  position: PlainPoint;
  value: V;
}

// TODO Improve typing
export type AdjacentFromOptions<V> = {
  withDiagonals?: boolean;
  onOutOfBounds?: 'drop' | 'keep' | AdjacentOutOfBoundsHandler<V>;
} | {
  directions: Direction2D[];
  onOutOfBounds?: 'drop' | 'keep' | AdjacentOutOfBoundsHandler<V>;
};
type AdjacentOutOfBoundsHandler<V> = (position: PlainPoint, grid: Grid<V>) => PlainPoint | 'drop' | 'keep' | boolean;

export abstract class AbstractGrid<V> implements Grid<V> {
  abstract get height(): number;
  abstract get width(): number;

  * cells(): Generator<GridCell<V>> {
    const width = this.width;
    const height = this.height;
    for (let x = 0; x < width; x++) {
      for (let y = 0; y < height; y++) {
        yield {position: {x, y}, value: this.get(x, y)};
      }
    }
  }

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

  contains(x: number, y: number): boolean
  contains(point: PointLike): boolean
  contains(pointOrX: PointLike | number, yValue?: number): boolean {
    const {x, y} = asPlainPoint(pointOrX, yValue);
    return x >= 0 && x < this.width && y >= 0 && y < this.height;
  }

  adjacentFrom(x: number, y: number, options?: AdjacentFromOptions<V>): Generator<GridCell<V>>
  adjacentFrom(point: PointLike, options?: AdjacentFromOptions<V>): Generator<GridCell<V>>
  adjacentFrom(x: number, y: number, options?: AdjacentFromOptions<V>): Generator<GridCell<V>>
  adjacentFrom(point: PointLike, options?: AdjacentFromOptions<V>): Generator<GridCell<V>>
  * adjacentFrom(
    pointOrX: PointLike | number,
    yValueOrOptions?: number | AdjacentFromOptions<V>,
    options?: AdjacentFromOptions<V>,
  ): Generator<GridCell<V>> {
    let x: number;
    let y: number;
    if (typeof pointOrX === 'number') {
      x = pointOrX;
      y = yValueOrOptions as number;
    } else {
      ({x, y} = asPlainPoint(pointOrX));
      options = yValueOrOptions as never;
    }
    options ||= {};
    const directions = 'directions' in options ? options.directions : getDirections('cardinal', options);

    const onOutOfBounds = options.onOutOfBounds || 'drop';
    for (const {deltaX, deltaY} of directions) {
      let position = { x: x + deltaX, y: y + deltaY };
      if (!this.contains(position)) {
        const outOfBoundsResponse = typeof onOutOfBounds === 'function' ? onOutOfBounds(position, this) : onOutOfBounds;
        if (typeof outOfBoundsResponse === 'object') {
          position = outOfBoundsResponse;
        } else if (!outOfBoundsResponse || outOfBoundsResponse === 'drop') {
          continue;
        }
      }

      const value = this.get(position);
      yield { position, value };
    }
  }
}

export class ArrayGrid<V> extends AbstractGrid<V> {
  static fromInput(input: string): ArrayGrid<string> {
    return new ArrayGrid(splitLines(input).map((l) => l.split('')));
  }

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

export class SparseArrayGrid<V> extends AbstractGrid<V> {
  data: V[][];
  height: number;
  width: number;

  constructor(width: number, height: number)
  constructor(data: V[][], width: number, height: number)
  constructor(dataOrWidth: number | V[][], widthOrHeight: number, height?: number) {
    super();
    if (Array.isArray(dataOrWidth)) {
      this.data = dataOrWidth;
      this.width = widthOrHeight;
      this.height = height!;
    } else {
      this.data = [];
      this.width = dataOrWidth;
      this.height = widthOrHeight;
    }
  }

  protected _get(x: number, y: number): V {
    return this.data[y]?.[x];
  }

  protected _set(x: number, y: number, value: V) {
    let row = this.data[y];
    if (!row) {
      row = [];
      this.data[y] = row;
    }
    row[x] = value;
  }

  * cells(): Generator<GridCell<V>> {
    const width = this.width;
    const height = this.height;
    for (let x = 0; x < width; x++) {
      for (let y = 0; y < height; y++) {
        const value = this.get(x, y);
        if (value != null) {
          yield {position: {x, y}, value};
        }
      }
    }
  }

}
