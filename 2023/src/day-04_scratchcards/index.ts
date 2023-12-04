import { splitLines } from '@util';

// region Types and Globals

// endregion

export function solvePart1(input: string): number {
  const lines = splitLines(input);
  return lines.map((card) => {
    const [winningNumbers, numbers] = card.split(': ')[1]
      .split(' | ').map((p) => p.trim().split(/\s+/))
      .map((l) => l.map((v) => Number(v.trim())));
    const matches = winningNumbers.filter((n) => numbers.includes(n)).length;
    return matches <= 1 ? matches : Math.pow(2, matches - 1);
  }).reduce((s, v) => s + v, 0);
}

export function solvePart2(input: string): number {
  const lines = splitLines(input);
  // TODO Implement solution
  return Number.NaN;
}

// region Shared Code

// endregion
