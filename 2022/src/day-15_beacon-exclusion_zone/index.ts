import { Point, splitLines } from '../../../util/util';

export interface Sensor {
  position: Point;
  closestBeacon: Point;
  detectionRadius: number;
}

const positionPattern = /at x=(?<x>-?\d+), y=(?<y>-?\d+)/g;

export function parseSensors(input: string): Sensor[] {
  const lines = splitLines(input);
  const sensors: Sensor[] = [];
  for (const line of lines) {
    const [{groups: sensorMatch}, {groups: beaconMatch}] = [...line.matchAll(positionPattern)];
    if (!sensorMatch || !beaconMatch) {
      throw new Error(`Unable to parse line: ${line}`);
    }
    const sensorPosition = {x: Number(sensorMatch.x), y: Number(sensorMatch.y)};
    const beaconPosition = {x: Number(beaconMatch.x), y: Number(beaconMatch.y)};
    sensors.push({
      position: sensorPosition,
      closestBeacon: beaconPosition,
      detectionRadius: Math.abs(sensorPosition.x - beaconPosition.x) + Math.abs(sensorPosition.y - beaconPosition.y),
    })
  }
  return sensors;
}

export function countExclusionSizeInRow(sensors: Sensor[], rowY: number): number {
  const excludedX = new Set<number>();
  for (const sensor of sensors) {
    const {position, detectionRadius} = sensor;
    const remainingRange = detectionRadius - Math.abs(position.y - rowY);
    if (remainingRange < 0) {
      continue;
    }

    excludedX.add(position.x);
    for (let deltaX = remainingRange; deltaX > 0; deltaX--) {
      excludedX.add(position.x + deltaX);
      excludedX.add(position.x - deltaX);
    }
  }
  sensors.filter((s) => s.closestBeacon.y === rowY).forEach((s) => excludedX.delete(s.closestBeacon.x));
  return excludedX.size;
}

export function findDistressTuningFrequency(sensors: Sensor[], positionMin: number, positionMax: number): number {
  let x = positionMin;
  let y = positionMin - 1;
  let distressBeaconFound = false;
  while (!distressBeaconFound && y <= positionMax) {
    x = positionMin;
    y++;

    const exclusionSegments: {from: number, to: number}[] = [];
    for (const sensor of sensors) {
      const {position, detectionRadius} = sensor;
      const remainingRange = detectionRadius - Math.abs(position.y - y);
      if (remainingRange > 0) {
        exclusionSegments.push({from: position.x - remainingRange, to: position.x + remainingRange});
      }
    }
    exclusionSegments.sort(({from: a}, {from: b}) => a - b);

    if (exclusionSegments[0].from > positionMin) {
      x = positionMin;
      distressBeaconFound = true;
      break;
    }
    for (const { from, to } of exclusionSegments) {
      if (x + 1 < from) {
        x++;
        distressBeaconFound = true;
        break;
      }
      x = Math.max(x, to);
    }
    if (!distressBeaconFound && x + 1 < positionMax) {
      x++;
      distressBeaconFound = true;
    }
  }

  if (!distressBeaconFound) {
    throw new Error('No distress beacon could be found');
  }
  return (x * 4000000) + y;
}
