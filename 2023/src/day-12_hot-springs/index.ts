import { splitLines } from '@util';

// region Types and Globals
interface DamageReport {
  damageGroups: number[];
  uncertainSprings: string;
}
// endregion

export function solvePart1(input: string): number {
  const reports = splitLines(input).map(parseDamageReport);
  return reports
    .map(countArrangements)
    .reduce((s, v) => s + v, 0);
}

export function solvePart2(input: string): number {
  const reports = splitLines(input)
    .map((line) => {
      const [springs, groups] = line.split(' ');
      const unfoldedSprings = [springs, springs, springs, springs, springs].join('?');
      const unfoldedGroups = [groups, groups, groups, groups, groups].join(',');
      return `${unfoldedSprings} ${unfoldedGroups}`;
    })
    .map(parseDamageReport);
  return reports
    .map(countArrangements)
    .reduce((s, v) => s + v, 0);
}

// region Shared Code
function parseDamageReport(line: string): DamageReport {
  const [springs, groups] = line.split(' ');
  const damageGroups = groups.split(',').map(Number);
  return {
    damageGroups,
    uncertainSprings: springs,
  }
}

function countArrangements(report: DamageReport): number {
  cache = new Map<string, number>();
  return countArrangementsWithCache(report.uncertainSprings, report.damageGroups);
}

let cache: Map<string, number>;
function countArrangementsWithCache(segment: string, groups: number[]): number {
  segment = segment.replace(/^\.+|\.+$/, '');
  if (segment.length === 0) {
    return groups.length === 0 ? 1 : 0;
  }
  if (groups.length === 0) {
    return segment.includes('#') ? 0 : 1;
  }

  const key = `${segment}|${groups.join(',')}`;
  if (cache.has(key)) {
    return cache.get(key)!;
  }

  let closedGroupAtStart = 0;
  for (let i = 0; i < segment.length; i++) {
    if (segment[i] !== '#') {
      break;
    }
    closedGroupAtStart++;
  }
  if (segment[closedGroupAtStart] === '?') {
    closedGroupAtStart = 0;
  }

  let count = 0;
  if (closedGroupAtStart > 0) {
    if (closedGroupAtStart === groups[0]) {
      count += countArrangementsWithCache(segment.slice(groups[0]), groups.slice(1));
    }
  } else if (segment.includes('?')) {
    count += countArrangementsWithCache(segment.replace('?', '.'), groups);

    const allowedNumberOfDamagedSprings = groups.reduce(((s, v) => s + v), 0);
    if (segment.split('').filter((v) => v === '#').length < allowedNumberOfDamagedSprings) {
      count += countArrangementsWithCache(segment.replace('?', '#'), groups);
    }
  }
  cache.set(key, count);
  return count;
}
// endregion
