import { formatGrid } from './collection';
import { SparseArrayGrid } from './grid';

describe('format grid', () => {
  describe('configuration', () => {
    const grid = [
      ['a', 'b'],
      ['c', 'd'],
    ]
    test('without config', () => {
      const formattedGrid = formatGrid(grid);
      expect(formattedGrid).toEqual(cleanExpectedString(`
      ab
      cd
    `))
    });
    test('with row prefix', () => {
      const formattedGrid = formatGrid(grid, { rowPrefix: '|' });
      expect(formattedGrid).toEqual(cleanExpectedString(`
      |ab
      |cd
    `))
    });
    test('with row suffix', () => {
      const formattedGrid = formatGrid(grid, { rowSuffix: '|' });
      expect(formattedGrid).toEqual(cleanExpectedString(`
      ab|
      cd|
    `))
    });
    test('with column prefix', () => {
      const formattedGrid = formatGrid(grid, { columnPrefix: '-' });
      expect(formattedGrid).toEqual(cleanExpectedString(`
      --
      ab
      cd
    `))
    });
    test('with column suffix', () => {
      const formattedGrid = formatGrid(grid, { columnSuffix: '-' });
      expect(formattedGrid).toEqual(cleanExpectedString(`
      ab
      cd
      --
    `))
    });
    test('with column pre- and suffix', () => {
      const formattedGrid = formatGrid(grid, { columnPrefix: '_', columnSuffix: '-' });
      expect(formattedGrid).toEqual(cleanExpectedString(`
      __
      ab
      cd
      --
    `))
    });
    test('with column and row prefix', () => {
      const formattedGrid = formatGrid(grid, { rowPrefix: '|', columnPrefix: '-' });
      expect(formattedGrid).toEqual(cleanExpectedString(`
      |--
      |ab
      |cd
    `))
    });
    test('with column prefix, row prefix and row suffix', () => {
      const formattedGrid = formatGrid(grid, { rowPrefix: '<', rowSuffix: '>', columnPrefix: '-' });
      expect(formattedGrid).toEqual(cleanExpectedString(`
      <-->
      <ab>
      <cd>
    `))
    });
    test('with all pre- and suffixes', () => {
      const formattedGrid = formatGrid(grid, {
        rowPrefix: '<',
        rowSuffix: '>',
        columnPrefix: '_',
        columnSuffix: '-',
      });
      expect(formattedGrid).toEqual(cleanExpectedString(`
      <__>
      <ab>
      <cd>
      <-->
    `))
    });
    test('with all pre- and suffixes and outside corners', () => {
      const formattedGrid = formatGrid(grid, {
        rowPrefix: '<',
        rowSuffix: '>',
        columnPrefix: '_',
        columnSuffix: '-',
        outsideCorner: '+',
      });
      expect(formattedGrid).toEqual(cleanExpectedString(`
      +__+
      <ab>
      <cd>
      +--+
    `))
    });
    test('with column separator', () => {
      const formattedGrid = formatGrid(grid, { columnSeparator: '~' });
      expect(formattedGrid).toEqual(cleanExpectedString(`
      a~b
      c~d
    `))
    });
    test('with row separator', () => {
      const formattedGrid = formatGrid(grid, { rowSeparator: ':' });
      expect(formattedGrid).toEqual(cleanExpectedString(`
      ab
      ::
      cd
    `))
    });
    test('with row and column separator', () => {
      const formattedGrid = formatGrid(grid, { rowSeparator: ':', columnSeparator: '~' });
      expect(formattedGrid).toEqual(cleanExpectedString(`
      a~b
      :::
      c~d
    `))
    })
    test('with value formatter', () => {
      const formattedGrid = formatGrid(grid, { valueFormatter: (v) => v + v });
      expect(formattedGrid).toEqual(cleanExpectedString(`
      aabb
      ccdd
    `))
    })
    test('with full config', () => {
      const formattedGrid = formatGrid(grid, {
        valueFormatter: (v) => v + v,

        rowPrefix: '|',
        rowSuffix: '|',
        rowSeparator: '.',

        columnPrefix: '-',
        columnSuffix: '-',
        columnSeparator: ' ',

        outsideCorner: '+',
      });
      expect(formattedGrid).toEqual(cleanExpectedString(`
      +-----+
      |aa bb|
      |.....|
      |cc dd|
      +-----+
    `))
    })

    test('with outside corner and row prefix, but without row suffix', () => {
      const formattedGrid = formatGrid(grid, {
        rowPrefix: '|',
        columnPrefix: '-',
        outsideCorner: '+',
      });
      expect(formattedGrid).toEqual(cleanExpectedString(`
      +--
      |ab
      |cd
    `))
    })
    test('with outside corner and row suffix, but without row prefix', () => {
      const formattedGrid = formatGrid(grid, {
        rowSuffix: '|',
        columnPrefix: '-',
        outsideCorner: '+',
      });
      expect(formattedGrid).toEqual(cleanExpectedString(`
      --+
      ab|
      cd|
    `))
    })
    test('with shorter outside corner than row suffix and prefix', () => {
      const formattedGrid = formatGrid(grid, {
        outsideCorner: '+',
        rowPrefix: '/\\',
        rowSuffix: '/\\',
        columnPrefix: '-',
        columnSuffix: '-',
      });
      expect(formattedGrid).toEqual(cleanExpectedString(`
      ++--++
      /\\ab/\\
      /\\cd/\\
      ++--++
    `))
    })
    test('with longer outside corner than row suffix and prefix', () => {
      const formattedGrid = formatGrid(grid, {
        outsideCorner: '123',
        rowPrefix: '|',
        rowSuffix: '|',
        columnPrefix: '-',
        columnSuffix: '-',
      });
      expect(formattedGrid).toEqual(cleanExpectedString(`
      1--1
      |ab|
      |cd|
      1--1
    `))
    })
    test('with multi-character column prefix', () => {
      const formattedGrid = formatGrid(grid, {
        columnPrefix: '12',
        columnSeparator: ' ',
      });
      expect(formattedGrid).toEqual(cleanExpectedString(`
      121
      a b
      c d
    `))
    })
    test('with multi-character row separator', () => {
      const formattedGrid = formatGrid(grid, {
        rowSeparator: '12',
        columnSeparator: ' ',
      });
      expect(formattedGrid).toEqual(cleanExpectedString(`
      a b
      121
      c d
    `))
    })
  })
  describe('edge cases', () => {
    test('of empty grid', () => {
      expect(formatGrid([])).toEqual('');
    })
    test('of grid with single empty row', () => {
      expect(formatGrid([[]])).toEqual('');
    })

    test('of sparse grid', () => {
      const grid = new SparseArrayGrid<string>(2, 2);
      grid.set(0, 0, 'a');
      grid.set(1, 1, 'b');
      expect(formatGrid(grid, { valueFormatter: (v) => v || '.' })).toEqual(cleanExpectedString(`
      a.
      .b
    `))
    })
  })

  function cleanExpectedString(expected: string): string {
    return expected.trim().split('\n').map((l) => l.trim()).join('\n');
  }
});
