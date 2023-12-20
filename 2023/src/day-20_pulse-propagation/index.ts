import { splitLines } from '@util';
import { Queue } from 'datastructures-js';

// region Types and Globals
const pulses = ['high', 'low'] as const;
type Pulse = typeof pulses[number];
type PulseCounter = Record<Pulse, number>;

const buttonModuleName = 'button';
const broadcastModuleName = 'broadcaster';

const flipFlopMarker = '%';
const conjunctionMarker = '&';
// endregion

// const part1ButtonPushs = 1;
// const logLevel: 'v' | 'vv' | null = 'vv';
const part1ButtonPushs = 1000;
const logLevel: 'v' | 'vv' | null = null;

export function solvePart1(input: string): number {
  const counter: PulseCounter = { high: 0, low: 0 };
  const modules = parseModules(input, counter);
  const button = new Button(counter);
  modules[buttonModuleName] = button;
  Object.values(modules).forEach((m) => m.initialize(modules));

  const buttonPushs = part1ButtonPushs;
  let pressCounter = 0;
  while (pressCounter < buttonPushs) {
    if (logLevel === 'vv') {
      console.group(`Button Press #${pressCounter + 1}:`)
    }
    button.press();
    const queue = new Queue<Module>();
    button.destinations.forEach((m) => queue.enqueue(m));
    while (!queue.isEmpty()) {
      const module = queue.dequeue();
      if (!module.needsProcessing) {
        continue;
      }
      module.process();
      module.destinations.forEach((m) => queue.enqueue(m));
    }
    if (logLevel === 'vv') {
      console.groupEnd();
      console.log('Counter:', `low=${counter.low}`, `high=${counter.high}\n`);
    }
    if (logLevel === 'v') {
      console.log(`Button Press #${pressCounter + 1}:`, `low=${counter.low}`, `high=${counter.high}`);
    }
    pressCounter++;
  }

  return counter.low * counter.high;
}

export function solvePart2(input: string): number {
  const lines = splitLines(input);
  // TODO Implement solution
  return Number.NaN;
}

// region Shared Code
function parseModules(input: string, counter: PulseCounter): Record<string, Module> {
  const modules: Record<string, Module> = {};
  for (const line of splitLines(input)) {
    const [moduleDefinition, destinations] = line.split('->').map((v) => v.trim());
    const destinationNames = destinations.split(',').map((s) => s.trim());

    let module: Module;
    if (moduleDefinition[0] === flipFlopMarker) {
      module = new FlipFlop(moduleDefinition.slice(1), destinationNames, counter);
    } else if (moduleDefinition[0] === conjunctionMarker) {
      module = new Conjunction(moduleDefinition.slice(1), destinationNames, counter);
    } else if (moduleDefinition === broadcastModuleName) {
      module = new Broadcast(destinationNames, counter);
    } else {
      throw new Error(`Unable to parse module for line: ${line}`)
    }
    modules[module.name] = module;
  }
  return modules;
}

abstract class Module {

  public readonly destinations: Module[] = [];

  constructor(
    public readonly name: string,
    private readonly destinationNames: readonly string[],
    private readonly counter: PulseCounter,
  ) {}

  initialize(modules: Record<string, Module>) {
    this.destinationNames.forEach((name) => {
      let module = modules[name];
      if (!module) {
        module = new Receiver(name, this.counter);
      }
      this.destinations.push(module);
      if (module instanceof Conjunction) {
        module.initializeIngress(this.name);
      }
    })
  }

  abstract get needsProcessing(): boolean;
  abstract receive(pulse: Pulse, from: string): void;
  abstract getOutput(): Pulse;

  process(): void {
    if (!this.needsProcessing) {
      throw new Error(`Invalid state of module ${this.name}: No processing necessary`);
    }

    const output = this.getOutput();
    for (const destination of this.destinations) {
      if (logLevel === 'vv') {
        console.log(this.name, `-${output}->`, destination.name);
      }
      this.counter[output]++;
      destination.receive(output, this.name);
    }
    this.finishedTransmitting();
  }

  protected abstract finishedTransmitting(): void;
}

abstract class SingleInputModule extends Module {

  protected received: Pulse | null = null;
  get needsProcessing(): boolean {
    return this.received != null;
  }

  receive(pulse: Pulse) {
    this.received = pulse;
  }

  protected finishedTransmitting() {
    this.received = null;
  }
}

class Broadcast extends SingleInputModule {
  constructor(destinationNames: readonly string[], counter: PulseCounter) {
    super(broadcastModuleName, destinationNames, counter);
  }

  getOutput(): Pulse {
    if (this.received == null) {
      throw new Error(`Invalid state of module ${this.name}: No pulse has been received`)
    }
    return this.received;
  }
}

class FlipFlop extends SingleInputModule {

  private isOn: boolean = false;

  constructor(name: string, destinationNames: readonly string[], counter: PulseCounter) {
    super(name, destinationNames, counter);
  }

  receive(pulse: Pulse) {
    if (pulse === 'high') {
      return;
    }
    this.isOn = !this.isOn;
    super.receive(pulse);
  }

  getOutput(): Pulse {
    return this.isOn ? 'high' : 'low';
  }
}

class Conjunction extends Module {

  private readonly ingress: Record<string, Pulse> = {};

  private receivedPulse = false;
  get needsProcessing(): boolean {
    return true;
  }

  constructor(name: string, destinationNames: readonly string[], counter: PulseCounter) {
    super(name, destinationNames, counter);
  }

  initializeIngress(name: string) {
    this.ingress[name] = 'low';
  }

  receive(pulse: Pulse, from: string) {
    this.ingress[from] = pulse;
    this.receivedPulse = true;
  }

  getOutput(): Pulse {
    return Object.values(this.ingress).some((p) => p === 'low') ? 'high' : 'low';
  }

  protected finishedTransmitting() {
    this.receivedPulse = false;
  }
}

class Button extends Module {

  public canBePressed: boolean = true;
  get needsProcessing(): boolean {
    return this.canBePressed;
  }

  constructor(counter: PulseCounter) {
    super(buttonModuleName, [broadcastModuleName], counter);
  }

  press() {
    this.canBePressed = true;
    return this.process();
  }

  receive(): void {
    throw new Error('Button cannot receive signals');
  }
  getOutput(): Pulse {
    return 'low';
  }
  protected finishedTransmitting(): void {
    this.canBePressed = false;
  }
}

class Receiver extends Module {

  get needsProcessing(): boolean {
    return false;
  }

  constructor(name: string, counter: PulseCounter) {
    super(name, [], counter);
  }

  receive(): void { }
  getOutput(): Pulse {
    throw new Error('Method not implemented.');
  }
  protected finishedTransmitting(): void {
    throw new Error('Method not implemented.');
  }
}
// endregion
