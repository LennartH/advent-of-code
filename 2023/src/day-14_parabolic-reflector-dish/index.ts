import { directionFromName, formatGrid, isVertical, StraightCardinalDirectionName, sum } from '@util';
import { ArrayGrid, Grid } from '@util/grid';
import { filter, map, pipe, reduce } from 'iter-ops';

export function solvePart1(input: string): number {
  const grid = ArrayGrid.fromInput(input);
  tiltTowards('N', grid);
  return pipe(
    grid.cells(),
    filter(({value}) => value === 'O'),
    map(({position: {y}}) => grid.height - y),
    reduce(sum),
  ).first!;
}

export function solvePart2(input: string): number {
  const grid = ArrayGrid.fromInput(input);
  const totalCycles = 1000000000;
  const sequence: StraightCardinalDirectionName[] = ['N', 'W', 'S', 'E'];
  const memory = new Map<string, number>();
  memory.set(formatGrid(grid), 0);
  let cycleCounter = 0;
  let foundLoop = false;
  while (cycleCounter < totalCycles) {
    sequence.forEach((d) => tiltTowards(d, grid));
    cycleCounter++;

    if (!foundLoop) {
      const gridString = formatGrid(grid);
      if (memory.has(gridString)) {
        const loopLength = cycleCounter - memory.get(gridString)!;
        const remainingCycles = totalCycles - cycleCounter;
        cycleCounter = totalCycles - (remainingCycles % loopLength);
        foundLoop = true;
      } else {
        memory.set(gridString, cycleCounter);
      }
    }
  }
  return pipe(
    grid.cells(),
    filter(({value}) => value === 'O'),
    map(({position: {y}}) => grid.height - y),
    reduce(sum),
  ).first!;
}

// region Shared Code
function tiltTowards(direction: StraightCardinalDirectionName, grid: Grid<string>) {
  const { deltaX, deltaY} = directionFromName(direction);
  if (isVertical(direction)) {
    for (
      let y = direction === 'N' ? 1 : grid.height - 2;
      direction === 'N' ? y < grid.height : y >= 0;
      y += -deltaY
    ) {
      for (const {position: {x: rockX}, value} of grid.row(y)) {
        if (value !== 'O') {
          continue;
        }
        let rockY = y;
        while ((direction === 'N' ? rockY > 0 : rockY < grid.height - 1) && grid.get(rockX, rockY + deltaY) === '.') {
          rockY += deltaY;
        }
        grid.set(rockX, y, '.');
        grid.set(rockX, rockY, 'O');
      }
    }
  } else {
    for (
      let x = direction === 'W' ? 1 : grid.width - 2;
      direction === 'W' ? x < grid.width : x >= 0;
      x += -deltaX
    ) {
      for (const {position: {y: rockY}, value} of grid.column(x)) {
        if (value !== 'O') {
          continue;
        }
        let rockX = x;
        while ((direction === 'W' ? rockX > 0 : rockX < grid.width - 1) && grid.get(rockX + deltaX, rockY) === '.') {
          rockX += deltaX;
        }
        grid.set(x, rockY, '.');
        grid.set(rockX, rockY, 'O');
      }
    }
  }
}
// endregion
