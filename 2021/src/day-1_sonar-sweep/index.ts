export function countValueIncrements(values: number[], windowSize = 1): number {
  let count = 0;
  for (let i = windowSize; i < values.length; i++) {
    const window1 = values.slice(i - windowSize, i).reduce((s, v) => s + v, 0);
    const window2 = values.slice(i - windowSize + 1, i + 1).reduce((s, v) => s + v, 0);
    if (window2 > window1) {
      count++;
    }
  }
  return count;
}
