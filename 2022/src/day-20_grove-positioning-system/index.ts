import { splitLines } from '@util';

export function parseEncryptedData(input: string): number[] {
  return splitLines(input).map((v) => Number(v));
}

export function decryptGroveCoordinates(rawData: number[], decryptionKey = 1, mixCount = 1): number {
  const data = rawData.map((v, i) => ({value: v * decryptionKey, originalIndex: i}));

  const mixed = [...data];
  for (let count = 0; count < mixCount; count++) {
    for (let originalIndex = 0; originalIndex < data.length; originalIndex++) {
      const entry = data[originalIndex];
      const index = mixed.indexOf(entry);
      const newIndex = (index + entry.value) % (mixed.length - 1);
      mixed.splice(index, 1);
      mixed.splice(newIndex, 0, entry);
    }
  }

  const zeroIndex = mixed.findIndex(({value}) => value === 0);
  let sum = 0;
  for (let i = 1; i <= 3; i++) {
    let groveCoordinate = (zeroIndex + (i * 1000)) % mixed.length;
    sum += mixed[groveCoordinate].value;
  }
  return sum;
}
