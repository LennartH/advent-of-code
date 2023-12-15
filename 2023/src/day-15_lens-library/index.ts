import { splitLines, sum } from '@util';

export function solvePart1(input: string): number {
  const instructions = splitLines(input)[0].split(',');
  return instructions.map(hashCode).reduce(sum);
}

export function solvePart2(input: string): number {
  const instructions = splitLines(input)[0].split(',');
  const lensMap = new LensMap();
  instructions.forEach((i) => lensMap.execute(i));
  return lensMap.totalFocusingPower();
}

// region Types and Globals
class LensMap {
  readonly boxes: LensMapEntry[][] = new Array(256).fill(0).map(() => []);

  execute(instruction: string) {
    if (instruction.indexOf('-') !== -1) {
      this.remove(instruction.slice(0, -1))
    } else {
      const [key, value] = instruction.split('=');
      this.set(key, Number(value));
    }
  }

  remove(key: string) {
    const box = this.boxes[hashCode(key)];
    const index = box.findIndex(({key: k}) => k === key);
    if (index !== -1) {
      box.splice(index, 1);
    }
  }

  set(key: string, value: number) {
    const box = this.boxes[hashCode(key)];
    const entry = box.find(({key: k}) => k === key);
    if (entry != null) {
      entry.value = value;
    } else {
      box.push({key, value});
    }
  }

  totalFocusingPower(): number {
    return this.boxes
      .flatMap(
        (b, bi) => b.map(({value: v}, li) =>  (bi + 1) * (li + 1) * v)
      )
      .reduce(sum);
  }
}

interface LensMapEntry {
  key: string;
  value: number;
}
// endregion

// region Shared Code
function hashCode(text: string): number {
  let hash = 0;
  for (let i = 0; i < text.length; i++) {
    hash += text.charCodeAt(i);
    hash *= 17;
    hash = hash % 256;
  }
  return hash;
}
// endregion
