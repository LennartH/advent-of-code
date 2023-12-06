import { splitLines } from '@util';

// region Types and Globals
interface Race {
  time: number;
  distanceRecord: number;
}
// endregion

export function solvePart1(input: string): number {
  const races = parseRaces(splitLines(input));
  return races.map((race) => {
    let winCount = 0;
    for (let i = 0; i < race.time; i++) {
      const distance = i * (race.time - i);
      if (distance > race.distanceRecord) {
        winCount++;
      }
    }
    return winCount;
  }).reduce((s, v) => s * v, 1);
}

export function solvePart2(input: string): number {
  const lines = splitLines(input);
  // TODO Implement solution
  return Number.NaN;
}

// region Shared Code
function parseRaces(lines: string[]): Race[] {
  const times = lines[0].split(/\s+/).slice(1).map(Number);
  const distanceRecords = lines[1].split(/\s+/).slice(1).map(Number);

  const races: Race[] = [];
  for (let i = 0; i < times.length; i++) {
    races.push({
      time: times[i],
      distanceRecord: distanceRecords[i],
    });
  }
  return races;
}
// endregion
