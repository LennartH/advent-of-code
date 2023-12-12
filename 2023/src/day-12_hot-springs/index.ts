import { splitLines } from '@util';

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
  const reports = splitLines(input).map(parseDamageReport);

  let count = 0;
  for (const report of reports) {
    const initialArrangements = findArrangements(report);
    const initialArrangementsCount = initialArrangements.length;
    let unfoldedArrangementsCount = 0;
    if (initialArrangements.some((s) => s.at(-1) === '#')) {
      const unfoldedReport: DamageReport = {
        maxNumberOfDamagedSprings: report.maxNumberOfDamagedSprings,
        damageGroups: [1, ...report.damageGroups],
        uncertainSprings: `#?${report.uncertainSprings}`,
      };
      const unfoldedArrangements = findArrangements(unfoldedReport);
      unfoldedArrangementsCount += unfoldedArrangements.length;
    }
    if (initialArrangements.some((s) => s.at(-1) === '.')) {
      const unfoldedReport: DamageReport = {
        maxNumberOfDamagedSprings: report.maxNumberOfDamagedSprings,
        damageGroups: [...report.damageGroups],
        uncertainSprings: `?${report.uncertainSprings}`,
      };
      const unfoldedArrangements = findArrangements(unfoldedReport);
      unfoldedArrangementsCount += unfoldedArrangements.length;
    }
    const reportCount = initialArrangementsCount * unfoldedArrangementsCount * unfoldedArrangementsCount * unfoldedArrangementsCount * unfoldedArrangementsCount;
    console.log(report.uncertainSprings, '->', reportCount);
    count += reportCount;
  }

  return count;
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
  const validArrangements: string[] = [];
  for (const springs of collapse(report.uncertainSprings.split(''))) {
    if (isValid(springs, report)) {
      validArrangements.push(springs.join(''));
    }
  }
  return validArrangements;
}

function* collapse(springs: string[]): Generator<string[]> {
  if (isCollapsed(springs)) {
    return yield springs;
  }
  // TODO Case if max damaged springs has been reached?

  const uncertainSpring = springs.indexOf('?');
  const left = [...springs];
  left[uncertainSpring] = '.';
  for (const collapsed of collapse(left)) {
    yield collapsed;
  }
  const right = [...springs];
  right[uncertainSpring] = '#';
  for (const collapsed of collapse(right)) {
    yield collapsed;
  }
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
