import * as fs from 'fs';

const alphabet = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'

function getDuplicateItem(rucksack: string): string {
  const halfSize = rucksack.length / 2;
  for (let i = 0; i < halfSize; i++) {
    const item = rucksack[i];
    if (rucksack.includes(item, halfSize)) {
      return item;
    }
  }
  throw new Error(`No common item found in '${(rucksack.slice(0, halfSize))}' and '${(rucksack.slice(halfSize))}'`);
}

function getGroupItem(group: string[]): string {
  for (let i = 0; i < group[0].length; i++) {
    const item = group[0].charAt(i);
    if (group[1].includes(item) && group[2].includes(item)) {
      return item;
    }
  }
  throw new Error(`No common item found in group ${group.map((r) => `'${r}'`).join(', ')}`);
}

function getItemPriority(item: string): number {
  const alphabetIndex = alphabet.indexOf(item);
  if (alphabetIndex === -1) {
    throw new Error(`Invalid item '${item}'`);
  }
  return alphabetIndex + 1;
}

function exampleSolution() {
  const lines = `
    vJrwpWtwJgWrhcsFMMfFFhFp
    jqHRNqRjqzjGDLGLrsFMfFZSrLrFZsSL
    PmmdzqPrVvPwwTWBwg
    wMqvLMZHhHMvwLHjbvcjnnSBnvTQFn
    ttgJtRGJQctTZtZT
    CrZsJsPPZsGzwwsLwLmpwMDw
  `.trim().split('\n').map((l) => l.trim());
  const groups = [];
  for (let i = 0; i < lines.length; i += 3) {
    groups.push(lines.slice(i, i + 3));
  }

  const part1Result = lines.map(getDuplicateItem).map(getItemPriority).reduce((s, v) => s + v, 0);
  const part2Result = groups.map(getGroupItem).map(getItemPriority).reduce((s, v) => s + v, 0);
  console.log(`Solution for example input: Part 1 ${part1Result} | Part 2 ${part2Result}`);
}

function part1Solution() {
  const lines = fs.readFileSync('./assets/day-3_rucksack_reorganization.input.txt', 'utf-8').trim().split('\n');
  const prioritySum = lines.map(getDuplicateItem).map(getItemPriority).reduce((s, v) => s + v, 0);
  console.log(`Solution for Part 1: ${prioritySum}`);
}

function part2Solution() {
  const lines = fs.readFileSync('./assets/day-3_rucksack_reorganization.input.txt', 'utf-8').trim().split('\n');
  const groups = [];
  for (let i = 0; i < lines.length; i += 3) {
    groups.push(lines.slice(i, i + 3));
  }
  const prioritySum = groups.map(getGroupItem).map(getItemPriority).reduce((s, v) => s + v, 0);
  console.log(`Solution for Part 2: ${prioritySum}`);
}


exampleSolution();
part1Solution();
part2Solution();
