import { formatGrid, splitLines } from '@util';

enum CellState {
  Lava = '#',
  Air = '.',
  Trapped = '-',
}

export interface Voxel {
  x: number;
  y: number;
  z: number;
}

export interface Droplet {
  lava: Voxel[];
  cells: CellState[][][];
  bounds: { width: number, depth: number, height: number }
}

const directions = [
  {dx: 1, dy: 0, dz: 0}, {dx: -1, dy: 0, dz: 0},
  {dx: 0, dy: 1, dz: 0}, {dx: 0, dy: -1, dz: 0},
  {dx: 0, dy: 0, dz: 1}, {dx: 0, dy: 0, dz: -1},
]

export function parseDroplet(input: string): Droplet {
  const lines = splitLines(input);
  const cells: Droplet['cells'] = [];
  const bounds = { width: 0, depth: 0, height: 0 };
  const lava = lines.map((line) => {
    const parts = line.split(',');
    const voxel = {
      x: Number(parts[0]),
      y: Number(parts[1]),
      z: Number(parts[2]),
    };
    setCellValue(cells, voxel, CellState.Lava);
    bounds.width = Math.max(bounds.width, voxel.x + 1);
    bounds.depth = Math.max(bounds.depth, voxel.y + 1);
    bounds.height = Math.max(bounds.height, voxel.z + 1);
    return voxel;
  });

  const queue: Voxel[] = [{x: 0, y: 0, z: 0}];
  while (queue.length > 0) {
    const voxel = queue.pop()!;
    setCellValue(cells, voxel, CellState.Air);
    queue.push(...directions
      .map(({dx, dy, dz}) => ({x: voxel.x + dx, y: voxel.y + dy, z: voxel.z + dz}))
      .filter(({x, y, z}) =>
        x >= 0 && x < bounds.width &&
        y >= 0 && y < bounds.depth &&
        z >= 0 && z < bounds.height &&
        !cells[z]?.[y]?.[x]
      )
    );
  }
  for (let z = 0; z < bounds.height; z++) {
    for (let y = 0; y < bounds.depth; y++) {
      for (let x = 0; x < bounds.width; x++) {
        if (!cells[z]?.[y]?.[x]) {
          setCellValue(cells, {x, y, z}, CellState.Trapped);
        }
      }
    }
  }

  return { lava, cells, bounds };
}

function setCellValue(cells: Droplet['cells'], voxel: Voxel, value: CellState) {
  let plane = cells[voxel.z];
  if (!plane) {
    plane = [];
    cells[voxel.z] = plane;
  }
  let row = plane[voxel.y];
  if (!row) {
    row = [];
    plane[voxel.y] = row;
  }
  row[voxel.x] = value;
}

export function calculateDropletSurfaceArea(droplet: Droplet): number {
  let area = 0;
  for (const voxel of droplet.lava) {
    for (const direction of directions) {
      const { x, y, z } = {
        x: voxel.x + direction.dx,
        y: voxel.y + direction.dy,
        z: voxel.z + direction.dz,
      };
      if (droplet.cells[z]?.[y]?.[x] !== CellState.Lava) {
        area++;
      }
    }
  }
  return area;
}

export function calculateExposedDropletSurfaceArea(droplet: Droplet): number {
  let area = 0;
  for (const voxel of droplet.lava) {
    for (const direction of directions) {
      const { x, y, z } = {
        x: voxel.x + direction.dx,
        y: voxel.y + direction.dy,
        z: voxel.z + direction.dz,
      };
      const cellState = droplet.cells[z]?.[y]?.[x];
      if (!cellState || cellState === CellState.Air) {
        area++;
      }
    }
  }
  return area;
}

export function dropletAsString(droplet: Droplet): string[] {
  return droplet.cells.map((plane, z) => formatGrid(plane, {
    outsideCorner: `${z}`, rowSuffix: `${z}`, rowPrefix: `${z}`, columnSuffix: `${z}`, columnPrefix: `${z}`,
  }))
}
