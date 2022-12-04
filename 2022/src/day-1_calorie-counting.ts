import * as fs from 'fs';

function getOrderedCaloriesCounts(lines: string[]): number[] {
  let accumulator = 0;
  return  lines.map((s) => s.length === 0 ? 0 : Number(s)).reduce((list, value, index, values) => {
    accumulator += value;
    if (value === 0 || index === values.length - 1) {
      list.push(accumulator);
      accumulator = 0;
    }
    return list;
  }, [] as number[]).sort((a, b) => b - a);
}

function exampleSolution() {
  const lines = `
    1000
    2000
    3000
    
    4000
    
    5000
    6000
    
    7000
    8000
    9000
    
    10000
  `.trim().split('\n').map((l) => l.trim());
  const caloriesCarried = getOrderedCaloriesCounts(lines);
  const part1Score = caloriesCarried[0];
  const part2Score = caloriesCarried.slice(0, 3).reduce((s, v) => s + v, 0);
  console.log(`Solution for example input: Part 1 ${part1Score} | Part 2 ${part2Score}`);
}

function part1Solution() {
  const lines = fs.readFileSync('./assets/day-1_calorie-counting.input.txt', 'utf-8').trim().split('\n');
  const maxCaloriesCarried = getOrderedCaloriesCounts(lines)[0];
  console.log(`Solution for Part 1: ${maxCaloriesCarried}`);
}

function part2Solution() {
  const lines = fs.readFileSync('./assets/day-1_calorie-counting.input.txt', 'utf-8').trim().split('\n');
  const caloriesCarried = getOrderedCaloriesCounts(lines);
  const top3CaloriesCarried = caloriesCarried.slice(0, 3).reduce((s, v) => s + v, 0);
  console.log(`Solution for Part 2: ${top3CaloriesCarried}`);
}


exampleSolution();
part1Solution();
part2Solution();
