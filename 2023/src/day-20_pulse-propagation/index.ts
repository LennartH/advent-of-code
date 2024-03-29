import { leastCommonMultiple, splitLines } from '@util';
import { Queue } from 'datastructures-js';

// region Types and Globals
const pulses = ['high', 'low'] as const;
type Pulse = typeof pulses[number];
type PulseCounter = Record<Pulse, number>;

interface Package {
  from: string;
  pulse: Pulse;
  to: string;
}

const buttonModuleName = 'button';
const broadcastModuleName = 'broadcaster';

const flipFlopMarker = '%';
const conjunctionMarker = '&';
// endregion

const part1ButtonPushes = 1000;
const logLevel: null | '' | 'v' | 'vv' = '';

export function solvePart1(input: string): number {
  const counter: PulseCounter = { high: 0, low: 0 };
  const modules = parseModules(input);
  const button = new Button();
  modules[buttonModuleName] = button;

  const buttonPushes = part1ButtonPushes;
  let pushCounter = 0;
  while (pushCounter < buttonPushes) {
    if (logLevel === 'vv') {
      console.group(`Button Press #${pushCounter + 1}:`)
    }
    const queue = new Queue<Package>();
    button.push().forEach((signal) => queue.enqueue({from: button.name, ...signal}));
    while (!queue.isEmpty()) {
      const {from, pulse, to} = queue.dequeue();
      counter[pulse]++;
      if (logLevel === 'vv') {
        console.log(from, `-${pulse}->`, to);
      }
      const module = modules[to];
      module.receive(pulse, from);
      module.process().forEach((signal) => queue.enqueue({from: module.name, ...signal}));
    }
    if (logLevel === 'vv') {
      console.groupEnd();
      console.log('Counter:', `low=${counter.low}`, `high=${counter.high}\n`);
    }
    if (logLevel === 'v') {
      console.log(`Button Press #${pushCounter + 1}:`, `low=${counter.low}`, `high=${counter.high}`);
    }
    pushCounter++;
  }

  return counter.low * counter.high;
}

export function solvePart2(input: string): number {
  const modules = parseModules(input);
  const button = new Button();
  modules[buttonModuleName] = button;

  const outputModule = 'rx';
  const outputConjunction = Object.values(modules).find(({destinations}) => destinations.includes(outputModule))?.name;
  if (outputConjunction == null) {
    throw new Error(`Unable to find input of final output module ${outputModule}`);
  }
  // If all feeder send a high, the final output module will receive a low
  const outputConjunctionFeeder = Object.values(modules).filter(({destinations}) => destinations.includes(outputConjunction)).map(({name}) => name);
  // Find cycle length for each feeder and calculate the lcm
  const cycleLengths: Record<string, number> = {};
  const cyclesFound: string[] = [];

  let pushCounter = 0;
  while (cyclesFound.length !== outputConjunctionFeeder.length) {
    const queue = new Queue<Package>();
    button.push().forEach((signal) => queue.enqueue({from: button.name, ...signal}));
    pushCounter++;
    while (!queue.isEmpty()) {
      const {from, pulse, to} = queue.dequeue();
      if (outputConjunctionFeeder.includes(from) && !cyclesFound.includes(from) && pulse === 'high') {
        cycleLengths[from] = pushCounter;
        cyclesFound.push(from);
      }

      const module = modules[to];
      module.receive(pulse, from);
      module.process().forEach((signal) => queue.enqueue({from: module.name, ...signal}));
    }
  }

  return leastCommonMultiple(Object.values(cycleLengths));
}

// region Shared Code
function parseModules(input: string): Record<string, Module> {
  const modules: Record<string, Module> = {};
  for (const line of splitLines(input)) {
    const [moduleDefinition, destinations] = line.split('->').map((v) => v.trim());
    const destinationNames = destinations.split(',').map((s) => s.trim());

    let module: Module;
    if (moduleDefinition[0] === flipFlopMarker) {
      module = new FlipFlop(moduleDefinition.slice(1), destinationNames);
    } else if (moduleDefinition[0] === conjunctionMarker) {
      module = new Conjunction(moduleDefinition.slice(1), destinationNames);
    } else if (moduleDefinition === broadcastModuleName) {
      module = new Broadcast(destinationNames);
    } else {
      throw new Error(`Unable to parse module for line: ${line}`)
    }
    modules[module.name] = module;
  }

  Object.values(modules).forEach((module) => {
    module.destinations.forEach((name) => {
      let destination = modules[name];
      if (!destination) {
        destination = new Receiver(name);
        modules[name] = destination;
      }
      if (destination instanceof Conjunction) {
        destination.initializeIngress(module.name);
      }
    })
  })

  return modules;
}

abstract class Module {

  constructor(
    public readonly name: string,
    public readonly destinations: readonly string[],
  ) {}

  abstract receive(pulse: Pulse, from: string): void;
  abstract getOutput(): Pulse | null;

  process(): {to: string, pulse: Pulse}[] {
    const output = this.getOutput();
    if (output == null) {
      return [];
    }
    return this.destinations.map((to) => ({to, pulse: output}));
  }
}

class Broadcast extends Module {

  protected received: Pulse | null = null;

  constructor(destinationNames: readonly string[]) {
    super(broadcastModuleName, destinationNames);
  }

  receive(pulse: Pulse) {
    this.received = pulse;
  }

  getOutput(): Pulse {
    if (this.received == null) {
      throw new Error(`Invalid state of module ${this.name}: No pulse has been received`)
    }
    return this.received;
  }
}

class FlipFlop extends Module {

  private sendSignal = false;
  private isOn = false;

  constructor(name: string, destinationNames: readonly string[]) {
    super(name, destinationNames);
  }

  receive(pulse: Pulse) {
    if (pulse === 'high') {
      this.sendSignal = false;
    } else {
      this.sendSignal = true;
      this.isOn = !this.isOn;
    }
  }

  getOutput(): Pulse | null {
    if (!this.sendSignal) {
      return null;
    }
    return this.isOn ? 'high' : 'low';
  }
}

class Conjunction extends Module {

  private readonly ingress: Record<string, Pulse> = {};

  constructor(name: string, destinationNames: readonly string[]) {
    super(name, destinationNames);
  }

  initializeIngress(name: string) {
    this.ingress[name] = 'low';
  }

  receive(pulse: Pulse, from: string) {
    this.ingress[from] = pulse;
  }

  getOutput(): Pulse {
    return Object.values(this.ingress).some((p) => p === 'low') ? 'high' : 'low';
  }
}

class Button extends Module {

  constructor() {
    super(buttonModuleName, [broadcastModuleName]);
  }

  push() {
    return this.process();
  }

  receive(): void {
    throw new Error('Button cannot receive signals');
  }
  getOutput(): Pulse {
    return 'low';
  }
}

class Receiver extends Module {

  constructor(name: string) {
    super(name, []);
  }

  receive(): void { }
  getOutput(): Pulse | null {
    return null;
  }
}
// endregion
