export function clamp(value: number, min: number, max: number): number {
  if (value <= min) {
    return min;
  }
  if (value >= max) {
    return max;
  }
  return value;
}

export function greatestCommonDivisor(a: number, b: number, ...numbers: number[]): number
export function greatestCommonDivisor(numbers: number[]): number
export function greatestCommonDivisor(...args: number[] | [number[]]): number {
    const numbers = Array.isArray(args[0]) ? args[0] : args as number[];

  let result = numbers[0];

  for (let i = 1; i < numbers.length; i++) {
    let a = result;
    let b = numbers[i];

    while (b !== 0) {
      let t = b;
      b = a % b;
      a = t;
    }

    result = a;
  }

  return result;
}

export function leastCommonMultiple(a: number, b: number, ...numbers: number[]): number
export function leastCommonMultiple(numbers: number[]): number
export function leastCommonMultiple(...args: number[] | [number[]]): number {
  const numbers = Array.isArray(args[0]) ? args[0] : args as number[];

  let result = numbers[0];
  for (let i = 1; i < numbers.length; i++) {
    const value = numbers[i];
    result = (result * value) / greatestCommonDivisor(result, value);
  }
  return result;
}
