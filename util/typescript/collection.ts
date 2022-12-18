export function shuffle<T>(list: T[]): T[] {
  for (let i = list.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [list[i], list[j]] = [list[j], list[i]];
  }
  return list;
}

export function* allPermutations<T>(list: T[]): Generator<T[]> {
  const length = list.length;
  const c = new Array(length).fill(0);
  let i = 1, k, p;

  yield list.slice();
  while (i < length) {
    if (c[i] < i) {
      k = i % 2 && c[i];
      p = list[i];
      list[i] = list[k];
      list[k] = p;
      ++c[i];
      i = 1;
      yield list.slice();
    } else {
      c[i] = 0;
      ++i;
    }
  }
}
