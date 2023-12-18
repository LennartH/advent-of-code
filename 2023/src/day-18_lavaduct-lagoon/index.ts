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
    const nextPosition = translateBy(position, scaleBy(directionFromName(direction), steps));
    total += crossProduct(position, nextPosition);
    perimeter += steps;
    position = nextPosition;
  }
  // I have no idea why this works... Probably something about roughly half of the perimeter isn't considered
  // as part of the polygon when using the shoelace formula. But why (perimeter / 2) + 1 I don't know...
  // Answer: Special case of Pick's theorem (see https://www.reddit.com/r/adventofcode/comments/18l2tap/comment/kdv8imu/)
  const area = Math.abs(total / 2);
  return area + (perimeter / 2) + 1;
}
// endregion
