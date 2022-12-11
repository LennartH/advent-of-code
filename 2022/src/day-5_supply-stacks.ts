import * as fs from 'fs';

function parseStacks(input: string): string[][] {
  const lines = input.split('\n').slice(0, -1);
  if ((lines[0].length + 1) % 4 !== 0) {
    throw new Error('Unable to determine number of stacks from input');
  }
  const stacksCount = (lines[0].length + 1) / 4;

  const stacks: string[][] = [];
  stacks.length = stacksCount;
  for (const line of lines) {
    if (line.length === 0) {
      continue;
    }
    for (let i = 0; i < stacks.length; i++) {
      const crateIndex = 1 + i * 4;
      const crate = line[crateIndex];
      if (crate !== ' ') {
        let stack = stacks[i];
        if (!stack) {
          stack = [];
          stacks[i] = stack;
        }
        stack.unshift(crate);
      }
    }
  }
  return stacks;
}

type Instruction = {
  quantity: number;
  from: number;
  to: number;
};

function parseInstructions(input: string): Instruction[] {
  const lines = input.split('\n');
  const instructionPattern = /move (?<quantity>\d+) from (?<from>\d+) to (?<to>\d+)/;

  return lines
    .filter((l) => l.length > 0)
    .map((line) => {
      const match = line.match(instructionPattern);
      if (match == null || match.groups == null) {
        throw new Error(`Invalid instruction input '${line}'`);
      }
      return {
        quantity: Number(match.groups['quantity']),
        from: Number(match.groups['from']) - 1,
        to: Number(match.groups['to']) - 1,
      };
    });
}

function processInstructions(stacks: string[][], instructions: Instruction[], bulk: boolean): string[][] {
  const changedStacks: string[][] = stacks.map((s) => [...s]);
  for (const instruction of instructions) {
    const quantity = instruction.quantity;
    const from = changedStacks[instruction.from];
    const to = changedStacks[instruction.to];
    if (from.length < quantity) {
      throw new Error(
        `Invalid instructions ${instruction.from} -${quantity}-> ${instruction.to}: Source stack is empty`
      );
    }
    if (bulk) {
      const crates = from.splice(-quantity, quantity);
      to.splice(to.length, 0, ...crates);
    } else {
      for (let i = 0; i < instruction.quantity; i++) {
        to.push(from.pop()!);
      }
    }
  }
  return changedStacks;
}

function exampleSolution() {
  const input = `
    [D]    
[N] [C]    
[Z] [M] [P]
 1   2   3 

move 1 from 2 to 1
move 3 from 1 to 3
move 2 from 2 to 1
move 1 from 1 to 2
  `.slice(1, -3);
  const [stacksInput, instructionsInput] = input.split('\n\n');
  const stacks = parseStacks(stacksInput);
  const instructions = parseInstructions(instructionsInput);

  const part1Result = processInstructions(stacks, instructions, false)
    .map((s) => s[s.length - 1])
    .join('');
  const part2Result = processInstructions(stacks, instructions, true)
    .map((s) => s[s.length - 1])
    .join('');
  console.log(`Solution for example input: Part 1 ${part1Result} | Part 2 ${part2Result}`);
}

function part1Solution() {
  const input = fs.readFileSync('./assets/day-5_supply-stacks.input.txt', 'utf-8');
  const [stacksInput, instructionsInput] = input.split('\n\n');
  let stacks = parseStacks(stacksInput);
  const instructions = parseInstructions(instructionsInput);
  stacks = processInstructions(stacks, instructions, false);
  const topCrates = stacks.map((s) => s[s.length - 1]).join('');
  console.log(`Solution for Part 1: ${topCrates}`);
}

function part2Solution() {
  const input = fs.readFileSync('./assets/day-5_supply-stacks.input.txt', 'utf-8');
  const [stacksInput, instructionsInput] = input.split('\n\n');
  let stacks = parseStacks(stacksInput);
  const instructions = parseInstructions(instructionsInput);
  stacks = processInstructions(stacks, instructions, true);
  const topCrates = stacks.map((s) => s[s.length - 1]).join('');
  console.log(`Solution for Part 2: ${topCrates}`);
}

exampleSolution();
part1Solution();
part2Solution();
