import * as fs from 'fs';

enum Shape {Rock, Paper, Scissors}
const shapeMap: Record<string, Shape> = {
  'A': Shape.Rock,
  'X': Shape.Rock,

  'B': Shape.Paper,
  'Y': Shape.Paper,

  'C': Shape.Scissors,
  'Z': Shape.Scissors,
}
const scoreForShape: Record<Shape, number> = {
  [Shape.Rock]: 1,
  [Shape.Paper]: 2,
  [Shape.Scissors]: 3,
}

enum RoundResult {Loss, Draw, Win}
const roundResultMap: Record<string, RoundResult> = {
  'X': RoundResult.Loss,
  'Y': RoundResult.Draw,
  'Z': RoundResult.Win,
}
const scoreForGameResult: Record<RoundResult, number> = {
  [RoundResult.Loss]: 0,
  [RoundResult.Draw]: 3,
  [RoundResult.Win]: 6,
}

function getRoundResult(playerShape: Shape, opponentShape: Shape): RoundResult {
  if (playerShape === opponentShape) {
    return RoundResult.Draw;
  }

  if (playerShape === Shape.Rock) {
    return opponentShape === Shape.Scissors ? RoundResult.Win : RoundResult.Loss;
  }
  if (playerShape === Shape.Paper) {
    return opponentShape === Shape.Rock ? RoundResult.Win : RoundResult.Loss;
  }
  if (playerShape === Shape.Scissors) {
    return opponentShape === Shape.Paper ? RoundResult.Win : RoundResult.Loss;
  }
  throw new Error(`Not implemented for '${playerShape}' and '${opponentShape}'`);
}

function getShapeForResult(opponentShape: Shape, desiredResult: RoundResult): Shape {
  if (desiredResult === RoundResult.Draw) {
    return opponentShape;
  }

  if (opponentShape === Shape.Rock) {
    return desiredResult === RoundResult.Win ? Shape.Paper : Shape.Scissors;
  }
  if (opponentShape === Shape.Paper) {
    return desiredResult === RoundResult.Win ? Shape.Scissors : Shape.Rock;
  }
  if (opponentShape === Shape.Scissors) {
    return desiredResult === RoundResult.Win ? Shape.Rock : Shape.Paper;
  }
  throw new Error(`Not implemented for '${opponentShape}' and '${desiredResult}'`);
}

function calculateTotalScoreIfSecondSymbolIsShape(lines: string[]): number {
  return lines.reduce((acc, line) => {
    const player = shapeMap[line[2]];
    const opponent = shapeMap[line[0]];
    const result = getRoundResult(player, opponent);
    return acc + scoreForShape[player] + scoreForGameResult[result];
  }, 0);
}

function calculateTotalScoreIfSecondSymbolIsResult(lines: string[]): number {
  return lines.reduce((acc, line) => {
    const opponent = shapeMap[line[0]];
    const result = roundResultMap[line[2]];
    const player = getShapeForResult(opponent, result);
    return acc + scoreForShape[player] + scoreForGameResult[result];
  }, 0);
}

function exampleSolution() {
  const lines = `
    A Y
    B X
    C Z
  `.trim().split('\n').map((l) => l.trim());
  const part1Score = calculateTotalScoreIfSecondSymbolIsShape(lines);
  const part2Score = calculateTotalScoreIfSecondSymbolIsResult(lines);
  console.log(`Solution for example input: Part 1 ${part1Score} | Part 2 ${part2Score}`);
}

function part1Solution() {
  const lines = fs.readFileSync('./assets/day-2_rock-paper-scissors.input.txt', 'utf-8').trim().split('\n');
  const totalScore = calculateTotalScoreIfSecondSymbolIsShape(lines);
  console.log(`Solution for Part 1: ${totalScore}`);
}

function part2Solution() {
  const lines = fs.readFileSync('./assets/day-2_rock-paper-scissors.input.txt', 'utf-8').trim().split('\n');
  const totalScore = calculateTotalScoreIfSecondSymbolIsResult(lines);
  console.log(`Solution for Part 2: ${totalScore}`);
}


exampleSolution();
part1Solution();
part2Solution();
