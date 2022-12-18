import { splitLines } from '@util';

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

export function releasePressure(graph: Graph, time: number, actors: number): number {
  if (actors === 1) {
    let releasedPressure = 0;
    for (const { releasedPressure: routePressure } of collectPossiblePaths(graph, time)) {
      releasedPressure = Math.max(releasedPressure, routePressure);
    }
    return releasedPressure;
  } else if (actors === 2) {
    const paths = [...collectPossiblePaths(graph, time)];
    let releasedPressure = 0;
    for (const path of paths) {
      for (const other of paths) {
        if (path === other || path.releasedPressure + other.releasedPressure < releasedPressure) {
          continue;
        }
        const hasOverlap = path.nodes.some((n1) => other.nodes.some((n2) => n1.label === n2.label));
        if (hasOverlap) {
          continue;
        }
        releasedPressure = Math.max(releasedPressure, path.releasedPressure + other.releasedPressure);
      }
    }
    return releasedPressure;
  }
  throw new Error(`Not implemented for ${actors} actors`);
}

export function* collectPossiblePaths(graph: Graph, time: number): Generator<Path> {
  let openPaths: PathCandidate[] = [
    {
      nodes: [graph.start],
      remainingNodes: Object.values(graph.nodes).filter((n) => n !== graph.start && costToOpenValve(graph, graph.start, n) < time),
      releasedPressure: 0,
      totalCost: 0,
    },
  ];
  while (openPaths.length > 0) {
    const { nodes, remainingNodes, totalCost, releasedPressure } = openPaths.shift()!;
    const current = nodes[nodes.length - 1];
    if (remainingNodes.length === 0) {
      yield {
        nodes: nodes.slice(1),
        releasedPressure,
      }
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
          releasedPressure: releasedPressure + (time - totalCost - cost) * next.flowRate,
        });
        continued = true;
      }
    }
    if (!continued) {
      yield {
        nodes: nodes.slice(1),
        releasedPressure,
      }
    }
  }
}

interface Path {
  nodes: Node[];
  releasedPressure: number;
}

interface PathCandidate {
  nodes: Node[];
  remainingNodes: Node[];
  totalCost: number;
  releasedPressure: number;
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
