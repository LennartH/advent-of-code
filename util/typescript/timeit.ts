export interface TimeitConfig {
  count?: number;
  beforeAll?: () => void;
  beforeEach?: () => void;
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
const noopFunction = () => {};
const defaultTimer = performance.now;

export function timeit(snippet: Snippet, config?: TimeitConfig): TimeitResult
export function timeit(name: string, snippet: Snippet, config?: TimeitConfig): TimeitResult
export function timeit(nameOrSnippet: string | Snippet, snippetOrConfig?: Snippet | TimeitConfig, maybeConfig?: TimeitConfig): TimeitResult {
  let name: string | undefined;
  let snippet: Snippet;
  let partialConfig: TimeitConfig | undefined;
  if (typeof nameOrSnippet === 'string') {
    name = nameOrSnippet;
    snippet = snippetOrConfig as Snippet;
    partialConfig = maybeConfig;
  } else {
    snippet = nameOrSnippet as Snippet;
    partialConfig = snippetOrConfig as TimeitConfig;
  }

  const { count, beforeAll, beforeEach, timer, args } = getConfig(partialConfig);

  const results: number[] = [];
  let total = 0;
  let average = 0;
  let median: number;

  beforeAll();
  for (let i = 0; i < count; i++) {
    beforeEach();
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

type Snippet = (...args: unknown[]) => unknown;
type InternalConfig = Required<TimeitConfig>;

function getConfig(config?: TimeitConfig): InternalConfig {
  const count = config?.count || defaultCount;
  const beforeAll = config?.beforeAll || noopFunction;
  const beforeEach = config?.beforeEach || noopFunction;
  const timer = config?.timer || defaultTimer;
  const args = config?.args || [];
  return {
    count,
    beforeAll,
    beforeEach,
    timer,
    args,
  }
}
