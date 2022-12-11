import * as fs from 'fs';

interface Movement {
  deltaX: number;
  deltaY: number;
}

interface Point {
  x: number;
  y: number;
}

class Rope {
  points: Point[];

  private visitedByTail: Set<string> = new Set<string>(['0,0']);

  constructor(length: number) {
    this.points = new Array(length).fill('').map(() => ({ x: 0, y: 0 }));
  }

  moveHead(by: Movement) {
    this.movePoint(this.points[0], by);
    for (let index = 1; index < this.points.length; index++) {
      const point = this.points[index];
      const predecessor = this.points[index - 1];
      const { adjacent, delta } = this.getPointsRelation(predecessor, point);
      if (!adjacent) {
        const successorMovement = {
          deltaX: Math.min(1, Math.max(delta.x, -1)),
          deltaY: Math.min(1, Math.max(delta.y, -1)),
        };
        this.movePoint(point, successorMovement);
        if (index === this.points.length - 1) {
          this.visitedByTail.add(`${point.x},${point.y}`);
        }
      }
    }
  }

  countPositionsVisitedByTail(): number {
    return this.visitedByTail.size;
  }

  private movePoint(point: Point, by: Movement) {
    point.x += by.deltaX;
    point.y += by.deltaY;
  }

  private getPointsRelation(point1: Point, point2: Point): { adjacent: boolean; delta: Point } {
    const delta = {
      x: point1.x - point2.x,
      y: point1.y - point2.y,
    };
    return {
      adjacent: Math.abs(delta.x) <= 1 && Math.abs(delta.y) <= 1,
      delta,
    };
  }
}

function parseMovements(lines: string[]): Movement[] {
  return lines.reduce((movements, line) => {
    const parts = line.split(' ');
    const direction = parts[0];
    const amount = Number(parts[1]);
    let deltaX = 0;
    let deltaY = 0;
    if (direction === 'U') {
      deltaY = 1;
    } else if (direction === 'R') {
      deltaX = 1;
    } else if (direction === 'D') {
      deltaY = -1;
    } else if (direction === 'L') {
      deltaX = -1;
    } else {
      throw new Error(`Invalid movement direction '${direction}'`);
    }
    for (let i = 0; i < amount; i++) {
      movements.push({ deltaX, deltaY });
    }
    return movements;
  }, [] as Movement[]);
}

function exampleSolution() {
  const linesPart1 = `
    R 4
    U 4
    L 3
    D 1
    R 4
    D 1
    L 5
    R 2
  `
    .trim()
    .split('\n')
    .map((l) => l.trim());
  const ropePart1 = new Rope(2);
  parseMovements(linesPart1).forEach((m) => ropePart1.moveHead(m));
  const part1Result = ropePart1.countPositionsVisitedByTail();

  const linesPart2 = `
    R 5
    U 8
    L 8
    D 3
    R 17
    D 10
    L 25
    U 20
  `
    .trim()
    .split('\n')
    .map((l) => l.trim());
  const ropePart2 = new Rope(10);
  parseMovements(linesPart2).forEach((m) => ropePart2.moveHead(m));
  const part2Result = ropePart2.countPositionsVisitedByTail();
  console.log(`Solution for example input: Part 1 ${part1Result} | Part 2 ${part2Result}`);
}

function part1Solution() {
  const lines = fs.readFileSync('./assets/day-9_rope-bridge.input.txt', 'utf-8').trim().split('\n');
  const rope = new Rope(2);
  parseMovements(lines).forEach((m) => rope.moveHead(m));
  const positionVisitedByTail = rope.countPositionsVisitedByTail();
  console.log(`Solution for Part 1: ${positionVisitedByTail}`);
}

function part2Solution() {
  const lines = fs.readFileSync('./assets/day-9_rope-bridge.input.txt', 'utf-8').trim().split('\n');
  const rope = new Rope(10);
  parseMovements(lines).forEach((m) => rope.moveHead(m));
  const positionVisitedByTail = rope.countPositionsVisitedByTail();
  console.log(`Solution for Part 2: ${positionVisitedByTail}`);
}

exampleSolution();
part1Solution();
part2Solution();
