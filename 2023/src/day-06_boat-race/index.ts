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
  const races = parseRaces(splitLines(input));
  const race = squashRaces(races);

  let lowerBound = 0;
  for (let i = 1; i < race.time; i++) {
    const distance = i * (race.time - i);
    if (distance > race.distanceRecord) {
      lowerBound = i;
      break;
    }
  }

  let upperBound = 0;
  for (let i = race.time - 1; i > 0; i--) {
    const distance = i * (race.time - i);
    if (distance > race.distanceRecord) {
      upperBound = i;
      break;
    }
  }

  return upperBound - lowerBound + 1;
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

function squashRaces(races: Race[]): Race {
  const squashedTime = races.map((r) => r.time.toString()).join('');
  const squashedDistanceRecord = races.map((r) => r.distanceRecord.toString()).join('');
  return {
    time: Number(squashedTime),
    distanceRecord: Number(squashedDistanceRecord),
  };
}
// endregion
