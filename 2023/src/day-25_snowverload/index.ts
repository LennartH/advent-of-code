import { splitLines } from '@util';

// region Types and Globals
interface Graph {
  nodes: string[];
  edges: Edge[];
}

interface Edge {
  key: string;
  a: string;
  b: string;
}
// endregion

export function solvePart1(input: string): number {
  const graph = parseGraph(input);
  // Something like a Girwan-Newman algorithm (https://en.wikipedia.org/wiki/Girvan%E2%80%93Newman_algorithm),
  // but simplified because we know what the Input looks like

  // Count the number of shortest paths that use an edge
  const {tree} = allShortestPaths(graph);
  const edgeBetweennes: Record<string, number> = Object.fromEntries(graph.edges.map(({key}) => [key, 0]))
  for (const steps of tree.values()) {
    for (const [to, from] of steps.entries()) {
      if (to === from) {
        continue;
      }
      const edgeKey = `${from}--${to}` in edgeBetweennes ? `${from}--${to}` : `${to}--${from}`;
      edgeBetweennes[edgeKey]++;
    }
  }

  const edgesToRemove = Object.entries(edgeBetweennes)
      .sort(([_, a], [__, b]) => b - a)
      .map(([k, v]) => k)
      .slice(0, 4); // 4 instead of 3 to be safe
  graph.edges = graph.edges.filter(({key}) => !edgesToRemove.includes(key));

  const adjacency: Record<string, string[]> = Object.fromEntries(graph.nodes.map((n) => [n, []]));
  for (const {a, b} of graph.edges) {
    adjacency[a].push(b);
    adjacency[b].push(a);
  }

  const visited = new Set<string>();
  const open: string[] = [graph.nodes[0]];

  // Count first group using DFS
  let count1 = 0;
  while (open.length > 0) {
    const node = open.pop()!;
    if (visited.has(node)) {
      continue;
    }
    count1++;
    visited.add(node);

    for (const next of adjacency[node]) {
      if (visited.has(next)) {
        continue;
      }
      open.push(next);
    }
  }

  if (visited.size === graph.nodes.length) {
    throw new Error('Graph is not separated');
  }

  // Count group 2 using DFS
  open.push(graph.nodes.find((n) => !visited.has(n))!);
  let count2 = 0;
  while (open.length > 0) {
    const node = open.pop()!;
    if (visited.has(node)) {
      continue;
    }
    count2++;
    visited.add(node);

    for (const next of adjacency[node]) {
      if (visited.has(next)) {
        continue;
      }
      open.push(next);
    }
  }

  if (count1 + count2 !== graph.nodes.length) {
    throw new Error('Some nodes have been isolated');
  }

  return count1 * count2;
}

export function solvePart2(input: string): number {
  const lines = splitLines(input);
  // TODO Implement solution
  return Number.NaN;
}

// region Shared Code
function parseGraph(input: string): Graph {
  const nodes = new Set<string>();
  const edges: Edge[] = [];

  for (const line of splitLines(input)) {
    const [from, to] = line.split(': ');
    const toNodes = to.split(' ');

    nodes.add(from);
    for (const node of toNodes) {
      nodes.add(node);
      edges.push({ key: `${from}--${node}`, a: from, b: node });
    }
  }

  return { nodes: [...nodes], edges };
}

// Floyd-Warshall: https://en.wikipedia.org/wiki/Floyd%E2%80%93Warshall_algorithm
function allShortestPaths({ nodes, edges }: Graph): {
  distance: Map<string, Map<string, number>>,
  tree: Map<string, Map<string, string>>
} {
  const distance = new Map<string, Map<string, number>>();
  const tree = new Map<string, Map<string, string>>();
  for (const a of nodes) {
    distance.set(a, new Map<string, number>());
    tree.set(a, new Map<string, string>());
    for (const b of nodes) {
      distance.get(a)!.set(b, a === b ? 0 : Infinity);
      tree.get(a)!.set(b, a === b ? a : null as never);
    }
  }
  for (const {a, b} of edges) {
    distance.get(a)!.set(b, 1);
    distance.get(b)!.set(a, 1);
    tree.get(a)!.set(b, a);
    tree.get(b)!.set(a, b);
  }

  for (const k of nodes) {
    for (const i of nodes) {
      for (const j of nodes) {
        const currentBest = distance.get(i)!.get(j)!;
        const distanceOverK = distance.get(i)!.get(k)! + distance.get(k)!.get(j)!;
        if (currentBest > distanceOverK) {
          distance.get(i)!.set(j, distanceOverK);
          tree.get(i)!.set(j, tree.get(k)!.get(j)!);
        }
      }
    }
  }

  return {distance, tree};
}
// endregion
