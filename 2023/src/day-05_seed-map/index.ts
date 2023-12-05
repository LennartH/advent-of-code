import { splitLines } from '@util';

// region Types and Globals
class ResourceMap {

  constructor(
    public readonly sourceName: string,
    public readonly destinationName: string,
    readonly ranges: MappingRange[],
  ) {}

  toDestination(sourceNumber: number): number {
    for (const range of this.ranges) {
      if (range.includes(sourceNumber)) {
        return range.toDestination(sourceNumber);
      }
    }
    return sourceNumber;
  }
}

class MappingRange {

  readonly sourceToDestinationDelta: number;

  constructor(
    readonly sourceStart: number,
    readonly destinationStart: number,
    readonly length: number
  ) {
    this.sourceToDestinationDelta = destinationStart - sourceStart;
  }

  includes(sourceNumber: number): boolean {
    return sourceNumber >= this.sourceStart && sourceNumber < this.sourceStart + this.length;
  }

  toDestination(sourceNumber: number): number {
    return sourceNumber + this.sourceToDestinationDelta;
  }
}
// endregion

export function solvePart1(input: string): number {
  const {seeds, mappings} = parseInput(input);
  return seeds
    .map((s) => mappings.reduce((v, m) => m.toDestination(v), s))
    .reduce((min, v) => Math.min(min, v));
}

export function solvePart2(input: string): number {
  const lines = splitLines(input);
  // TODO Implement solution
  return Number.NaN;
}

// region Shared Code
function parseInput(input: string): {seeds: number[], mappings: ResourceMap[]} {
  const lines = splitLines(input);
  const seeds = lines[0].split(':')[1].trim().split(/\s+/).map(Number);
  const mappings = lines.slice(2).join('\n').split('\n\n')
    .map((text) => {
      const lines = text.split('\n');
      const {source, destination} = lines[0].match(/(?<source>[a-z]+)-to-(?<destination>[a-z]+)/)!.groups!;
      const ranges = lines.slice(1).map((line) => {
        const [destinationStart, sourceStart, length] = line.split(/\s+/).map(Number);
        return new MappingRange(sourceStart, destinationStart, length);
      });
      return new ResourceMap(source, destination, ranges);
    })
  return {seeds, mappings};
}
// endregion
