import { CardinalDirection2D, directionFromName, isHorizontal, oppositeOf, PlainPoint, sum, translateBy } from '@util';
import { ArrayGrid, Grid } from '@util/grid';

export function solvePart1(input: string): number {
  const grids = input.split(/\n\s*\n/).map(ArrayGrid.fromInput);
  return grids.map((g) => findFoldLineId(g, false)).reduce(sum);
}

export function solvePart2(input: string): number {
  const grids = input.split(/\n\s*\n/).map(ArrayGrid.fromInput);
  return grids.map((g) => findFoldLineId(g, true)).reduce(sum);
}

// region Shared Code
function findFoldLineId(grid: Grid<string>, fixSmudge: boolean): number {
  const direction = directionFromName('SE');
  let line = { x: 0, y: 0 };
  while (line.x < grid.width - 1 || line.y < grid.height - 1) {
    const next = translateBy(line, direction);
    if (line.x < grid.width - 1 && (columnsAreEqual(grid, line, next) || (fixSmudge && columnsAreOffByOne(grid, line, next)))) {
      if (foldLineIsValid(grid, line, directionFromName('E'), fixSmudge && !columnsAreOffByOne(grid, line, next))) {
        return line.x + 1;
      }
    }
    if (line.y < grid.height - 1 && (rowsAreEqual(grid, line, next) || (fixSmudge && rowsAreOffByOne(grid, line, next)))) {
      if (foldLineIsValid(grid, line, directionFromName('S'), fixSmudge && !rowsAreOffByOne(grid, line, next))) {
        return 100 * (line.y + 1);
      }
    }
    line = next;
  }
  return 0;
}

function foldLineIsValid(grid: Grid<string>, line: PlainPoint, direction: CardinalDirection2D, fixSmudge: boolean): boolean {
  let isValid = true;
  for (
    let before = translateBy(line, oppositeOf(direction)), after = translateBy(translateBy(line, direction), direction);
    isHorizontal(direction) ? before.x >= 0 && after.x < grid.width : before.y >= 0 && after.y < grid.height;
    before = translateBy(before, oppositeOf(direction)), after = translateBy(after, direction)
  ) {
    const linesAreEqual = isHorizontal(direction) ? columnsAreEqual(grid, before, after) : rowsAreEqual(grid, before, after);
    if (!linesAreEqual) {
      const linesAreOffByOne = isHorizontal(direction) ? columnsAreOffByOne(grid, before, after) : rowsAreOffByOne(grid, before, after);
      if (fixSmudge && linesAreOffByOne) {
        fixSmudge = false;
        continue;
      }
      if (!fixSmudge) {
        isValid = false;
        break;
      }
    }
  }
  return isValid && !fixSmudge;
}

function columnsAreOffByOne(grid: Grid<string>, line1: PlainPoint, line2: PlainPoint): boolean {
  return isOffByOne([...grid.columnValues(line1)].join(''), [...grid.columnValues(line2)].join(''));
}

function rowsAreOffByOne(grid: Grid<string>, line1: PlainPoint, line2: PlainPoint): boolean {
  return isOffByOne([...grid.rowValues(line1)].join(''), [...grid.rowValues(line2)].join(''));
}

function isOffByOne(a: string, b: string): boolean {
  let mismatchCount = 0;
  for (let i = 0; i < a.length; i++) {
    if (a[i] !== b[i]) {
      mismatchCount++;
    }
  }
  return mismatchCount === 1;
}

function columnsAreEqual(grid: Grid<string>, line1: PlainPoint, line2: PlainPoint): boolean {
  return [...grid.columnValues(line1)].join('') === [...grid.columnValues(line2)].join('');
}

function rowsAreEqual(grid: Grid<string>, line1: PlainPoint, line2: PlainPoint): boolean {
  return [...grid.rowValues(line1)].join('') === [...grid.rowValues(line2)].join('');
}
// endregion
