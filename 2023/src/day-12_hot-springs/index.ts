import { splitLines, unique } from '@util';

// region Types and Globals
interface DamageReport {
  maxNumberOfDamagedSprings: number;
  damageGroups: number[];
  uncertainSprings: string;
}
// endregion

export function solvePart1(input: string): number {
  const reports = splitLines(input).map(parseDamageReport);
  return reports
    .map(findArrangements)
    .map((l) => l.length)
    .reduce((s, v) => s + v, 0);
}

export function solvePart2(input: string): number {
  const lines = splitLines(input);
  // TODO Implement solution
  return Number.NaN;
}

// region Shared Code
function parseDamageReport(line: string): DamageReport {
  const [springs, groups] = line.split(' ');
  const damageGroups = groups.split(',').map(Number);
  return {
    maxNumberOfDamagedSprings: damageGroups.reduce((s, v) => s + v, 0),
    damageGroups,
    uncertainSprings: springs,
  }
}

function findArrangements(report: DamageReport): string[] {
  const uniqueArrangements = unique(collapse(report.uncertainSprings.split('')).map((s) => s.join('')));
  const validArrangements: string[] = [];
  for (const springs of uniqueArrangements) {
    const valid = isValid(springs.split(''), report);
    if (valid) {
      validArrangements.push(springs);
    }
  }
  return validArrangements;
}

function collapse(springs: string[]): string[][] {
  if (isCollapsed(springs)) {
    return [springs];
  }
  // TODO Case if max damaged springs has been reached?

  const uncertainSpring = springs.indexOf('?');
  const left = [...springs];
  left[uncertainSpring] = '.';
  const right = [...springs];
  right[uncertainSpring] = '#';
  return [
    ...collapse(left),
    ...collapse(right),
  ]
}

function isCollapsed(springs: string[]): boolean {
  return !springs.some((v) => v === '?');
}

function isValid(collapsedSprings: string[], report: DamageReport): boolean {
  const foundGroups: number[] = [];
  let groupSize = 0;
  for (const spring of collapsedSprings) {
    if (spring === '#') {
      groupSize++;
    } else if (groupSize > 0) {
      foundGroups.push(groupSize);
      groupSize = 0;
    }
  }
  if (groupSize > 0) {
    foundGroups.push(groupSize);
  }
  return arraysEqualIgnoreOrder(foundGroups, report.damageGroups);
}

function arraysEqualIgnoreOrder(a: number[], b: number[]): boolean {
  if (a.length !== b.length) {
    return false;
  }

  for (let i = 0; i < a.length; i++) {
    if (a[i] !== b[i]) {
      return false;
    }
  }
  return true;
}
// endregion
