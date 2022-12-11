import * as fs from 'fs';

abstract class Instruction {
  readonly name: string;
  readonly args: unknown[];
  readonly duration: number;

  static parse(line: string): Instruction {
    const parts = line.split(' ');
    if (parts[0] === 'noop') {
      return new NoopInstruction();
    }
    if (parts[0] === 'addx') {
      return new AddXInstruction(Number(parts[1]));
    }
    throw new Error(`Unknown instruction '${parts[0]}'`);
  }

  protected constructor(name: string, duration: number, ...args: unknown[]) {
    this.name = name;
    this.duration = duration;
    this.args = args;
  }

  execute(device: Device) {
    for (let i = 0; i < this.duration; i++) {
      device.step();
    }
    this.doExecute(device);
  }

  protected abstract doExecute(device: Device): void;
}

class NoopInstruction extends Instruction {
  constructor() {
    super('noop', 1);
  }

  protected doExecute(device: Device) {}
}

class AddXInstruction extends Instruction {
  declare readonly args: number[];

  constructor(value: number) {
    super('addx', 2, value);
  }

  protected doExecute(device: Device) {
    device.register.X += this.args[0];
  }
}

class Device {
  private _cycle = 0;
  get cycle(): number {
    return this._cycle;
  }

  readonly register = {
    X: 1,
  };

  private readonly signalStrengthLog: number[] = [];
  get totalSignalStrength(): number {
    return this.signalStrengthLog.reduce((s, v) => s + v, 0);
  }

  private readonly display: string[][];

  constructor() {
    this.display = [
      new Array(40).fill('.'),
      new Array(40).fill('.'),
      new Array(40).fill('.'),
      new Array(40).fill('.'),
      new Array(40).fill('.'),
      new Array(40).fill('.'),
    ];
  }

  step() {
    this._cycle++;

    if (this._cycle === 20 || (this._cycle <= 220 && (this._cycle - 20) % 40 === 0)) {
      this.signalStrengthLog.push(this._cycle * this.register.X);
    }

    const displayX = (this._cycle - 1) % 40;
    const displayY = Math.floor((this._cycle - 1) / 40);
    if (displayX >= this.register.X - 1 && displayX <= this.register.X + 1) {
      this.display[displayY][displayX] = '#';
    }
  }

  displaySnapshot(): string {
    return this.display.map((l) => l.map((c) => c + c).join('')).join('\n');
  }
}

function exampleSolution() {
  const lines = fs.readFileSync('./assets/day-10_cathode-ray-tube.example-input.txt', 'utf-8').trim().split('\n');
  const device = new Device();
  lines.map((l) => Instruction.parse(l)).forEach((i) => i.execute(device));

  const part1Result = device.totalSignalStrength;
  const part2Result = device.displaySnapshot();
  const separatorLine = new Array(80).fill('-').join('');
  const expectedPart2Result = `
####....####....####....####....####....####....####....####....####....####....
######......######......######......######......######......######......######..
########........########........########........########........########........
##########..........##########..........##########..........##########..........
############............############............############............########
##############..............##############..............##############..........
    `.trim();
  console.log(
    `Solution for example input\n  Part 1 ${part1Result}\n  Part 2\n${part2Result}\n  Expected for Part 2\n${expectedPart2Result}\n\n${separatorLine}\n`
  );
}

function part1Solution() {
  const lines = fs.readFileSync('./assets/day-10_cathode-ray-tube.input.txt', 'utf-8').trim().split('\n');
  const device = new Device();
  lines.map((l) => Instruction.parse(l)).forEach((i) => i.execute(device));
  console.log(`Solution for Part 1: ${device.totalSignalStrength}`);
}

function part2Solution() {
  const lines = fs.readFileSync('./assets/day-10_cathode-ray-tube.input.txt', 'utf-8').trim().split('\n');
  const device = new Device();
  lines.map((l) => Instruction.parse(l)).forEach((i) => i.execute(device));
  console.log(`Solution for Part 2:\n${device.displaySnapshot()}`);
}

exampleSolution();
part1Solution();
part2Solution();
