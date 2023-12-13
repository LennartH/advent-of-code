import { formatGrid, sum } from '@util';
import { ArrayGrid, Grid } from '@util/grid';

export function solvePart1(input: string): number {
  const grids = input.split(/\n\s*\n/).map((p) => ArrayGrid.fromInput(p));
  return grids.map(findFoldLineId).reduce(sum);
}

export function solvePart2(input: string): number {
  const grids = input.split(/\n\s*\n/).map((p) => ArrayGrid.fromInput(p));
  return grids.map(findFoldLineIdWhenFixingSmudge).reduce(sum);
}

// region Shared Code
function findFoldLineId(grid: Grid<string>): number {
  for (let x = 0; x < grid.width - 1; x++) {
    if (columnsAreEqual(grid, x, x + 1)) {
      let foundFoldLineIndex = true;
      for (let x1 = x - 1, x2 = x + 2; x1 >= 0 && x2 < grid.width; x1--, x2++) {
        if (!columnsAreEqual(grid, x1, x2)) {
          foundFoldLineIndex = false;
          break;
        }
      }
      if (foundFoldLineIndex) {
        return x + 1;
      }
    }
  }

  for (let y = 0; y < grid.height - 1; y++) {
    if (rowsAreEqual(grid, y, y + 1)) {
      let foundFoldLineIndex = true;
      for (let y1 = y - 1, y2 = y + 2; y1 >= 0 && y2 < grid.height; y1--, y2++) {
        if (!rowsAreEqual(grid, y1, y2)) {
          foundFoldLineIndex = false;
          break;
        }
      }
      if (foundFoldLineIndex) {
        return 100 * (y + 1);
      }
    }
  }

  throw new Error(`Unable to find fold line for grid:\n${formatGrid(grid)}`)
}

function findFoldLineIdWhenFixingSmudge(grid: Grid<string>): number {
  for (let x = 0; x < grid.width - 1; x++) {
    const startingColumnsAreEqual = columnsAreEqual(grid, x, x + 1);
    const startingColumnsAreOffByOne = columnsAreOffByOne(grid, x, x+1);
    if (startingColumnsAreEqual || startingColumnsAreOffByOne) {
      let fixedSmudge = startingColumnsAreOffByOne;
      let foundFoldLineIndex = true;
      for (let x1 = x - 1, x2 = x + 2; x1 >= 0 && x2 < grid.width; x1--, x2++) {
        if (!columnsAreEqual(grid, x1, x2)) {
          if (!fixedSmudge && columnsAreOffByOne(grid, x1, x2)) {
            fixedSmudge = true;
            continue;
          }
          foundFoldLineIndex = false;
          break;
        }
      }
      if (foundFoldLineIndex && fixedSmudge) {
        return x + 1;
      }
    }
  }

  for (let y = 0; y < grid.height - 1; y++) {
    const startingRowsAreEqual = rowsAreEqual(grid, y, y + 1);
    const startingRowsAreOffByOne = rowsAreOffByOne(grid, y, y + 1);
    if (startingRowsAreEqual || startingRowsAreOffByOne) {
      let fixedSmudge = startingRowsAreOffByOne;
      let foundFoldLineIndex = true;
      for (let y1 = y - 1, y2 = y + 2; y1 >= 0 && y2 < grid.height; y1--, y2++) {
        if (!rowsAreEqual(grid, y1, y2)) {
          if (!fixedSmudge && rowsAreOffByOne(grid, y1, y2)) {
            fixedSmudge = true;
            continue;
          }
          foundFoldLineIndex = false;
          break;
        }
      }
      if (foundFoldLineIndex && fixedSmudge) {
        return 100 * (y + 1);
      }
    }
  }

  throw new Error(`Unable to find fold line for grid:\n${formatGrid(grid)}`)
}

function columnsAreOffByOne(grid: Grid<string>, x1: number, x2: number): boolean {
  const columnA = [...grid.column(x1)].map(({value}) => value).join('');
  const columnB = [...grid.column(x2)].map(({value}) => value).join('');
  let mismatchCount = 0;
  for (let i = 0; i < columnA.length; i++) {
    if (columnA[i] !== columnB[i]) {
      mismatchCount++;
    }
  }
  return mismatchCount === 1;
}

function rowsAreOffByOne(grid: Grid<string>, y1: number, y2: number): boolean {
  const rowA = [...grid.row(y1)].map(({value}) => value).join('');
  const rowB = [...grid.row(y2)].map(({value}) => value).join('');
  let mismatchCount = 0;
  for (let i = 0; i < rowA.length; i++) {
    if (rowA[i] !== rowB[i]) {
      mismatchCount++;
    }
  }
  return mismatchCount === 1;
}

function columnsAreEqual(grid: Grid<string>, x1: number, x2: number): boolean {
  const columnA = [...grid.column(x1)].map(({value}) => value).join('');
  const columnB = [...grid.column(x2)].map(({value}) => value).join('');
  return columnA === columnB;
}

function rowsAreEqual(grid: Grid<string>, y1: number, y2: number): boolean {
  const rowA = [...grid.row(y1)].map(({value}) => value).join('');
  const rowB = [...grid.row(y2)].map(({value}) => value).join('');
  return rowA === rowB;
}
// endregion
