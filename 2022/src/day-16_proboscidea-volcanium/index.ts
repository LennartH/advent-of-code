import { splitLines } from '../../../util/util';

interface SimpleNode {
  label: string;
  flowRate: number;
  edges: string[];
}

interface SimpleGraph {
  start: SimpleNode;
  nodes: Record<string, SimpleNode>;
}

export interface Node {
  label: string;
  flowRate: number;
  edges: Record<string, number>;
}

export interface Graph {
  start: Node;
  nodes: Record<string, Node>;
}

const nodePattern = /Valve (?<label>[A-Z]+) has flow rate=(?<rate>\d+); tunnels? leads? to valves? (?<edges>[A-Z, ]+)/;

export function parseGraph(input: string): Graph {
  const lines = splitLines(input);

  const nodes: Record<string, SimpleNode> = {};
  const relevantNodes: SimpleNode[] = [];
  lines.forEach((line) => {
    const match = line.match(nodePattern);
    if (!match || !match.groups) {
      throw new Error(`Unable to parse node from: ${line}`);
    }
    const { label, rate, edges } = match.groups;
    const node: SimpleNode = {
      label,
      flowRate: Number(rate),
      edges: edges.split(', '),
    };
    if (node.flowRate > 0 || node.label === 'AA') {
      relevantNodes.push(node);
    }
    nodes[label] = node;
  });

  if (!nodes['AA']) {
    throw new Error('Starting node could not be found');
  }
  const simpleGraph: SimpleGraph = { start: nodes['AA'], nodes };

  const traveledNodes: Record<string, Node> = Object.fromEntries(
    relevantNodes.map((from) => [from.label, {
      label: from.label,
      flowRate: from.flowRate,
      edges: Object.fromEntries(relevantNodes
        .filter((n) => from !== n)
        .map((to) => [to.label, searchPathTo(simpleGraph, from, to).cost])
      )
    }])
  );
  return {
    start: traveledNodes['AA'],
    nodes: traveledNodes,
  };
}

export function releasePressure(graph: Graph, time: number): number {
  let releasedPressure = 0;
  for (const route of collectPossiblePaths(graph, time)) {
    let routePressure = 0;
    let timeLeft = time;
    let current = graph.start;
    while (route.length > 0 && timeLeft > 0) {
      const next = route.shift()!;
      const cost = costToOpenValve(graph, current, next);
      timeLeft = timeLeft - cost;
      if (timeLeft < 0) {
        break;
      }
      current = next;
      routePressure += timeLeft * current.flowRate;
    }
    releasedPressure = Math.max(releasedPressure, routePressure);
  }
  return releasedPressure;
}

export function collectPossiblePaths(graph: Graph, time: number): Node[][] {
  const paths: Node[][] = [];
  let openPaths: PathCandidate[] = [
    {
      nodes: [graph.start],
      remainingNodes: Object.values(graph.nodes).filter((n) => n !== graph.start && costToOpenValve(graph, graph.start, n) < time),
      totalCost: 0,
    },
  ];
  while (openPaths.length > 0) {
    const { nodes, remainingNodes, totalCost } = openPaths.shift()!;
    const current = nodes[nodes.length - 1];
    if (remainingNodes.length === 0) {
      paths.push(nodes);
      continue;
    }
    let continued = false;
    for (const next of remainingNodes) {
      const cost = costToOpenValve(graph, current, next);
      if (totalCost + cost < time) {
        openPaths.push({
          nodes: [...nodes, next],
          remainingNodes: remainingNodes.filter((n) => n !== next),
          totalCost: totalCost + cost,
        });
        continued = true;
      }
    }
    if (!continued) {
      paths.push(nodes);
    }
  }
  return paths.map((p) => p.slice(1));
}

interface PathCandidate {
  nodes: Node[];
  remainingNodes: Node[];
  totalCost: number;
}

function costToOpenValve(graph: Graph, from: Node, to: Node): number {
  return graph.nodes[from.label].edges[to.label] + 1;
}

function searchPathTo(graph: SimpleGraph, from: SimpleNode, to: SimpleNode): VisitedNode {
  const openNodes: VisitedNode[] = [];
  const visited = new Set<string>();

  openNodes.push({
    label: from.label,
    cost: 0,
    predecessors: [],
  });
  do {
    const current = openNodes.pop()!;
    const { label, cost, predecessors } = current;
    visited.add(label);
    if (label === to.label) {
      return current;
    }

    const neighbours = graph.nodes[label].edges;
    for (const neighbour of neighbours) {
      if (!visited.has(neighbour)) {
        const index = openNodes.findIndex((n) => n.label === neighbour);
        const next: VisitedNode = {
          label: neighbour,
          cost: cost + 1,
          predecessors: [...predecessors, label],
        };
        if (index === -1) {
          openNodes.push(next);
        } else if (next.cost < openNodes[index].cost) {
          openNodes[index] = next;
        }
      }
    }
    openNodes.sort((a, b) => b.cost - a.cost);
  } while (openNodes.length > 0);

  throw new Error(`No path could be found from ${from.label} to ${to.label}`);
}

interface VisitedNode {
  label: string;
  cost: number;
  predecessors: string[];
}
