import { ArrayGrid, Grid } from './grid';

export function shuffle<T>(list: T[]): T[] {
  for (let i = list.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [list[i], list[j]] = [list[j], list[i]];
  }
  return list;
}

export function unique<T>(list: T[], predicate?: (a: T, b: T) => boolean): T[] {
  if (predicate != null) {
    return list.filter((a, i) => list.findIndex((b) => predicate(a, b)) === i);
  } else {
    return [...new Set(list)];
  }
}

// Only keys for properties that are strings or numbers
type AllowedKeyType = string | number;
type AllowedKeyOf<T> = keyof { [K in keyof T as T[K] extends AllowedKeyType ? K : never]: T[K]; };
export function groupBy<T, K extends AllowedKeyType>(list: T[], key: AllowedKeyOf<T> | ((e: T) => K)): Record<K, T[]> {
  const getKey = typeof key === 'function' ? key : (e: T) => e[key] as K;
  return list.reduce((groups, item) => {
    const _key = getKey(item);
    let group = groups[_key];
    if (group == null) {
      group = [];
      groups[_key] = group;
    }
    group.push(item);
    return groups;
  }, {} as Record<K, T[]>);
}

export function* allPermutations<T>(list: T[]): Generator<T[]> {
  const length = list.length;
  const c = new Array(length).fill(0);
  let i = 1, k, p;

  yield list.slice();
  while (i < length) {
    if (c[i] < i) {
      k = i % 2 && c[i];
      p = list[i];
      list[i] = list[k];
      list[k] = p;
      ++c[i];
      i = 1;
      yield list.slice();
    } else {
      c[i] = 0;
      ++i;
    }
  }
}

export function* allPairs<T>(list: T[]): Generator<[T, T]> {
  for (let i = 0; i < list.length; i++) {
    for (let j = i + 1; j < list.length; j++) {
      yield [list[i], list[j]];
    }
  }
}

export interface GridFormat<V> {
  valueFormatter?: (v: V, x: number, y: number) => string;

  rowPrefix?: string;
  rowSuffix?: string;
  rowSeparator?: string;

  columnPrefix?: string;
  columnSuffix?: string;
  columnSeparator?: string;

  outsideCorner?: string;
}

export function formatGrid<V>(grid: V[][] | Grid<V>, format?: GridFormat<V>): string {
  const _grid = Array.isArray(grid) ? new ArrayGrid(grid) : grid;
  if (_grid.height === 0) {
    return '';
  }

  format ||= {};
  const valueFormatter = format.valueFormatter || ((v) => `${v}`);
  const columnSeparator = format.columnSeparator || '';
  const { rowPrefix, rowSuffix, rowSeparator, columnPrefix, columnSuffix, outsideCorner } = format;

  const lines: string[] = [];
  for (let y = 0; y < _grid.height; y++) {
    const lineSymbols: string[] = [];
    for (let x = 0; x < _grid.width; x++) {
      lineSymbols.push(valueFormatter(_grid.get(x, y), x, y));
    }
    const line = lineSymbols.join(columnSeparator);
    lines.push(line);
    if (rowSeparator && y < _grid.height - 1) {
      lines.push(rowSeparator.repeat(Math.ceil(line.length / rowSeparator.length)).substring(0, line.length))
    }
  }

  const lineLength = lines[0].length;
  if (rowPrefix || rowSuffix) {
    for (let i = 0; i < lines.length; i++) {
      lines[i] = `${rowPrefix || ''}${lines[i]}${rowSuffix || ''}`;
    }
  }
  if (columnPrefix || columnSuffix) {
    let leftCorner = rowPrefix ? outsideCorner || rowPrefix || '' : '';
    if (rowPrefix && rowPrefix.length !== leftCorner.length) {
      leftCorner = leftCorner.repeat(Math.ceil(rowPrefix.length / leftCorner.length)).substring(0, rowPrefix.length);
    }
    let rightCorner = rowSuffix ? outsideCorner || rowSuffix || '' : '';
    if (rowSuffix && rowSuffix.length !== rightCorner.length) {
      rightCorner = rightCorner.repeat(Math.ceil(rowSuffix.length / rightCorner.length)).substring(0, rowSuffix.length);
    }
    if (columnPrefix) {
      const header = columnPrefix.repeat(Math.ceil(lineLength / columnPrefix.length)).substring(0, lineLength);
      lines.unshift(`${leftCorner}${header}${rightCorner}`);
    }
    if (columnSuffix) {
      const footer = columnSuffix.repeat(Math.ceil(lineLength / columnSuffix.length)).substring(0, lineLength);
      lines.push(`${leftCorner}${footer}${rightCorner}`);
    }
  }
  return lines.join('\n')
}
