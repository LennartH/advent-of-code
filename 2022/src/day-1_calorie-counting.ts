import * as fs from 'fs';

// const input = `
// 1000
// 2000
// 3000
//
// 4000
//
// 5000
// 6000
//
// 7000
// 8000
// 9000
//
// 10000
// `.trim()

const input = fs.readFileSync('./assets/day1_calorie-counting.input.txt', 'utf-8').trim();

const lines = input.split('\n');

let accumulator = 0;
const maxCaloriesCarried = lines.map((s) => s.length === 0 ? 0 : Number(s)).reduce((max, value) => {
  if (value !== 0) {
    accumulator += value;
  } else {
    max = max > accumulator ? max : accumulator;
    accumulator = 0;
  }
  return max;
}, 0);

console.log(maxCaloriesCarried);
