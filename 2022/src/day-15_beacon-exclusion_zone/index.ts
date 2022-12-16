import { Point, splitLines } from '../../../util/util';

export interface SensorSystem {
  sensors: Sensor[];
}

export interface Sensor {
  position: Point;
  closestBeacon: Point;
  detectionRadius: number;
}

const positionPattern = /at x=(?<x>-?\d+), y=(?<y>-?\d+)/g;

export function parseSensorSystem(input: string): SensorSystem {
  const lines = splitLines(input);
  const sensors: SensorSystem['sensors'] = [];
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
  return { sensors };
}

export function countExclusionSizeInRow(system: SensorSystem, rowY: number): number {
  const excludedX = new Set<number>();
  for (const sensor of system.sensors) {
    const {position, detectionRadius} = sensor;
    const cutoff = detectionRadius - Math.abs(position.y - rowY);
    if (cutoff < 0) {
      continue;
    }

    excludedX.add(position.x);
    for (let deltaX = cutoff; deltaX > 0; deltaX--) {
      excludedX.add(position.x + deltaX);
      excludedX.add(position.x - deltaX);
    }
  }
  system.sensors.filter((s) => s.closestBeacon.y === rowY).forEach((s) => excludedX.delete(s.closestBeacon.x));
  return excludedX.size;
}
