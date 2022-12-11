import * as fs from 'fs';

enum Direction {
  Top,
  Right,
  Bottom,
  Left,
}
const directionDelta = [
  [0, -1],
  [1, 0],
  [0, 1],
  [-1, 0],
];
const directions = [Direction.Top, Direction.Right, Direction.Bottom, Direction.Left];

function readGrid(lines: string[]): number[][] {
  return lines.map((line) => {
    const row: number[] = [];
    row.length = line.length;
    for (let i = 0; i < line.length; i++) {
      row[i] = Number(line[i]);
    }
    return row;
  });
}

function countVisibleTrees(grid: number[][]): number {
  let count = 0;
  const width = grid[0].length;
  const height = grid.length;
  for (let y = 0; y < height; y++) {
    for (let x = 0; x < width; x++) {
      const treeHeight = grid[y][x];
      for (const direction of directions) {
        const [deltaX, deltaY] = directionDelta[direction];
        let nextX = x + deltaX;
        let nextY = y + deltaY;
        let maxHeightInDirection = -1;
        while (nextX >= 0 && nextX < width && nextY >= 0 && nextY < height && treeHeight > maxHeightInDirection) {
          const otherTreeHeight = grid[nextY][nextX];
          maxHeightInDirection = otherTreeHeight > maxHeightInDirection ? otherTreeHeight : maxHeightInDirection;
          nextX += deltaX;
          nextY += deltaY;
        }
        if (treeHeight > maxHeightInDirection) {
          count++;
          break;
        }
      }
    }
  }
  return count;
}

function findMaxScenicScore(grid: number[][]): number {
  let maxScenicScore = 0;
  const width = grid[0].length;
  const height = grid.length;
  for (let y = 1; y < height - 1; y++) {
    for (let x = 1; x < width - 1; x++) {
      const treeHeight = grid[y][x];
      const viewRange = [0, 0, 0, 0];
      for (const direction of directions) {
        const [deltaX, deltaY] = directionDelta[direction];
        let nextX = x + deltaX;
        let nextY = y + deltaY;
        let maxHeightInDirection = -1;
        while (nextX >= 0 && nextX < width && nextY >= 0 && nextY < height && treeHeight > maxHeightInDirection) {
          const otherTreeHeight = grid[nextY][nextX];
          maxHeightInDirection = otherTreeHeight > maxHeightInDirection ? otherTreeHeight : maxHeightInDirection;
          nextX += deltaX;
          nextY += deltaY;
          viewRange[direction]++;
        }
      }
      const scenicScore = viewRange.reduce((s, v) => s * v);
      maxScenicScore = scenicScore > maxScenicScore ? scenicScore : maxScenicScore;
    }
  }
  return maxScenicScore;
}

function exampleSolution() {
  const lines = `
    30373
    25512
    65332
    33549
    35390
  `
    .trim()
    .split('\n')
    .map((l) => l.trim());
  const grid = readGrid(lines);

  const part1Result = countVisibleTrees(grid);
  const part2Result = findMaxScenicScore(grid);
  console.log(`Solution for example input: Part 1 ${part1Result} | Part 2 ${part2Result}`);
}

function part1Solution() {
  const lines = fs.readFileSync('./assets/day-8_treetop-tree-house.input.txt', 'utf-8').trim().split('\n');
  const grid = readGrid(lines);
  const visibleTrees = countVisibleTrees(grid);
  console.log(`Solution for Part 1: ${visibleTrees}`);
}

function part2Solution() {
  const lines = fs.readFileSync('./assets/day-8_treetop-tree-house.input.txt', 'utf-8').trim().split('\n');
  const grid = readGrid(lines);
  const maxScenicScore = findMaxScenicScore(grid);
  console.log(`Solution for Part 2: ${maxScenicScore}`);
}

exampleSolution();
part1Solution();
part2Solution();
