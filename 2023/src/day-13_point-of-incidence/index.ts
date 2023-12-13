import { formatGrid, splitLines, sum } from '@util';
import { ArrayGrid, Grid } from '@util/grid';
import { pipe } from 'iter-ops';

// region Types and Globals

// endregion

export function solvePart1(input: string): number {
  const grids = input.split(/\n\s*\n/).map((p) => ArrayGrid.fromInput(p));
  return grids.map(findFoldLineId).reduce(sum);
}

export function solvePart2(input: string): number {
  const lines = splitLines(input);
  // TODO Implement solution
  return Number.NaN;
}

// region Shared Code
function findFoldLineId(grid: Grid<string>): number {
  for (let x = 0; x < grid.width - 1; x++) {
    const columnA = [...grid.column(x)].map(({value}) => value).join('');
    const columnB = [...grid.column(x + 1)].map(({value}) => value).join('');
    if (columnA === columnB) {
      let foundFoldLineIndex = true;
      for (let x1 = x - 1, x2 = x + 2; x1 >= 0 && x2 < grid.width; x1--, x2++) {
        const columnA = [...grid.column(x1)].map(({value}) => value).join('');
        const columnB = [...grid.column(x2)].map(({value}) => value).join('');
        if (columnA !== columnB) {
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
    const rowA = [...grid.row(y)].map(({value}) => value).join('');
    const rowB = [...grid.row(y + 1)].map(({value}) => value).join('');
    if (rowA === rowB) {
      let foundFoldLineIndex = true;
      for (let y1 = y - 1, y2 = y + 2; y1 >= 0 && y2 < grid.height; y1--, y2++) {
        const rowA = [...grid.row(y1)].map(({value}) => value).join('');
        const rowB = [...grid.row(y2)].map(({value}) => value).join('');
        if (rowA !== rowB) {
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
// endregion
