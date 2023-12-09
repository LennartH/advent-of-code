import { splitLines } from '@util';

export function solvePart1(input: string): number {
  const valueHistories = splitLines(input).map((l) => l.split(/\s+/).map(Number));
  return valueHistories.map(predictNextValue).reduce((s, v) => s + v, 0);
}

export function solvePart2(input: string): number {
  const valueHistories = splitLines(input).map((l) => l.split(/\s+/).map(Number));
  return valueHistories.map(predictPreviousValue).reduce((s, v) => s + v, 0);
}

// region Shared Code
function predictNextValue(sequence: number[]): number {
  const nextSequence = getNextSequence(sequence);
  if (!nextSequence.some((v) => v !== nextSequence[0])) {
    // All values are equal
    return sequence.at(-1)! + nextSequence[0];
  } else {
    return sequence.at(-1)! + predictNextValue(nextSequence)
  }
}

function predictPreviousValue(sequence: number[]): number {
  const nextSequence = getNextSequence(sequence);
  if (!nextSequence.some((v) => v !== nextSequence[0])) {
    // All values are equal
    return sequence[0] - nextSequence[0];
  } else {
    return sequence[0] - predictPreviousValue(nextSequence)
  }
}

function getNextSequence(sequence: number[]): number[] {
  const nextSequence: number[] = [];
  for (let i = 1; i < sequence.length; i++) {
    const delta = sequence[i] - sequence[i - 1];
    nextSequence.push(delta);
  }
  return nextSequence;
}
// endregion
