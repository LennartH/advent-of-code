import { groupBy, PlainPoint, splitLines } from '@util';
import { ArrayGrid, Grid } from '@util/grid';

// region Types and Globals
interface SchematicSymbol {
  id: string;
  position: PlainPoint;
}
// endregion

export function solvePart1(input: string): number {
  const schematic = new ArrayGrid(splitLines(input).map((l) => l.split('')));
  const symbols = findSymbols(schematic);
  return symbols.flatMap((s) => collectAdjacentNumbers(schematic, s))
                .reduce((s, v) => s + v, 0);
}

export function solvePart2(input: string): number {
  const schematic = new ArrayGrid(splitLines(input).map((l) => l.split('')));
  const gears = findSymbols(schematic).filter(({id}) => id === '*');
  return gears.map((s) => collectAdjacentNumbers(schematic, s))
    .filter((n) => n.length === 2)
    .map(([a, b]) => a * b)
    .reduce((s, v) => s + v, 0);
}

// region Shared Code
function findSymbols(schematic: Grid<string>): SchematicSymbol[] {
  const symbols: SchematicSymbol[] = [];
  for (let x = 0; x < schematic.width; x++) {
    for (let y = 0; y < schematic.height; y++) {
      const value = schematic.get(x, y);
      if (isSchematicSymbol(value)) {
        symbols.push({id: value, position: {x, y}});
      }
    }
  }
  return symbols;
}

function collectAdjacentNumbers(schematic: Grid<string>, {position}: SchematicSymbol): number[] {
  const numbers: number[] = [];
  const hits = getNeighbours(schematic, position).filter((p) => isNumeric(schematic.get(p)));
  const hitsPerLine = groupBy(hits, 'y');
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

const directions = [
  {dx: 0, dy: -1}, // Up
  {dx: 1, dy: -1}, // Up Right
  {dx: 1, dy: 0}, // Right
  {dx: 1, dy: 1}, // Right Down
  {dx: 0, dy: 1}, // Down
  {dx: -1, dy: 1}, // Down Left
  {dx: -1, dy: 0}, // Left
  {dx: -1, dy: -1}, // Left Up
]
function getNeighbours(schematic: Grid<unknown>, {x ,y }: PlainPoint): PlainPoint[] {
  const neighbours: PlainPoint[] = [];
  for (const {dx, dy} of directions) {
    if (schematic.contains(x + dx, y + dy)) {
      neighbours.push({x: x + dx, y: y + dy});
    }
  }
  return neighbours;
}

function isSchematicSymbol(value: string): boolean {
  return value !== '.' && !isNumeric(value);
}

const numericValues = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0']
function isNumeric(value: string): boolean {
  return value !== '.' && numericValues.includes(value);
}
// endregion
