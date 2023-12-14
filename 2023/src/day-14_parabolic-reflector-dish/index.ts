import { splitLines, sum } from '@util';
import { ArrayGrid, Grid } from '@util/grid';
import { filter, map, pipe, reduce } from 'iter-ops';

// region Types and Globals

// endregion

export function solvePart1(input: string): number {
  const grid = ArrayGrid.fromInput(input);
  tiltToNorth(grid);
  return pipe(
    grid.cells(),
    filter(({value}) => value === 'O'),
    map(({position: {y}}) => grid.height - y),
    reduce(sum),
  ).first!;
}

export function solvePart2(input: string): number {
  const lines = splitLines(input);
  // TODO Implement solution
  return Number.NaN;
}

// region Shared Code
function tiltToNorth(grid: Grid<string>) {
  for (let y = 1; y < grid.height; y++) {
    for (const {position: {x: rockX}, value} of grid.row(y)) {
      if (value !== 'O') {
        continue;
      }
      let rockY = y;
      while (rockY > 0 && grid.get(rockX, rockY - 1) === '.') {
        rockY--;
      }
      grid.set(rockX, y, '.');
      grid.set(rockX, rockY, 'O');
    }
  }
}
// endregion
