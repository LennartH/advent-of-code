import { Game, Monkey, parseMonkeys } from './index';
import { readFile } from '../../../util/util';

describe('day 11', () => {
  describe('example input', () => {
    const input = `
      Monkey 0:
        Starting items: 79, 98
        Operation: new = old * 19
        Test: divisible by 23
          If true: throw to monkey 2
          If false: throw to monkey 3
      
      Monkey 1:
        Starting items: 54, 65, 75, 74
        Operation: new = old + 6
        Test: divisible by 19
          If true: throw to monkey 2
          If false: throw to monkey 0
      
      Monkey 2:
        Starting items: 79, 60, 97
        Operation: new = old * old
        Test: divisible by 13
          If true: throw to monkey 1
          If false: throw to monkey 3
      
      Monkey 3:
        Starting items: 74
        Operation: new = old + 3
        Test: divisible by 17
          If true: throw to monkey 0
          If false: throw to monkey 1
    `;

    test('returns 10605 for part 1', () => {
      const monkeys = parseMonkeys(input);
      const game = new Game(monkeys, 3);
      game.executeGame(20);
      expect(game.inspectionsCounts).toEqual([101, 95, 7, 105]);
      expect(game.calculateMonkeyBusiness()).toEqual(10605);
    });
    test('returns 2713310158 for part 2', () => {
      const monkeys = parseMonkeys(input);
      const game = new Game(monkeys, 1);
      game.executeGame(20);
      expect(game.inspectionsCounts).toEqual([99, 97, 8, 103]);
      game.executeGame(10000 - 20);
      expect(game.calculateMonkeyBusiness()).toEqual(2713310158);
    });

    describe('parse input', () => {
      test('of monkey with addition as operator', () => {
        const [monkey] = parseMonkeys(`
          Monkey 0:
            Starting items: 54, 65, 75, 74
            Operation: new = old + 6
            Test: divisible by 19
              If true: throw to monkey 2
              If false: throw to monkey 0
        `);
        expect(monkey).toEqual(
          new Monkey(
            [54, 65, 75, 74],
            { operand1: 'old', operator: '+', operand2: 6 },
            { divisor: 19, targetIfTrue: 2, targetIfFalse: 0 }
          )
        );
      });
      test("of monkey with 'old' as both operands", () => {
        const [monkey] = parseMonkeys(`
          Monkey 0:
            Starting items: 79, 60, 97
            Operation: new = old * old
            Test: divisible by 13
              If true: throw to monkey 1
              If false: throw to monkey 3
        `);
        expect(monkey).toEqual(
          new Monkey(
            [79, 60, 97],
            { operand1: 'old', operator: '*', operand2: 'old' },
            { divisor: 13, targetIfTrue: 1, targetIfFalse: 3 }
          )
        );
      });
      test("of monkey with 'old' as second operand", () => {
        const [monkey] = parseMonkeys(`
          Monkey 0:
            Starting items: 79, 98
            Operation: new = 19 * old
            Test: divisible by 23
              If true: throw to monkey 2
              If false: throw to monkey 3
        `);
        expect(monkey).toEqual(
          new Monkey(
            [79, 98],
            { operand1: 19, operator: '*', operand2: 'old' },
            { divisor: 23, targetIfTrue: 2, targetIfFalse: 3 }
          )
        );
      });
      test('of multiple monkeys', () => {
        const monkeys = parseMonkeys(`
          Monkey 0:
            Starting items: 79, 60, 97
            Operation: new = old * old
            Test: divisible by 13
              If true: throw to monkey 1
              If false: throw to monkey 3
  
          Monkey 1:
            Starting items: 74
            Operation: new = old + 3
            Test: divisible by 17
              If true: throw to monkey 0
              If false: throw to monkey 1
        `);
        expect(monkeys).toEqual([
          new Monkey(
            [79, 60, 97],
            { operand1: 'old', operator: '*', operand2: 'old' },
            { divisor: 13, targetIfTrue: 1, targetIfFalse: 3 }
          ),
          new Monkey(
            [74],
            { operand1: 'old', operator: '+', operand2: 3 },
            { divisor: 17, targetIfTrue: 0, targetIfFalse: 1 }
          ),
        ]);
      });
    });
  });

  describe('solution is', () => {
    test('99840 for part 1', () => {
      const monkeys = parseMonkeys(readFile(`${__dirname}/input`));
      const game = new Game(monkeys, 3);
      game.executeGame(20);
      expect(game.calculateMonkeyBusiness()).toEqual(99840);
    });
    test('20683044837 for part 2', () => {
      const monkeys = parseMonkeys(readFile(`${__dirname}/input`));
      const game = new Game(monkeys, 1);
      game.executeGame(10000);
      expect(game.calculateMonkeyBusiness()).toEqual(20683044837);
    });
  });
});
