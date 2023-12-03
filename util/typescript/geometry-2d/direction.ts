import { unique } from '../collection';

export interface CardinalDirection2D {
  readonly name: CardinalDirectionName;
  readonly deltaX: number;
  readonly deltaY: number;
}
export interface PlainDirection2D {
  readonly name: CardinalDirectionName;
  readonly deltaX: number;
  readonly deltaY: number;
}
export type Direction2D = CardinalDirection2D | PlainDirection2D;

const cardinalDirectionNames = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'] as const;
export type CardinalDirectionName = typeof cardinalDirectionNames[number];
export type StraightCardinalDirectionName = 'N' | 'E' | 'S' | 'W';
const plainDirectionNames = ['U', 'UR', 'R', 'DR', 'D', 'DL', 'L', 'UL'] as const
export type PlainDirectionName = typeof plainDirectionNames[number];
export type StraightPlainDirectionName = 'U' | 'R' | 'D' | 'L';

// region Factory Methods
interface DirectionsFactoryOptions {
  invertAxis?: AxesString | Axes;
  withDiagonals?: boolean;
}

export function getDirections(names: CardinalDirectionName[], invertAxis?: AxesString | Axes): CardinalDirection2D[]
export function getDirections(names: PlainDirectionName[], invertAxis?: AxesString | Axes): PlainDirection2D[]
export function getDirections(flavor: 'cardinal', options?: DirectionsFactoryOptions): CardinalDirection2D[]
export function getDirections(flavor: 'plain', options?: DirectionsFactoryOptions): PlainDirection2D[]
export function getDirections(namesOrFlavor: DirectionName[] | 'cardinal' | 'plain', invertAxisOrOptions?: AxesString | Axes | DirectionsFactoryOptions): PlainDirection2D[] {
  let names: readonly DirectionName[];
  let invertAxis: undefined | AxesString | Axes = undefined;
  if (typeof namesOrFlavor === 'string') {
    names = namesOrFlavor === 'cardinal' ? cardinalDirectionNames : plainDirectionNames;
    const options = invertAxisOrOptions as DirectionsFactoryOptions;
    if (!options?.withDiagonals) {
      names = names.filter(isStraight);
    }
    invertAxis = options?.invertAxis;
  } else {
    names = namesOrFlavor;
    invertAxis = invertAxisOrOptions as (undefined | AxesString | Axes);
  }
  return names.map((n) => directionFromName(n as never, invertAxis));
}

export function directionFromName(name: CardinalDirectionName, invertAxis?: AxesString | Axes): CardinalDirection2D
export function directionFromName(name: PlainDirectionName, invertAxis?: AxesString | Axes): PlainDirection2D
export function directionFromName(name: DirectionName, invertAxis?: AxesString | Axes): Direction2D {
  let deltaX = 0;
  let deltaY = 0;
  for (const part of splitDirectionName(name)) {
    if (isHorizontal(part)) {
      deltaX = directionDelta[part];
    } else {
      deltaY = directionDelta[part];
    }
  }
  if (invertAxis != null) {
    for (const part of normalizeAxes(invertAxis)) {
      if (part === 'x') {
        deltaX *= -1;
      } else if (part === 'y') {
        deltaY *= -1;
      }
    }
  }
  return {name: name as never, deltaX, deltaY};
}

export function oppositeOf(direction: Direction2D): Direction2D
export function oppositeOf(direction: CardinalDirectionName, invertAxis?: AxesString | Axes): CardinalDirection2D
export function oppositeOf(direction: PlainDirectionName, invertAxis?: AxesString | Axes): PlainDirection2D
export function oppositeOf(direction: DirectionName | Direction2D, invertAxis?: AxesString | Axes): Direction2D {
  const name = typeof direction === 'string' ? direction : direction.name;
  const directionNames = isCardinalDirectionName(name) ? cardinalDirectionNames : plainDirectionNames;
  const directionNamesLength = directionNames.length;
  const oppositeOffset = directionNamesLength / 2;
  const oppositeName = directionNames[(directionNames.indexOf(name as never) + oppositeOffset) % directionNamesLength] as never;
  if (typeof direction === 'string') {
    return directionFromName(oppositeName, invertAxis);
  } else {
    return {name: oppositeName, deltaX: -1 * direction.deltaX, deltaY: -1 * direction.deltaY };
  }
}
// endregion

// region Orientation
export function isDiagonal(direction: DirectionName | Direction2D): boolean {
  return !isStraight(direction);
}

export function isStraight(direction: DirectionName | Direction2D): boolean {
  if (typeof direction === 'string') {
    return straightDirections.includes(direction);
  } else {
    return direction.deltaX === 0 || direction.deltaY === 0;
  }
}

export function isHorizontal(direction: DirectionName | Direction2D): boolean {
  if (typeof direction === 'string') {
    return horizontalDirections.includes(direction);
  } else {
    return direction.deltaY === 0;
  }
}

export function isVertical(direction: DirectionName | Direction2D): boolean {
  if (typeof direction === 'string') {
    return verticalDirections.includes(direction);
  } else {
    return direction.deltaX === 0;
  }
}
// endregion

// region Type Guards
export function isCardinalDirection(direction: Direction2D): direction is CardinalDirection2D {
  return isCardinalDirectionName(direction.name);
}

function isCardinalDirectionName(name: DirectionName): name is CardinalDirectionName {
  return cardinalDirectionNames.includes(name as never);
}

export function isPlainDirection(direction: Direction2D): direction is PlainDirection2D {
  return isPlainDirectionName(direction.name);
}

function isPlainDirectionName(name: DirectionName): name is PlainDirectionName {
  return plainDirectionNames.includes(name as never);
}
// endregion

// region Local Utilities
type DirectionName = CardinalDirectionName | PlainDirectionName;
type StraightDirectionName = StraightCardinalDirectionName | StraightPlainDirectionName;

type AxesString = 'x' | 'y' | 'xy' | 'yx';
type Axes = ('x' | 'y')[];
const horizontalDirections: readonly string[] = ['E', 'R', 'W', 'L'];
const verticalDirections: readonly string[] = ['N', 'U', 'S', 'D'];
const straightDirections: readonly string[] = [...horizontalDirections, ...verticalDirections]

const directionDelta: Record<StraightDirectionName, number> = {
  N: -1,   U: -1,
  E:  1,   R:  1,
  S:  1,   D:  1,
  W: -1,   L: -1,
};

function splitDirectionName(name: DirectionName): StraightDirectionName[] {
  return name.split('') as StraightDirectionName[];
}

function normalizeAxes(axes: AxesString | Axes): ('x' | 'y')[] {
  return typeof axes === 'string' ? axes.split('') as ('x' | 'y')[] : unique(axes);
}
// endregion
