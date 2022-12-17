import { splitLines } from '../../../util/util';

export interface Node {
  id: number;
  label: string;
  flowRate: number;
}

export interface Graph {
  start: Node;
  nodes: Node[];
  edges: number[][];
}

const nodePattern = /Valve (?<label>[A-Z]+) has flow rate=(?<rate>\d+); tunnels? leads? to valves? (?<edges>[A-Z, ]+)/;

export function parseGraph(input: string): Graph {
  const lines = splitLines(input);

  let start: Node | undefined = undefined;
  const nodes: Node[] = [];
  const edgesById: string[][] = new Array(lines.length).fill(0).map(() => []);
  lines.forEach((line, index) => {
    const match = line.match(nodePattern);
    if (!match || !match.groups) {
      throw new Error(`Unable to parse node from: ${line}`);
    }
    const { label, rate, edges } = match.groups;
    const node = {id: index, label, flowRate: Number(rate)};
    if (node.label === 'AA') {
      start = node;
    }
    nodes.push(node);
    edgesById[index] = edges.split(', ');
  });

  if (!start) {
    throw new Error('Starting node could not be found');
  }
  const edges: number[][] = edgesById.map((edgesFrom) => edgesFrom.map((label) => nodes.find((n) => n.label === label)!.id));
  return { start, nodes, edges };
}

export function releasePressure(graph: Graph, time: number): number {
  let releasedPressure = 0;
  let current = graph.start;
  let candidates: Node[] = graph.nodes.filter((n) => n.flowRate > 0);
  while (time > 0 && candidates.length > 0) {
    const candidatesWithScore = candidates
      .map((node) => [node, costToOpenValve(graph, current, node)] as [Node, number])
      .filter(([_, cost]) => cost < time)
      .map(([node, cost]) => [node, cost, (time - cost) * node.flowRate] as [Node, number, number]);
    if (candidatesWithScore.length === 0) {
      break;
    }
    candidatesWithScore.sort((candidate1, candidate2) => {
      const [, cost1, pressure1] = candidate1;
      const [, cost2, pressure2] = candidate2;
      const efficiency1 = pressure1 / cost1;
      const efficiency2 = pressure2 / cost2;
      return efficiency2 - efficiency1;
    });
    const [next, cost, pressure] = candidatesWithScore[0];
    current = next;
    time = time - cost;
    releasedPressure += pressure;
    candidates = candidates.filter((c) => c.label !== next.label);
  }
  return releasedPressure;
}

function costToOpenValve(graph: Graph, from: Node, to: Node): number {
  const { cost } = searchPathTo(graph, from, to);
  return cost;
}

function searchPathTo(graph: Graph, from: Node, to: Node): VisitedNode {
  const { nodes, edges } = graph;
  const openNodes: VisitedNode[] = [];
  const visited = new Set<string>();

  let finalNode: VisitedNode | undefined = undefined;
  openNodes.push({
    node: from,
    cost: 1,
    predecessor: null,
  });
  do {
    const node = openNodes.pop()!;
    visited.add(node.node.label);
    if (node.node.label === to.label) {
      finalNode = node;
      break;
    }

    const neighbours = edges[node.node.id].map((i) => nodes[i]);
    for (const neighbour of neighbours) {
      if (!visited.has(neighbour.label)) {
        const index = openNodes.findIndex((n) => n.node.label === neighbour.label);
        const successorNode: VisitedNode = {
          node: neighbour,
          cost: node.cost + 1,
          predecessor: node,
        }
        if (index === -1) {
          openNodes.push(successorNode);
        } else if (node.cost + 1 < openNodes[index].cost) {
          openNodes[index] = successorNode;
        }
      }
    }
    openNodes.sort((a, b) => a.cost - b.cost);
  } while (openNodes.length > 0);

  if (finalNode == null) {
    throw new Error(`No path could be found from ${from.label} to ${to.label}`);
  }
  return finalNode;
}

interface VisitedNode {
  node: Node;
  cost: number;
  predecessor: VisitedNode | null;
}
