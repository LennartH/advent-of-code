import { splitLines } from '../../../util/util';

export function parseMonkeys(input: string): Monkey[] {
  const monkeyInputs = input.trim().split(/\n\s*\n/);
  const monkeys: Monkey[] = [];
  for (const monkeyInput of monkeyInputs) {
    const lines = splitLines(monkeyInput);
    const startingItems = lines[1].substring(lines[1].indexOf(':') + 1).trim().split(', ').map((v) => Number(v));
    const operationParts = lines[2].substring(lines[2].indexOf('=') + 1).trim().split(' ');
    monkeys.push(new Monkey(
      startingItems,
      {
        operand1: operationParts[0] === 'old' ? 'old' : Number(operationParts[0]),
        operator: operationParts[1] as never,
        operand2: operationParts[2] === 'old' ? 'old' : Number(operationParts[2]),
      },
      {
        divisor: Number(lines[3].substring(lines[3].lastIndexOf(' ') + 1)),
        targetIfTrue: Number(lines[4].substring(lines[4].lastIndexOf(' ') + 1)),
        targetIfFalse: Number(lines[5].substring(lines[5].lastIndexOf(' ') + 1)),
      }
    ))
  }
  return monkeys;
}

export class Game {
  private readonly monkeys: Monkey[];
  private readonly worryDivisor: number;
  private readonly worryModulo: number;

  get inspectionsCounts(): number[] {
    return this.monkeys.map((m) => m.inspectionsCount);
  }

  constructor(monkeys: Monkey[], worryDivisor: number) {
    this.monkeys = monkeys;
    this.worryDivisor = worryDivisor;
    this.worryModulo = this.monkeys.reduce((s, m) => s * m.throwConfig.divisor, 1);
  }

  executeGame(numberOfRounds: number) {
    for (let i = 0; i < numberOfRounds; i++) {
      this.executeRound();
    }
  }

  executeRound() {
    for(const monkey of this.monkeys) {
      for (const {target, item} of monkey.executeRound(this.worryDivisor, this.worryModulo)) {
        this.monkeys[target].addItem(item);
      }
    }
  }

  calculateMonkeyBusiness(): number {
    const orderedBusinessPerMonkey = this.inspectionsCounts.sort((a, b) => b - a);
    return orderedBusinessPerMonkey[0] * orderedBusinessPerMonkey[1];
  }
}

export class Monkey {
  private items: number[];
  readonly inspectionConfig: InspectionConfig;
  readonly throwConfig: ThrowConfig;

  private _inspectionsCount = 0;
  get inspectionsCount(): number {
    return this._inspectionsCount;
  }

  constructor(
    startingItems: number[],
    inspectionConfig: InspectionConfig,
    throwConfig: ThrowConfig,
  ) {
    this.items = [...startingItems];
    this.inspectionConfig = inspectionConfig;
    this.throwConfig = throwConfig;
  }

  executeRound(worryDivisor: number, worryModulo: number): {target: number, item: number}[] {
    const itemsAfterRound: number[] = [];
    const throws: {target: number, item: number}[] = [];
    for (const item of this.items) {
      const itemAfterInspection = this.inspectItem(item, worryDivisor, worryModulo);
      const throwTarget = this.getTargetFor(itemAfterInspection);
      throws.push({target: throwTarget, item: itemAfterInspection});
      this._inspectionsCount++;
    }
    this.items = itemsAfterRound;
    return throws;
  }

  inspectItem(item: number, worryDivisor: number, worryModulo: number): number {
    const {operand1, operator, operand2} = this.inspectionConfig;
    const reducedWorry = item % worryModulo;
    const operand1Value = operand1 === 'old' ? reducedWorry : operand1;
    const operand2Value = operand2 === 'old' ? reducedWorry : operand2;
    const itemAfterInspection = operator === '+' ? operand1Value + operand2Value : operand1Value * operand2Value;
    return Math.floor(itemAfterInspection / worryDivisor);
  }

  getTargetFor(item: number): number {
    const {divisor, targetIfTrue, targetIfFalse} = this.throwConfig;
    return item % divisor === 0 ? targetIfTrue : targetIfFalse;
  }

  addItem(item: number) {
    this.items.push(item);
  }
}

export interface InspectionConfig {
  readonly operand1: 'old' | number;
  readonly operator: '+' | '*';
  readonly operand2: 'old' | number;
}

export interface ThrowConfig {
  readonly divisor: number;
  targetIfTrue: number;
  targetIfFalse: number;
}
