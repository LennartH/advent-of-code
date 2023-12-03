import { Grid, SparseArrayGrid } from '@util/grid';
import {
  directionFromName,
  formatGrid,
  getDirections,
  oppositeOf,
  PlainRect,
  Point2D,
  Rect2D,
  StraightCardinalDirectionName
} from '@util';

export enum CellType {
  Floor = '.',
  Wall = '#',
}

export enum Rotation {
  Clockwise = 'R',
  Counterclockwise = 'L',
}

export interface TreasureMap {
  start: {x: number, y: number};
  grid: Grid<CellType>;
  instructions: (number | Rotation)[];
}

export interface FaceDefinition extends PlainRect {
  id: string;
  neighbours: Partial<Record<StraightCardinalDirectionName, string>>;
}

export function parseTreasureMap(input: string): TreasureMap {
  const [encodedGrid, encodedInstructions] = input.split('\n\n');

  const gridLines = encodedGrid.split('\n');
  let start: TreasureMap['start'] = null as never;
  const grid = new SparseArrayGrid<CellType>(gridLines.reduce((w, l) => l.length > w ? l.length : w, 0), gridLines.length);
  for (let y = 0; y < grid.height; y++) {
    const line = gridLines[y];
    for (let x = 0; x < grid.width; x++) {
      const cell = line[x] as (' ' | CellType);
      if (cell === ' ') {
        continue;
      }
      if (start == null) {
        start = {x, y};
      }
      grid.set(x, y, cell);
    }
  }

  const instructions: TreasureMap['instructions'] = [];
  let distance = '';
  for (let i = 0; i < encodedInstructions.length; i++) {
    const symbol = encodedInstructions[i];
    if (symbol === Rotation.Clockwise || symbol === Rotation.Counterclockwise) {
      instructions.push(Number(distance), symbol);
      distance = '';
    } else {
      distance += symbol;
    }
  }
  instructions.push(Number(distance));

  return { start, grid, instructions }
}

const directions = getDirections('cardinal');

export function followInstructions(map: TreasureMap, faceDefinitions?: FaceDefinition[]): number {
  const { grid, instructions } = map;
  const cubeFaces = createCubeFaces(faceDefinitions)

  let directionIndex = 0;
  let direction = directions[directionIndex];
  let position = new Point2D(map.start);

  const walkedPath = new SparseArrayGrid<string>(grid.width, grid.height);
  walkedPath.set(position, ['>', 'v', '<', '^'][directionIndex])

  for (let i = 0; i < instructions.length; i++) {
    const instruction = instructions[i];
    if (instruction === Rotation.Clockwise || instruction === Rotation.Counterclockwise) {
      directionIndex += instruction === Rotation.Clockwise ? 1 : -1;
      directionIndex %= directions.length;
      if (directionIndex < 0) {
        directionIndex += directions.length;
      }
      direction = directions[directionIndex];
      walkedPath.set(position, ['>', 'v', '<', '^'][directionIndex])

      // console.log(`Instruction ${i+1}/${instructions.length}: Turning ${instruction}`)
      // console.log(formatGrid(grid, {
      //   valueFormatter: (v, x, y) => walkedPath.get(x, y) || v || ' ',
      // }))
      // console.log()

    } else {
      for (let step = 0; step < instruction; step++) {
        const nextPosition = position.clone().translateBy(direction);
        let nextCell = grid.get(nextPosition);
        if (nextCell === undefined) {
          if (directionIndex === 0) { // Right
            nextPosition.x = 0;
          } else if (directionIndex === 1) { // Down
            nextPosition.y = 0;
          } else if (directionIndex === 2) { // Left
            nextPosition.x = grid.width - 1;
          } else { // Up
            nextPosition.y = grid.height - 1;
          }
          nextCell = grid.get(nextPosition);
          while (nextCell === undefined) {
            nextPosition.translateBy(direction);
            nextCell = grid.get(nextPosition);
          }
        }
        if (nextCell === CellType.Wall) {
          break;
        }
        position = nextPosition;
        walkedPath.set(position, ['>', 'v', '<', '^'][directionIndex])

        // console.log(`Instruction ${i+1}/${instructions.length}: Step ${step+1}/${instruction}`)
        // console.log(formatGrid(grid, {
        //   valueFormatter: (v, x, y) => walkedPath.get(x, y) || v || ' ',
        // }))
        // console.log()

      }
    }
  }

  walkedPath.set(map.start, 'S');
  walkedPath.set(position, 'F');
  console.log(formatGrid(grid, {
    valueFormatter: (v, x, y) => walkedPath.get(x, y) || v || ' ',
  }))

  return ((position.y + 1) * 1000) + ((position.x + 1) * 4) + directionIndex;
}

function getNeighbour(position: Point2D, directionIndex: number, grid: Grid<CellType>, cubeFaces?: CubeFace[]): [Point2D, CellType, number] {
  const direction = directions[directionIndex];
  let nextPosition = position.clone().translateBy(direction);
  let nextCell = grid.get(nextPosition);
  if (nextCell === undefined) {
    if (!cubeFaces) {
      if (directionIndex === 0) { // Right
        nextPosition.x = 0;
      } else if (directionIndex === 1) { // Down
        nextPosition.y = 0;
      } else if (directionIndex === 2) { // Left
        nextPosition.x = grid.width - 1;
      } else { // Up
        nextPosition.y = grid.height - 1;
      }
      nextCell = grid.get(nextPosition);
      while (nextCell === undefined) {
        nextPosition.translateBy(direction);
        nextCell = grid.get(nextPosition);
      }
    } else {
      const currentFace = cubeFaces.find((f) => f.rect.containsPoint(position))!;
      ([ nextPosition, directionIndex ] = currentFace.moveToFace(position.clone(), directionIndex));
      nextCell = grid.get(nextPosition);
    }
  }
  return [nextPosition, nextCell, directionIndex];
}

class CubeFace {
  id: string;
  rect: Rect2D;
  neighbours: [StraightCardinalDirectionName, CubeFace][];

  constructor(id: string, rect: PlainRect) {
    this.id = id;
    this.rect = new Rect2D(rect);
    this.neighbours = [];
  }

  moveToFace(position: Point2D, directionIndex: number): [Point2D, number] {
    const [, face] = this.neighbours.find(([, { id }]) => id === targetFace) || [];
    if (!face) {
      throw new Error(`Neighbour with id ${targetFace} not found`);
    }
    const [directionToThis] = face.neighbours.find(([, { id }]) => id === this.id) || [];
    if (!directionToThis) {
      throw new Error(`Neighbour does not have the current face (id ${this.id}) as neighbour`);
    }
    // let directionToTarget = Direction2D.for(directionToThis as never).opposite().cardinal;
    let directionToTarget = oppositeOf(directionFromName(directionToThis)).name;

    // TODO Transform position
    // - Global to local face position
    // - Local face position to target face position
    // - Target face position to global position

    return [position, directionToTarget];
  }
}

function createCubeFaces(faceDefinitions?: FaceDefinition[]): CubeFace[] | undefined {
  if (faceDefinitions == null) {
    return undefined;
  }
  const cubeFaces = faceDefinitions.map((f) => new CubeFace(f.id, f));
  for (const { id, neighbours } of faceDefinitions) {
    const face = cubeFaces.find((f) => f.id === id)!;
    for (const [direction, neighbourId] of Object.entries(neighbours)) {
      const neighbour = cubeFaces.find((f) => f.id === neighbourId)!;
      face.neighbours.push([direction as StraightCardinalDirectionName, neighbour]);
    }
  }
  return cubeFaces;
}
