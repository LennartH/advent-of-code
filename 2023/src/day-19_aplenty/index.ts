import { groupBy, splitLines, sum } from '@util';

// TODO Use Sankey Diagram: https://www.reddit.com/r/adventofcode/comments/18lyvuv/2023_day_19_part_2_sankey_diagrams_are_cool/
// Additional info (k-d tree): https://www.reddit.com/r/adventofcode/comments/18lwcw2/2023_day_19_an_equivalent_part_2_example_spoilers/

// region Types and Globals
interface Part {
  x: number;
  m: number;
  a: number;
  s: number;
}

type Graph = Record<string, Edge[]>;

type Operator = '<' | '<=' | '>' | '>=';
// TODO Unify types !('key' in edge) everywhere is pretty annoying
type Edge =
  { to: string } |
  {
    key: keyof Part;
    operator: Operator;
    threshold: number;
    to: string;
  };

const start = 'in';
const accepted = 'A';
const rejected = 'R';
// endregion

export function solvePart1(input: string): number {
  const [workflowsText, partsText] = input.split(/\n\s*\n/);
  const graph = parseWorkflows(workflowsText);
  const parts = parseParts(partsText);
  return parts
    .filter((p) => isAccepted(p, graph))
    .map(({x, m, a, s}) => x + m + a + s)
    .reduce(sum);
}

export function solvePart2(input: string): number {
  const [workflowsText] = input.split(/\n\s*\n/);
  const graph = parseWorkflows(workflowsText);
  return findPathsToAccepted(graph)
    .map(calculatePossibleCombinationsForPath)
    .reduce(sum);
}

// region Shared Code
function parseWorkflows(text: string): Graph {
  return Object.fromEntries<Edge[]>(splitLines(text).map((line) => {
    const [name, rest] = line.split('{');
    const rules = rest.slice(0, -1).split(',');
    const fallback = rules.at(-1)!;
    return [name, [
      ...rules.slice(0, -1).map(parseRule),
      { to: fallback },
    ]];
  }));
}

function parseRule(text: string): Edge {
  const [condition, to] = text.split(':');
  const key = condition[0] as keyof Part;
  const operator = condition[1] as ('<' | '>');
  const threshold = Number(condition.slice(2));
  return {
    key,
    operator,
    threshold,
    to,
  }
}

function parseParts(text: string): Part[] {
  return splitLines(text).map((line) => Object.fromEntries(
    line.slice(1, -1).split(',').map((p) => {
      const [key, value] = p.split('=');
      return [key, Number(value)];
    })
  ) as never);
}

function isAccepted(part: Part, graph: Graph): boolean {
  let current = start;
  while (current in graph) {
    const edge = graph[current].find((e) => edgeAccepts(e, part));
    if (edge == null) {
      throw new Error(`Invalid edge in node ${current}: ${JSON.stringify(edge)}`);
    }
    current = edge.to;
  }
  if (current !== accepted && current !== rejected) {
    throw new Error(`Unable to process part ${JSON.stringify(part)}`);
  }
  return current === accepted;
}

function edgeAccepts(edge: Edge, part: Part): boolean {
  if (!('key' in edge)) {
    // Default rule
    return true;
  }
  const {key, operator, threshold} = edge;
  switch (operator) {
    case "<":
      return part[key] < threshold;
    case "<=":
      return part[key] <= threshold;
    case ">":
      return part[key] > threshold;
    case ">=":
      return part[key] >= threshold;
  }
}

interface OpenNode {
  name: string;
  edge?: Edge;
  previousEdges?: Edge[];
  predecessor?: OpenNode;
}

function findPathsToAccepted(graph: Graph): Edge[][] {
  const paths: Edge[][] = [];

  const visited = new Set<string>();
  const open: OpenNode[] = [{ name: start }];
  while (open.length > 0) {
    let current = open.pop()!;
    if (current.name === rejected) {
      continue;
    }
    if (current.name === accepted) {
      const path: Edge[] = [];
      while (current.predecessor != null) {
        path.push(current.edge!);
        current.previousEdges?.forEach((edge, i) => {
          path.push({...edge, operator: invertEdgeOperator(edge), to: current.name + "`".repeat(i + 1)});
        });
        current = current.predecessor;
      }
      paths.push(path.reverse());
      continue;
    }
    visited.add(current.name);

    const previousEdges: Edge[] = [];
    for (const edge of graph[current.name]) {
      if (visited.has(edge.to)) {
        continue;
      }
      open.push({name: edge.to, edge, previousEdges: [...previousEdges], predecessor: current});
      previousEdges.push(edge);
    }
  }

  return paths;
}

function invertEdgeOperator(edge: Edge): Operator {
  if (!('key' in edge)) {
    throw new Error('Unable to invert operator of default edge');
  }
  if (edge.operator === '<') {
    return '>=';
  }
  if (edge.operator === '>') {
    return '<=';
  }
  throw new Error('Not implemented');
}

function calculatePossibleCombinationsForPath(path: Edge[]): number {
  const conditionsByKey = groupBy(path.filter((e) => 'key' in e), 'key' as never);
  return (['x', 'm', 'a', 's'] as (keyof Part)[]).map((key) => {
    const conditions = conditionsByKey[key];
    if (conditions == null) {
      return 4000;
    }
    let count = 0;
    for (let value = 1; value <= 4000; value++) {
      const part: Part = { x: 0, m: 0, a: 0, s: 0 };
      part[key] = value;
      if (conditions.every((edge) => edgeAccepts(edge, part))) {
        count++;
      }
    }
    return count;
  }).reduce((s, v) => s * v, 1);
}
// endregion
