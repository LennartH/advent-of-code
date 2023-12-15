import { asPlainPoint, Direction2D, getDirections, PlainPoint, PointLike } from './geometry-2d';
import { splitLines } from './string';

export interface Grid<V> {
  get width(): number;
  get height(): number;

  cells(): Generator<GridCell<V>>;
  row(y: number): Generator<GridCell<V>>;
  row(point: PointLike): Generator<GridCell<V>>;
  column(x: number): Generator<GridCell<V>>;
  column(point: PointLike): Generator<GridCell<V>>;

  cellValues(): Generator<V>;
  rowValues(y: number): Generator<V>;
  rowValues(point: PointLike): Generator<V>;
  columnValues(x: number): Generator<V>;
  columnValues(point: PointLike): Generator<V>;

  get(x: number, y: number): V;
  get(point: PointLike): V;

  set(x: number, y: number, value: V): void;
  set(point: PointLike, value: V): void;
  // TODO move value

  floodFill(x: number, y: number, newValue?: V): GridCell<V>[];
  floodFill(x: number, y: number, options?: FloodFillOptions<V>): GridCell<V>[];
  floodFill(point: PointLike, newValue?: V): GridCell<V>[];
  floodFill(point: PointLike, options?: FloodFillOptions<V>): GridCell<V>[];

  contains(x: number, y: number): boolean;
  contains(point: PointLike): boolean;

  adjacentFrom(x: number, y: number, options?: AdjacentFromOptions<V>): Generator<GridCell<V>>;
  adjacentFrom(point: PointLike, options?: AdjacentFromOptions<V>): Generator<GridCell<V>>;
  adjacentFrom(x: number, y: number, options?: AdjacentFromOptions<V>): Generator<GridCell<V>>;
  adjacentFrom(point: PointLike, options?: AdjacentFromOptions<V>): Generator<GridCell<V>>;

  // TODO find path
  // TODO get/set rect
}

export interface GridCell<V> {
  position: PlainPoint;
  value: V;
}

export type FloodFillOptions<V> = {
  withDiagonals?: boolean;
} & (
  { newValue?: V; newValueForCell?: never } |
  { newValueForCell?: CellValueMapper<V>; newValue?: never }
) & (
  { floodableValues?: V | V[]; isFloodable?: never} |
  { isFloodable?: CellPredicate<V>; floodableValues?: never}
);

export type CellPredicate<V> = (cell: GridCell<V>) => boolean;
export type CellValueMapper<V> = (cell: GridCell<V>) => V | undefined;

export type AdjacentFromOptions<V> = {
  onOutOfBounds?: 'drop' | 'keep' | AdjacentOutOfBoundsHandler<V>;
} & (
  { withDiagonals?: boolean; directions?: never } |
  { directions: Direction2D[]; withDiagonals?: never }
);
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

  * cellValues(): Generator<V> {
    for (const {value} of this.cells()) {
      yield value;
    }
  }

  row(y: number): Generator<GridCell<V>>
  row(point: PointLike): Generator<GridCell<V>>
  * row(pointOrY: PointLike | number): Generator<GridCell<V>> {
    const { y } = asPlainPoint(pointOrY);
    const width = this.width;
    for (let x = 0; x < width; x++) {
      yield {position: {x, y}, value: this.get(x, y)};
    }
  }

  rowValues(y: number): Generator<V>
  rowValues(point: PointLike): Generator<V>
  * rowValues(pointOrY: PointLike | number): Generator<V> {
    for (const {value} of this.row(pointOrY as never)) {
      yield value;
    }
  }

  column(x: number): Generator<GridCell<V>>
  column(point: PointLike): Generator<GridCell<V>>
  * column(pointOrX: PointLike | number): Generator<GridCell<V>> {
    const { x } = asPlainPoint(pointOrX);
    const height = this.height;
    for (let y = 0; y < height; y++) {
      yield {position: {x, y}, value: this.get(x, y)};
    }
  }

  columnValues(x: number): Generator<V>
  columnValues(point: PointLike): Generator<V>
  * columnValues(pointOrX: PointLike | number): Generator<V> {
    for (const {value} of this.column(pointOrX as never)) {
      yield value;
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

  floodFill(x: number, y: number, newValue?: V): GridCell<V>[]
  floodFill(x: number, y: number, options?: FloodFillOptions<V>): GridCell<V>[]
  floodFill(point: PointLike, newValue?: V): GridCell<V>[]
  floodFill(point: PointLike, options?: FloodFillOptions<V>): GridCell<V>[]
  floodFill(...args: (number | PointLike | V | FloodFillOptions<V> | undefined)[]): GridCell<V>[] {
    // TODO Well, this is a mess...
    let start: PlainPoint;
    let newValueOrOptions: V | FloodFillOptions<V> | undefined;
    if (typeof args[0] === 'number') {
      start = {x: args[0], y: args[1] as number};
      newValueOrOptions = args[2] as never;
    } else {
      start = asPlainPoint(args[0] as PointLike);
      newValueOrOptions = args[1] as never;
    }
    let options: FloodFillOptions<V> = {};
    if (typeof newValueOrOptions === 'object' && (['withDiagonals', 'newValue', 'newValueForCell', 'floodableValues', 'isFloodable'].some((v) => v in (newValueOrOptions as object)))) {
      options = newValueOrOptions;
    } else if (newValueOrOptions !== undefined) {
      options.newValue = newValueOrOptions;
    }
    const newValueForCell: CellValueMapper<V> = options.newValueForCell || (() => options.newValue);
    let isFloodable: CellPredicate<V>;
    if (options.isFloodable != null) {
      isFloodable = options.isFloodable;
    } else if (options.floodableValues == null) {
      const startValue = this.get(start);
      isFloodable = ({value}) => value === startValue;
    } else if (Array.isArray(options.floodableValues)) {
      const floodableValues: V[] = options.floodableValues;
      isFloodable = ({value}) => floodableValues.includes(value);
    } else {
      const floodableValue: V = options.floodableValues;
      isFloodable = ({value}) => floodableValue === value;
    }

    let cell: GridCell<V> | undefined = {position: start, value: this.get(start)};
    if (!isFloodable(cell)) {
      return [];
    }

    const stack: GridCell<V>[] = [];
    const cells: GridCell<V>[] = [];
    while (cell != null) {
      const fillValue = newValueForCell(cell);
      if (fillValue !== undefined) {
        this.set(cell.position, fillValue);
      }
      cells.push(cell);

      for (const adjacentCell of this.adjacentFrom(cell.position, {withDiagonals: true})) {
        if (isFloodable(adjacentCell)) {
          stack.push(adjacentCell);
        }
      }
      cell = stack.pop();
    }
    return cells;
  }

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
    const directions = options.directions != null ? options.directions : getDirections('cardinal', options);

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
    for (const y in this.data) {
      for (const x in this.data[y]) {
        yield { position: {x: Number(x), y: Number(y)}, value: this.data[y][x] };
      }
    }
  }
  * row(pointOrY: PointLike | number): Generator<GridCell<V>> {
    const { y } = asPlainPoint(pointOrY);
    for (const x in this.data[y]) {
      yield { position: {x: Number(x), y: Number(y)}, value: this.data[y][x] };
    }
  }

  * column(pointOrX: PointLike | number): Generator<GridCell<V>> {
    const { x } = asPlainPoint(pointOrX);
    for (const y in this.data) {
      yield { position: {x: Number(x), y: Number(y)}, value: this.data[y][x] };
    }
  }

}
