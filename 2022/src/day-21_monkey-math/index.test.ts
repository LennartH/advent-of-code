import { readFile } from '@util';
import { parseEquations, solveEquality, solveEquations } from './index';

describe('Day 21', () => {
  describe('example input', () => {
    const input = `
      root: pppw + sjmn
      dbpl: 5
      cczh: sllz + lgvd
      zczc: 2
      ptdq: humn - dvpt
      dvpt: 3
      lfqf: 4
      humn: 5
      ljgn: 2
      sjmn: drzm * dbpl
      sllz: 4
      pppw: cczh / lfqf
      lgvd: ljgn * ptdq
      drzm: hmdt - zczc
      hmdt: 32
    `;

    test('solution is 152 for part 1', () => {
      const equations = parseEquations(input);
      const result = solveEquations(equations);
      expect(result).toEqual(152);
    });
    test('solution is 301 for part 2', () => {
      const equations = parseEquations(input);
      const result = solveEquality(equations);
      expect(result).toEqual(301);
    });
    describe('operand order matters', () => {
      test('swap subtraction order', () => {
        const equations = parseEquations(input);
        const equation = equations.openEquations.find((e) => e.name === 'ptdq')!;
        equation.variables = [equation.variables[1], equation.variables[0]];
        const result = solveEquality(equations);
        expect(result).toEqual(-295);
      })
      test('swap addition order', () => {
        const equations = parseEquations(input);
        const equation = equations.openEquations.find((e) => e.name === 'cczh')!;
        equation.variables = [equation.variables[1], equation.variables[0]];
        const result = solveEquality(equations);
        expect(result).toEqual(301);
      })
      test('swap multiplication order', () => {
        const equations = parseEquations(input);
        const equation = equations.openEquations.find((e) => e.name === 'lgvd')!;
        equation.variables = [equation.variables[1], equation.variables[0]];
        const result = solveEquality(equations);
        expect(result).toEqual(301);
      })
      test('swap division order', () => {
        const equations = parseEquations(input);
        const equation = equations.openEquations.find((e) => e.name === 'pppw')!;
        equation.variables = [equation.variables[1], equation.variables[0]];
        const result = solveEquality(equations);
        expect(result).toEqual(1 + (1/75));
      })
    })
  });
  describe('solution is', () => {
    const inputPath = `${__dirname}/input`;
    const input = readFile(inputPath);
    test('169525884255464 for part 1', () => {
      const equations = parseEquations(input);
      const result = solveEquations(equations);
      expect(result).toEqual(169525884255464);
    });
    test('3247317268284 for part 2', () => {
      const equations = parseEquations(input);
      const result = solveEquality(equations);
      expect(result).toEqual(3247317268284);
    });
  });

  // region Tests for smaller parts
  // endregion
});
