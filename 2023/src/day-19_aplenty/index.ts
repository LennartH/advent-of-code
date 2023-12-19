import { splitLines, sum } from '@util';

// region Types and Globals
interface Part {
  x: number;
  m: number;
  a: number;
  s: number;
}

interface Workflow {
  name: string;
  rules: Rule[];
  fallback: string;
}

interface Rule {
  predicate: (part: Part) => boolean;
  next: string;
}

const start = 'in';
const accepted = 'A';
const rejected = 'R';
// endregion

export function solvePart1(input: string): number {
  const [workflowsText, partsText] = input.split(/\n\s*\n/);
  const workflows = parseWorkflows(workflowsText);
  const parts = parseParts(partsText);
  return parts
    .filter((p) => isAccepted(p, workflows))
    .map(({x, m, a, s}) => x + m + a + s)
    .reduce(sum);
}

export function solvePart2(input: string): number {
  const lines = splitLines(input);
  // TODO Implement solution
  return Number.NaN;
}

// region Shared Code
function parseWorkflows(text: string): Record<string, Workflow> {
  return Object.fromEntries<Workflow>(splitLines(text)
    .map((line) => {
      const [name, rest] = line.split('{');
      const rules = rest.slice(0, -1).split(',');
      const fallback = rules.at(-1)!;
      return [
        name,
        {
          name,
          rules: rules.slice(0, -1).map(parseRule),
          fallback,
        }
      ];
    })
  );
}

function parseRule(text: string): Rule {
  const [condition, next] = text.split(':');
  const key = condition[0] as keyof Part;
  const operator = condition[1] as ('<' | '>');
  const threshold = Number(condition.slice(2));
  const predicate = operator === '>' ? (p: Part) => p[key] > threshold : (p: Part) => p[key] < threshold;
  return { predicate, next }
}

function parseParts(text: string): Part[] {
  return splitLines(text).map((line) => Object.fromEntries(
    line.slice(1, -1).split(',').map((p) => {
      const [key, value] = p.split('=');
      return [key, Number(value)];
    })
  ) as never);
}

function isAccepted(part: Part, workflows: Record<string, Workflow>): boolean {
  let current = start;
  while (current in workflows) {
    const workflow = workflows[current];
    current = workflow.rules.find((r) => r.predicate(part))?.next || workflow.fallback;
  }
  if (current !== accepted && current !== rejected) {
    throw new Error(`Unable to process part ${JSON.stringify(part)}`);
  }
  return current === accepted;
}
// endregion
