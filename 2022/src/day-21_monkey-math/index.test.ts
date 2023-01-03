import { readFile } from '@util';
import { parseEquations, solveEquations } from './index';

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
    test.skip('solution is ? for part 2', () => {
      throw new Error('Not implemented')
    });
  });
  describe('solution is', () => {
    const inputPath = `${__dirname}/input`;
    const input = readFile(inputPath);
    test('169525884255464 for part 1', () => {
      const equations = parseEquations(input);
      const result = solveEquations(equations);
      expect(result).toEqual(169525884255464);
    });
    test.skip('? for part 2', () => {
      throw new Error('Not implemented')
    });
  });

  // region Tests for smaller parts
  // endregion
});
