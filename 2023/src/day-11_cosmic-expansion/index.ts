import { allPairs, PlainPoint } from '@util';
import { ArrayGrid } from '@util/grid';
import { map, pipe, reduce } from 'iter-ops';

export function solvePart1(input: string): number {
  return solveWithExpansionFactor(input, 2);
}

export function solvePart2(input: string): number {
  return solveWithExpansionFactor(input, 1000000);
}

export function solveWithExpansionFactor(input: string, expansionFactor: number): number {
  const galaxies = galaxiesAfterExpansion(input, expansionFactor);
  return pipe(
    allPairs(galaxies),
    map(([from, to]) => manhattanDistance(from, to)),
    reduce((s, v) => s + v, 0)
  ).first || Number.NaN;
}

// region Shared Code
function galaxiesAfterExpansion(input: string, expansionFactor: number): PlainPoint[] {
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

  const galaxies: PlainPoint[] = [];
  for (const {x, y} of rawGalaxies) {
    const galaxy = {
      x: x + (emptyColumns.filter((cx) => cx < x).length * (expansionFactor - 1)),
      y: y + (emptyRows.filter((cy) => cy < y).length * (expansionFactor - 1)),
    }
    galaxies.push(galaxy);
  }
  return galaxies;
}

function manhattanDistance(point1: PlainPoint, point2: PlainPoint): number {
  return Math.abs(point1.x - point2.x) + Math.abs(point1.y - point2.y);
}
// endregion
