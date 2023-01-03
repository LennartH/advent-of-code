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

function calculateEquation(equation: Equation, variables: Record<string, number>): number {
  const { variables: [variable1, variable2 ], operator } = equation;
  const value1 = variables[variable1];
  const value2 = variables[variable2];
  if (value1 == null || value2 == null) {
    throw new Error(`Variables ${variable1} and/or ${variable2} are not resolved yet`);
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
