import { splitLines } from '@util';

export type Packet = (number | Packet)[];
export type PacketPair = [Packet, Packet];

export function parsePackets(input: string): PacketPair[] {
  const lines = splitLines(input).filter((l) => l.length !== 0);
  if (lines.length % 2 !== 0) {
    throw new Error('Read odd number of lines');
  }

  const pairs: [Packet, Packet][] = [];
  for (let i = 0; i < lines.length; i += 2) {
    pairs.push([parsePacket(lines[i]), parsePacket(lines[i + 1])]);
  }
  return pairs;
}

function parsePacket(line: string): Packet {
  const queue: Packet[] = [];
  let segment: Packet = undefined as never;
  let value = '';
  line = line.replace(/\s+/g, '');
  for (let i = 0; i < line.length; i++) {
    const char = line[i];
    if (char === '[') {
      const child: Packet = [];
      segment?.push(child);
      queue.push(segment);
      segment = child;
    } else if (char === ',' || char === ']') {
      if (value.length !== 0) {
        segment.push(Number(value));
      }
      value = '';
      if (char === ']') {
        const parent = queue.pop();
        if (!parent) {
          if (i !== line.length - 1) {
            throw new Error('End of stack');
          }
          return segment;
        }
        segment = parent;
      }
    } else {
      value += char;
    }
  }
  throw new Error('Unexpected end of input');
}

export function calculateOrderliness(pairs: PacketPair[]): number {
  return pairs
    .map((p, i) => (isInOrder(p) ? i + 1 : -1))
    .filter((v) => v !== -1)
    .reduce((s, v) => s + v, 0);
}

const dividerPacket1 = [[2]];
const dividerPacket2 = [[6]];

export function calculateDecoderKey(pairs: PacketPair[]): number {
  const packets = orderPackets(pairs);
  const dividerIndex1 = packets.indexOf(dividerPacket1) + 1;
  const dividerIndex2 = packets.indexOf(dividerPacket2) + 1;
  return dividerIndex1 * dividerIndex2;
}

export function orderPackets(pairs: PacketPair[]): Packet[] {
  const packets = pairs.reduce((list, p) => {
    list.push(p[0], p[1]);
    return list;
  }, [] as Packet[]);
  packets.push(dividerPacket1, dividerPacket2);
  packets.sort((p1, p2) => {
    const comparison = isSegmentInOrder([p1, p2]);
    if (comparison === true) {
      return -1;
    }
    if (comparison === false) {
      return 1;
    }
    return 0;
  });
  return packets;
}

export function isInOrder(pair: PacketPair): boolean {
  const isOrdered = isSegmentInOrder(pair);
  if (isOrdered === null) {
    throw new Error(`Unable to determine pair order`);
  }
  return isOrdered;
}

function isSegmentInOrder(pair: PacketPair): boolean | null {
  const left = [...pair[0]];
  const right = [...pair[1]];
  while (left.length > 0) {
    let leftValue = left.shift()!;
    let rightValue = right.shift();
    if (rightValue == null) {
      return false;
    }

    if (typeof leftValue === 'number' && typeof rightValue === 'number') {
      if (leftValue === rightValue) {
        continue;
      }
      return leftValue < rightValue;
    }

    if (typeof leftValue === 'number') {
      leftValue = [leftValue];
    }
    if (typeof rightValue === 'number') {
      rightValue = [rightValue];
    }
    const segmentOrder = isSegmentInOrder([leftValue, rightValue]);
    if (segmentOrder !== null) {
      return segmentOrder;
    }
  }
  return right.length === 0 ? null : true;
}
