import { crossProduct, directionFromName, scaleBy, splitLines, StraightPlainDirectionName, translateBy } from '@util';

// region Types and Globals
interface Instruction {
  direction: StraightPlainDirectionName;
  steps: number;
}
// endregion

export function solvePart1(input: string): number {
  const instructions: Instruction[] = splitLines(input).map((line) => {
    const [direction, steps] = line.split(' ');
    return {
      direction: direction as StraightPlainDirectionName,
      steps: Number(steps),
    };
  });
  return polygonArea(instructions);
}

export function solvePart2(input: string): number {
  const directions: StraightPlainDirectionName[] = ['R', 'D', 'L', 'U'];
  const instructions: Instruction[] = splitLines(input).map((line) => {
    const color = line.split(' ').at(-1)!;
    const directionIndex = Number(color.at(-2));
    const stepsHex = color.slice(2, -2);
    return {
      direction: directions[directionIndex],
      steps: Number.parseInt(stepsHex, 16),
    };
  });
  return polygonArea(instructions);
}

// region Shared Code
function polygonArea(instructions: Instruction[]): number {
  let total = 0;
  let perimeter = 0;
  let position = {x: 0, y: 0};
  for (const {direction, steps} of instructions) {
    const nextPosition = translateBy(position, scaleBy(directionFromName(direction, 'y'), steps));
    const cross = crossProduct(position, nextPosition);
    total += cross;
    perimeter += steps;
    position = nextPosition;
  }
  const area = Math.abs(total / 2);
  // I have no idea why this works... Probably something about roughly half of the perimeter isn't considered
  // as part of the polygon when using the shoelace formula. But why +2 I don't know... Works for me at least.
  return area + ((perimeter + 2) / 2);
}
// endregion
