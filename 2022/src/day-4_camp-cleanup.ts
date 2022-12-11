import * as fs from 'fs';

class SectionAssignment {
  readonly from: number;
  readonly to: number;

  constructor(range: string) {
    const parts = range.split('-');
    this.from = Number(parts[0]);
    this.to = Number(parts[1]);
  }

  hasSubsetRelationshipWith(other: SectionAssignment): boolean {
    return (this.from >= other.from && this.to <= other.to) || (other.from >= this.from && other.to <= this.to);
  }

  overlapsWith(other: SectionAssignment): boolean {
    return (this.to >= other.from && this.from <= other.from) || (other.to >= this.from && other.from <= this.from);
  }
}

function createAssignmentPair(line: string): [SectionAssignment, SectionAssignment] {
  const ranges = line.split(',');
  return [new SectionAssignment(ranges[0]), new SectionAssignment(ranges[1])];
}

function exampleSolution() {
  const lines = `
    2-4,6-8
    2-3,4-5
    5-7,7-9
    2-8,3-7
    6-6,4-6
    2-6,4-8
  `
    .trim()
    .split('\n')
    .map((l) => l.trim());
  const assignmentPairs = lines.map(createAssignmentPair);

  const part1Result = assignmentPairs
    .map(([a1, a2]) => (a1.hasSubsetRelationshipWith(a2) ? 1 : 0))
    .reduce((s: number, v) => s + v, 0);
  const part2Result = assignmentPairs
    .map(([a1, a2]) => (a1.overlapsWith(a2) ? 1 : 0))
    .reduce((s: number, v) => s + v, 0);
  console.log(`Solution for example input: Part 1 ${part1Result} | Part 2 ${part2Result}`);
}

function part1Solution() {
  const lines = fs.readFileSync('./assets/day-4_camp-cleanup.input.txt', 'utf-8').trim().split('\n');
  const assignmentPairs = lines.map(createAssignmentPair);
  const subsetPairCount = assignmentPairs
    .map(([a1, a2]) => (a1.hasSubsetRelationshipWith(a2) ? 1 : 0))
    .reduce((s: number, v) => s + v, 0);
  console.log(`Solution for Part 1: ${subsetPairCount}`);
}

function part2Solution() {
  const lines = fs.readFileSync('./assets/day-4_camp-cleanup.input.txt', 'utf-8').trim().split('\n');
  const assignmentPairs = lines.map(createAssignmentPair);
  const overlapsCount = assignmentPairs
    .map(([a1, a2]) => (a1.overlapsWith(a2) ? 1 : 0))
    .reduce((s: number, v) => s + v, 0);
  console.log(`Solution for Part 2: ${overlapsCount}`);
}

exampleSolution();
part1Solution();
part2Solution();
