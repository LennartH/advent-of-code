export enum DirectionNumerical {
  Top = 0,
  Right = 1,
  Bottom = 2,
  Left = 3,
}

export enum CardinalDirection {
  North = 'N',
  East = 'E',
  South = 'S',
  West = 'W',
}

export enum DirectionString {
  Top = 'T',
  Right = 'R',
  Bottom = 'B',
  Left = 'L',
}

export class Direction2D {

  static North = new Direction2D(0, -1);
  static East = new Direction2D(1, 0);
  static South = new Direction2D(0, 1);
  static West = new Direction2D(-1, 0);

  static values = [Direction2D.North, Direction2D.East, Direction2D.South, Direction2D.West] as const;

  static for(direction: DirectionNumerical | CardinalDirection | DirectionString): Direction2D {
    const result = Direction2D.values.find(
      (d) => d.numerical === direction || d.cardinal === direction || d.word === direction
    );
    if (!result) {
      throw new Error(`Unknown direction ${direction}`);
    }
    return result;
  }

  /* Implementation Members */

  readonly deltaX: number;
  readonly deltaY: number;

  readonly numerical: DirectionNumerical;
  readonly cardinal: CardinalDirection;
  readonly word: DirectionString;

  private constructor(deltaX: number, deltaY: number) {
    this.deltaX = deltaX;
    this.deltaY = deltaY;

    if (deltaY === 0) {
      if (deltaX > 0) {
        this.numerical = DirectionNumerical.Right;
        this.cardinal = CardinalDirection.East;
        this.word = DirectionString.Right;
      } else {
        this.numerical = DirectionNumerical.Left;
        this.cardinal = CardinalDirection.West;
        this.word = DirectionString.Left;
      }
    } else if (deltaY > 0) {
      this.numerical = DirectionNumerical.Bottom;
      this.cardinal = CardinalDirection.South;
      this.word = DirectionString.Bottom;
    } else {
      this.numerical = DirectionNumerical.Top;
      this.cardinal = CardinalDirection.North;
      this.word = DirectionString.Top;
    }
  }

  opposite(): Direction2D {
    let numerical = (this.numerical + 2) % Direction2D.values.length;
    if (numerical < 0) {
      numerical += Direction2D.values.length;
    }
    return Direction2D.for(numerical);
  }

  toString(format: 'cardinal' | 'string' | 'vector' = 'cardinal'): string {
    if (format === 'cardinal') {
      return this.cardinal;
    } else if (format === 'string') {
      return this.word;
    } else if (format === 'vector') {
      return `(${this.deltaX}, ${this.deltaY})`;
    } else {
      throw new Error(`Unknown format ${format}`);
    }
  }

}
