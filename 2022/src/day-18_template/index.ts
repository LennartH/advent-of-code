import { splitLines } from '@util';

export interface Voxel {
  x: number;
  y: number;
  z: number;
}

export interface Droplet {
  voxel: Voxel[];
  isOccupied: boolean[][][];
}

export function parseDroplet(input: string): Droplet {
  const lines = splitLines(input);
  const isOccupied: boolean[][][] = [];
  const voxel = lines.map((line) => {
    const parts = line.split(',');
    const voxel = {
      x: Number(parts[0]),
      y: Number(parts[1]),
      z: Number(parts[2]),
    };
    let plane = isOccupied[voxel.z];
    if (!plane) {
      plane = [];
      isOccupied[voxel.z] = plane;
    }
    let row = plane[voxel.y];
    if (!row) {
      row = [];
      plane[voxel.y] = row;
    }
    row[voxel.x] = true;
    return voxel;
  });
  return { voxel, isOccupied };
}

const directions = [
  {x: 1, y: 0, z: 0}, {x: -1, y: 0, z: 0},
  {x: 0, y: 1, z: 0}, {x: 0, y: -1, z: 0},
  {x: 0, y: 0, z: 1}, {x: 0, y: 0, z: -1},
]

export function calculateDropletSurfaceArea(droplet: Droplet): number {
  let area = 0;
  for (const voxel of droplet.voxel) {
    for (const direction of directions) {
      const { x, y, z } = {
        x: voxel.x + direction.x,
        y: voxel.y + direction.y,
        z: voxel.z + direction.z,
      };
      if (!droplet.isOccupied[z]?.[y]?.[x]) {
        area++;
      }
    }
  }
  return area;
}
