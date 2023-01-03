import { splitLines } from '@util';

export interface MonkeyEquations {
  variables: Record<string, number>;
  openEquations: Equation[];
}

export interface Equation {
  name: string;
  variables: [string, string];
  operator: '+' | '-' | '*' | '/';
}

const equationPattern = /(?<v1>[a-z]+) (?<op>[+-/*]) (?<v2>[a-z]+)/;

export function parseEquations(input: string): MonkeyEquations {
  const variables: Record<string, number> = {};
  const openEquations: Equation[] = [];
  for (const line of splitLines(input)) {
    const [name, rest] = line.split(': ');
    const equation = rest.match(equationPattern);
    if (equation == null) {
      variables[name] = Number(rest);
    } else {
      const { v1, op, v2 } = equation.groups!;
      openEquations.push({name, variables: [v1, v2], operator: op as never});
    }
  }
  return {variables, openEquations}
}

export function solveEquations(equations: MonkeyEquations): number {
  const { variables, openEquations } = equations;
  while (!variables.root) {
    for (let i = 0; i < openEquations.length; i++) {
      const { name, variables: [v1, v2] } = openEquations[i];
      if (v1 in variables && v2 in variables) {
        variables[name] = calculateEquation(openEquations[i], variables);
        openEquations.splice(i, 1);
        i--;
      }
    }
  }
  return variables.root;
}

export function solveEquality(equations: MonkeyEquations): number {
  const { variables, openEquations } = equations;
  delete variables.humn;
  const [{ variables: [root1, root2] }] = openEquations.splice(openEquations.findIndex((e) => e.name === 'root'), 1);

  let solvedEquation: boolean;
  do {
    solvedEquation = false
    for (let i = 0; i < openEquations.length; i++) {
      const { name, variables: [v1, v2] } = openEquations[i];
      if (v1 in variables && v2 in variables) {
        variables[name] = calculateEquation(openEquations[i], variables);
        openEquations.splice(i, 1);
        i--;
        solvedEquation = true;
      }
    }
  } while (solvedEquation);

  const openEquationsByName: Record<string, Equation> = Object.fromEntries(
    openEquations.map((e) => [e.name, e])
  );
  return solveEqualityFor(
    openEquationsByName[root1] || openEquationsByName[root2],
    variables,
    openEquationsByName,
    variables[root1] || variables[root2],
  )
}

function solveEqualityFor(equation: Equation, variables: Record<string, number>, equations: Record<string, Equation>, expected: number): number {
  const { variables: [v1, v2], operator } = equation;
  const value = variables[v1] || variables[v2];

  let solution: number;
  switch (operator) {
    case '+':
      solution = expected - value;
      break;
    case '-':
      const sign = variables[v1] ? -1 : 1;
      solution = (sign * expected) + value;
      break;
    case '*':
      solution = expected / value;
      break;
    case '/':
      if (variables[v1]) {
        solution = value / expected;
      } else {
        solution = value * expected;
      }
      break;
    default:
      throw new Error(`Unknown operator ${operator}`)
  }

  const nextEquation = equations[v1] || equations[v2];
  if (nextEquation) {
    return solveEqualityFor(nextEquation, variables, equations, solution);
  } else {
    return solution;
  }
}

function calculateEquation(equation: Equation, variables: Record<string, number>): number {
  const { variables: [v1, v2], operator } = equation;
  const value1 = variables[v1];
  const value2 = variables[v2];
  if (value1 == null || value2 == null) {
    throw new Error(`Variables ${v1} and/or ${v2} are not resolved yet`);
  }

  switch (operator) {
    case '+':
      return value1 + value2;
    case '-':
      return value1 - value2;
    case '*':
      return value1 * value2;
    case '/':
      return value1 / value2;
    default:
      throw new Error(`Unknown operator ${operator}`)
  }
}
