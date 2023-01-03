import { readFile } from '@util';
import { decryptGroveCoordinates, parseEncryptedData } from './index';

describe('Day 20', () => {
  describe('example input', () => {
    const input = `
      1
      2
      -3
      3
      -2
      0
      4
    `;

    test('solution is 3 for part 1', () => {
      const rawData = parseEncryptedData(input);
      const coordinates = decryptGroveCoordinates(rawData);
      expect(coordinates).toEqual( 3);
    });
    test('solution is 1623178306 for part 2', () => {
      const rawData = parseEncryptedData(input);
      const coordinates = decryptGroveCoordinates(rawData, 811589153, 10);
      expect(coordinates).toEqual( 1623178306);
    });
  });
  describe('solution is', () => {
    const inputPath = `${__dirname}/input`;
    const input = readFile(inputPath);
    test('2215 for part 1', () => {
      const rawData = parseEncryptedData(input);
      const coordinates = decryptGroveCoordinates(rawData, 1);
      expect(coordinates).toEqual(2215);
    });
    test('8927480683 for part 2', () => {
      const rawData = parseEncryptedData(input);
      const coordinates = decryptGroveCoordinates(rawData, 811589153, 10);
      expect(coordinates).toEqual( 8927480683);
    });
  });
});
