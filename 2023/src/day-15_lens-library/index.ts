import { splitLines, sum } from '@util';

// region Types and Globals

// endregion

export function solvePart1(input: string): number {
  const instructions = splitLines(input)[0].split(',');
  return instructions.map(hashCode).reduce(sum);
}

export function solvePart2(input: string): number {
  const lines = splitLines(input);
  // TODO Implement solution
  return Number.NaN;
}

// region Shared Code
function hashCode(text: string): number {
  let hash = 0;
  for (let i = 0; i < text.length; i++) {
    hash += text.charCodeAt(i);
    hash *= 17;
    hash = hash % 256;
  }
  return hash;
}
// endregion
