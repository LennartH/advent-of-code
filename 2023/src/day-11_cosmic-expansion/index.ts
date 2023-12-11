import { allPairs, PlainPoint, splitLines } from '@util';
import { ArrayGrid, Grid } from '@util/grid';
import { map, pipe, reduce } from 'iter-ops';

// region Types and Globals

// endregion

export function solvePart1(input: string): number {
  const {image, galaxies} = imageWithExpansion(input);
  return pipe(
    allPairs(galaxies),
    map(([from, to]) => manhattanDistance(from, to)),
    reduce((s, v) => s + v, 0)
  ).first || Number.NaN;
}

export function solvePart2(input: string): number {
  const lines = splitLines(input);
  // TODO Implement solution
  return Number.NaN;
}

// region Shared Code
export function imageWithExpansion(input: string): {image: Grid<string>, galaxies: PlainPoint[]} {
  const rawImage = ArrayGrid.fromInput(input);
  const emptyRows: number[] = [];
  for (let y = 0; y < rawImage.height; y++) {
    let foundGalaxy = false;
    for (const {value} of rawImage.row(y)) {
      if (value !== '.') {
        foundGalaxy = true;
        break;
      }
    }
    if (!foundGalaxy) {
      emptyRows.push(y);
    }
  }
  const emptyColumns: number[] = [];
  for (let x = 0; x < rawImage.width; x++) {
    let foundGalaxy = false;
    for (const {value} of rawImage.column(x)) {
      if (value !== '.') {
        foundGalaxy = true;
        break;
      }
    }
    if (!foundGalaxy) {
      emptyColumns.push(x);
    }
  }
  const rawGalaxies: PlainPoint[] = [];
  for (const {position, value} of rawImage.cells()) {
    if (value !== '.') {
      rawGalaxies.push(position);
    }
  }

  const image = new ArrayGrid(
    rawImage.width + emptyColumns.length,
    rawImage.height + emptyRows.length,
    '.'
  );
  const galaxies: PlainPoint[] = [];
  for (const {x, y} of rawGalaxies) {
    const galaxy = {
      x: x + emptyColumns.filter((cx) => cx < x).length,
      y: y + emptyRows.filter((cy) => cy < y).length,
    }
    image.set(galaxy, '#');
    galaxies.push(galaxy);
  }
  return {image, galaxies};
}

function manhattanDistance(point1: PlainPoint, point2: PlainPoint): number {
  return Math.abs(point1.x - point2.x) + Math.abs(point1.y - point2.y);
}
// endregion
