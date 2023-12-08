import { splitLines } from '@util';

// region Types and Globals
interface Map {
  instructions: ('L' | 'R')[];
  network: Record<string, Record<'L' | 'R', string>>
}
// endregion

export function solvePart1(input: string): number {
  const {instructions, network} = parseMap(splitLines(input));

  let counter = 0;
  let instructionIndex = 0;
  let node = 'AAA';
  while (node !== 'ZZZ') {
    const instruction = instructions[instructionIndex];
    node = network[node][instruction];
    instructionIndex++;
    if (instructionIndex >= instructions.length) {
      instructionIndex = 0;
    }
    counter++;
  }

  return counter;
}

export function solvePart2(input: string): number {
  const lines = splitLines(input);
  // TODO Implement solution
  return Number.NaN;
}

// region Shared Code
function parseMap(lines: string[]): Map {
  const instructions = lines[0].split('') as ('L' | 'R')[];
  const network = lines.splice(2).reduce((network, line) => {
    const matches = line.match(/[A-Z]+/g);
    if (matches == null || matches.length < 3) {
      throw new Error(`Unable to parse line: ${line}`);
    }
    network[matches[0]] = {L: matches[1], R: matches[2]}
    return network;
  }, {} as Record<string, Record<'L' | 'R', string>>);
  return { instructions, network }
}
// endregion
