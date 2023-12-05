import { splitLines } from '@util';

export function solvePart1(input: string): number {
  const {seeds, mappings} = parseInput(input);
  return seeds
    .map((s) => mappings.reduce((v, m) => m.toDestination(v), s))
    .reduce((min, v) => Math.min(min, v));
}

export function solvePart2(input: string): number {
  const {seeds, mappings} = parseInput(input);
  let minLocation = Number.MAX_SAFE_INTEGER;
  for (let i = 0; i < seeds.length; i += 2) {
    const seedEnd = seeds[i] + seeds[i + 1];
    for (let seed = seeds[i]; seed < seedEnd; seed++) {
      const seedMinLocation = mappings.reduce((v, m) => m.toDestination(v), seed);
      minLocation = Math.min(minLocation, seedMinLocation);
    }
    // FIXME Calculating location range-wise works for example, but not for real input
    // const seedRange = new ValueRange(seeds[i], seeds[i] + seeds[i + 1] - 1);
    // console.log(`Processing seed range ${seedRange}`)
    // console.group()
    // let resourceRanges: ValueRange[] = [seedRange];
    // for (const mapping of mappings) {
    //   console.log(`Mapping from ${mapping.sourceName} to ${mapping.destinationName} (${mapping.ranges.map((r) => r.toString()).join(' | ')})`)
    //   console.group()
    //   const mappedRanges = mapping.toDestinationRanges(resourceRanges);
    //   console.log(`${resourceRanges.join(', ')} -> ${mappedRanges.join(', ')}`);
    //   resourceRanges = mappedRanges;
    //   console.groupEnd()
    // }
    // const seedMinLocation = resourceRanges.map(({start}) => start).reduce((min, v) => Math.min(min, v));
    // console.log(`=> Min location for seed range ${seedRange} is ${seedMinLocation}`);
    // minLocation = Math.min(seedMinLocation, minLocation);
    // console.groupEnd()
    // console.log();
  }
  // console.log(`=> Min location for all seed ranges is ${minLocation}`);
  return minLocation;
}

// region Types and Globals
const infinity = 1000000000000; // For my puzzle anyway

class ResourceMap {

  readonly ranges: MappingRange[] = [];

  constructor(
    public readonly sourceName: string,
    public readonly destinationName: string,
    rangesText: string[],
  ) {
    this.ranges = rangesText.map((line) => {
      const [destinationStart, sourceStart, length] = line.split(/\s+/).map(Number);
      return new MappingRange(sourceStart, destinationStart, length);
    });
    this.ranges.sort(({start: a}, {start: b}) => a - b);

    if (this.ranges[0].start > 0) {
      this.ranges.unshift(new MappingRange(0, 0, this.ranges[0].start));
    }
    const lastRange = this.ranges.at(-1)!;
    this.ranges.push(new MappingRange(lastRange.end + 1, lastRange.end + 1, infinity - lastRange.end));

    for (let i = 0; i < this.ranges.length - 1; i++) {
      const range = this.ranges[i];
      const nextRange = this.ranges[i + 1];
      const gapLength = nextRange.start - range.end - 1;
      if (gapLength > 0) {
        const gapStart = range.end + 1;
        this.ranges.splice(i + 1, 0, new MappingRange(gapStart, gapStart, gapLength));
        i++;
      }
    }
  }

  toDestination(sourceNumber: number): number {
    for (const range of this.ranges) {
      if (range.includes(sourceNumber)) {
        return range.toDestination(sourceNumber);
      }
    }
    return sourceNumber;
  }

  toDestinationRanges(sourceRanges: ValueRange[]): ValueRange[] {
    const destinationRanges: ValueRange[] = [];
    for (const sourceRange of sourceRanges) {
      for (const mappingRange of this.ranges) {
        if (!mappingRange.intersectsRange(sourceRange)) {
          continue;
        }
        const intersection = mappingRange.intersection(sourceRange);
        const mappedIntersection = mappingRange.toDestinationRange(intersection);
        destinationRanges.push(mappedIntersection);
      }
    }
    return destinationRanges;
  }
}

interface SimpleRange {
  start: number;
  end: number;
}

class ValueRange implements SimpleRange {

  constructor(
    readonly start: number,
    readonly end: number
  ) {}

  includes(sourceNumber: number): boolean {
    return sourceNumber >= this.start && sourceNumber <= this.end;
  }

  includesRange({start, end}: SimpleRange): boolean {
    return this.includes(start) && this.includes(end);
  }

  intersectsRange({start, end}: SimpleRange): boolean {
    return this.includes(start) || this.includes(end);
  }

  intersection(range: SimpleRange): ValueRange {
    if (this.includesRange(range)) {
      return range instanceof ValueRange ? range : new ValueRange(range.start, range.end);
    }
    if (!this.intersectsRange(range)) {
      throw new Error(`Range ${this.start}-${this.end} does not intersect with: ${this}`);
    }
    return new ValueRange(
      Math.max(this.start, range.start),
      Math.min(this.end, range.end),
    )
  }

  toString(): string {
    return `${this.start}-${this.end >= infinity ? '∞' : this.end}`;
  }
}

class MappingRange extends ValueRange {

  readonly destinationStart: number;
  readonly sourceToDestinationDelta: number;

  constructor(sourceStart: number, destinationStart: number, length: number) {
    super(sourceStart, sourceStart + length - 1);
    this.destinationStart = destinationStart;
    this.sourceToDestinationDelta = destinationStart - sourceStart;
  }

  toDestination(sourceNumber: number): number {
    if (!this.includes(sourceNumber)) {
      throw new Error(`Out of range ${this}: ${sourceNumber}`);
    }
    return sourceNumber + this.sourceToDestinationDelta;
  }

  toDestinationRange({start, end}: SimpleRange): ValueRange {
    try {
      return new ValueRange(this.toDestination(start), this.toDestination(end));
    } catch (error) {
      throw Error(`Out of range ${this}: ${start}-${end}`)
    }
  }

  toString(): string {
    return `${super.toString()} ${this.sourceToDestinationDelta >= 0 ? '+' : ''}${this.sourceToDestinationDelta}`;
  }
}
// endregion

// region Shared Code
function parseInput(input: string): {seeds: number[], mappings: ResourceMap[]} {
  const lines = splitLines(input);
  const seeds = lines[0].split(':')[1].trim().split(/\s+/).map(Number);
  const mappings = lines.slice(2).join('\n').split('\n\n')
    .map((text) => {
      const lines = text.split('\n');
      const {source, destination} = lines[0].match(/(?<source>[a-z]+)-to-(?<destination>[a-z]+)/)!.groups!;
      return new ResourceMap(source, destination, lines.slice(1));
    })
  return {seeds, mappings};
}
// endregion
