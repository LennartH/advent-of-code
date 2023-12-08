import { splitLines, leastCommonMultiple } from '@util';

// region Types and Globals
interface Map {
  instructions: ('L' | 'R')[];
  network: Record<string, Record<'L' | 'R', string>>
}
// endregion

export function solvePart1(input: string): number {
  const map = parseMap(splitLines(input));
  return pathLength('AAA', map, (node) => node !== 'ZZZ');
}

export function solvePart2(input: string): number {
  const map = parseMap(splitLines(input));

  const nodes = Object.keys(map.network).filter((n) => n.endsWith('A'));
  const pathLengths = nodes.map((n) => pathLength(n, map, (node) => !node.endsWith('Z')));
  return leastCommonMultiple(pathLengths);
}

// region Shared Code
function parseMap(lines: string[]): Map {
  const instructions = lines[0].split('') as ('L' | 'R')[];
  const network = lines.splice(2).reduce((network, line) => {
    const matches = line.match(/[0-9A-Z]+/g);
    if (matches == null || matches.length < 3) {
      throw new Error(`Unable to parse line: ${line}`);
    }
    network[matches[0]] = {L: matches[1], R: matches[2]}
    return network;
  }, {} as Record<string, Record<'L' | 'R', string>>);
  return { instructions, network }
}

function pathLength(start: string, {instructions, network}: Map, predicate: (n: string) => boolean): number {
  let counter = 0;
  let instructionIndex = 0;
  let node = start;
  while (predicate(node)) {
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
// endregion
