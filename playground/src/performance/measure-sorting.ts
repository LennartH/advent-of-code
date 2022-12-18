import { timeit } from '@util';

let list: number[] = [];

const result = timeit('Sorting ordered list after adding single item',() => {
  list.unshift(10);
  list.sort((a, b) => a - b);
}, {
  count: 100000,
  beforeEach: () => list = new Array(2022).fill(0).map((_, i) => i),
});
console.dir(result);
