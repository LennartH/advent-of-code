export interface TimeitConfig {
  name?: string;
  count?: number;
  setup?: () => void;
  timer?: () => number;
  args?: unknown[];
}

export interface TimeitResult {
  name?: string;

  count: number;
  total: number;
  average: number;
  median: number;
}

const defaultCount = 1000000;
const defaultSetup = () => {};
const defaultTimer = performance.now;

export function timeit(snippet: (...args: unknown[]) => unknown, config?: TimeitConfig): TimeitResult {
  const { name, count, setup, timer, args } = getConfig(config);

  const results: number[] = [];
  let total = 0;
  let average = 0;
  let median: number;

  setup();
  for (let i = 0; i < count; i++) {
    const start = timer();
    snippet(...args);
    const end = timer();
    const duration = end - start;
    results.push(duration);
    total += duration;
    average += duration / count;
  }

  results.sort((a, b) => a - b);
  if (results.length % 2 === 0) {
    median = results[results.length / 2];
  } else {
    const i1 = Math.floor(results.length / 2);
    const i2 = Math.ceil(results.length / 2);
    median = (results[i1] + results[i2]) / 2;
  }

  return { name, count, total, average, median };
}

type OptionalConfigProperties = 'name';
type InternalConfig = Required<Omit<TimeitConfig, OptionalConfigProperties>> & Pick<TimeitConfig, OptionalConfigProperties>;

function getConfig(config?: TimeitConfig): InternalConfig {
  const count = config?.count || defaultCount;
  const setup = config?.setup || defaultSetup;
  const timer = config?.timer || defaultTimer;
  const args = config?.args || [];
  return {
    name: config?.name,
    count,
    setup,
    timer,
    args,
  }
}
