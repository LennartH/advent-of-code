import { getDirections, groupBy, PlainPoint } from '@util';
import { ArrayGrid, Grid } from '@util/grid';
import { aggregate, filter, map, pipe, spread } from 'iter-ops';

// region Types and Globals
interface SchematicSymbol {
  value: string;
  position: PlainPoint;
}

const directions = getDirections('cardinal', {withDiagonals: true});
// endregion

export function solvePart1(input: string): number {
  const schematic = ArrayGrid.fromInput(input);
  const symbols = findSymbols(schematic);
  return symbols.flatMap((s) => collectAdjacentNumbers(schematic, s))
                .reduce((s, v) => s + v, 0);
}

export function solvePart2(input: string): number {
  const schematic = ArrayGrid.fromInput(input);
  const gears = findSymbols(schematic).filter(({value}) => value === '*');
  return gears.map((s) => collectAdjacentNumbers(schematic, s))
    .filter((n) => n.length === 2)
    .map(([a, b]) => a * b)
    .reduce((s, v) => s + v, 0);
}

// region Shared Code
function findSymbols(schematic: Grid<string>): SchematicSymbol[] {
  return [...pipe(
    schematic.cells(),
    filter(({value}) => isSchematicSymbol(value)),
  )];
}

function collectAdjacentNumbers(schematic: Grid<string>, {position}: SchematicSymbol): number[] {
  const numbers: number[] = [];
  const hitsPerLine = pipe(
    schematic.adjacentFrom(position, { withDiagonals: true }),
    filter(({value}) => isNumeric(value)),
    map(({position}) => position),
    aggregate((hits) => groupBy(hits, 'y')),
  ).first!;
  for (const y of Object.keys(hitsPerLine).map(Number)) {
    numbers.push(...collectHitLineNumbers(schematic, y, hitsPerLine[y]));
  }
  return numbers;
}

function collectHitLineNumbers(schematic: Grid<string>, lineY: number, hits: PlainPoint[]): number[] {
  const numbers: number[] = [];
  let containsHit = false;
  let digits: string[] = [];
  for (let x = 0; x < schematic.width; x++) {
    const cellValue = schematic.get(x, lineY);
    if (isNumeric(cellValue)) {
      digits.push(cellValue);
      containsHit ||= hits.some(({ x: hitX, y: hitY }) => x === hitX && lineY === hitY);
    } else {
      if (containsHit) {
        numbers.push(Number(digits.join('')));
      }
      digits = [];
      containsHit = false;
    }
  }
  return numbers;
}

function isSchematicSymbol(value: string): boolean {
  return value !== '.' && !isNumeric(value);
}

const numericValues = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0']
function isNumeric(value: string): boolean {
  return value !== '.' && numericValues.includes(value);
}
// endregion
