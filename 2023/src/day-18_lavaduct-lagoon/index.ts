import { ArrayGrid, directionFromName, formatGrid, splitLines, StraightPlainDirectionName, translateBy } from '@util';
import { count, pipe } from 'iter-ops';

// region Types and Globals
interface Instruction {
  direction: StraightPlainDirectionName;
  steps: number;
  color: string;
}
// endregion

export function solvePart1(input: string): number {
  const instructions: Instruction[] = splitLines(input).map((line) => {
    const [direction, steps, color] = line.split(' ');
    return {
      direction: direction as StraightPlainDirectionName,
      steps: Number(steps),
      color: color.slice(2, -1),
    };
  });
  const totalStepsByDirection = instructions.reduce((totals, instruction) => {
    if (totals[instruction.direction] == null) {
      totals[instruction.direction] = 0;
    }
    totals[instruction.direction] += instruction.steps;
    return totals;
  }, {} as Record<StraightPlainDirectionName, number>);
  const terrain = new ArrayGrid(totalStepsByDirection['R'] * 4, totalStepsByDirection['D'] * 4, '.');
  const start = {x: Math.floor(terrain.width / 2), y: Math.floor(terrain.height / 2)};
  let position = start;
  terrain.set(position, '#');
  for (const {direction, steps} of instructions) {
    for (let i = 0; i < steps; i++) {
      position = translateBy(position, directionFromName(direction));
      terrain.set(position, '#');
    }
  }
  terrain.floodFill(start.x + 1, start.y + 1, '#');
  return pipe(
    terrain.cellValues(),
    count((v) => v === '#'),
  ).first!;
}

export function solvePart2(input: string): number {
  const lines = splitLines(input);
  // TODO Implement solution
  return Number.NaN;
}

// region Shared Code

// endregion
