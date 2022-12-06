import * as fs from 'fs';

function findStartOfPacket(data: string, markerLength: number): number {
  let markerStart = -markerLength;
  let markerEnd = 0;
  const characterCount: Record<string, number> = {};
  for (let index = 0; index < data.length; index++) {
    const character = data[index];
    characterCount[character] = (characterCount[character] || 0) + 1;
    if (markerStart >= 0) {
      const character = data[markerStart];
      characterCount[character] -= 1;
      if (!Object.values(characterCount).filter((c) => c > 0).some((c) => c !== 1)) {
        return index + 1;
      }
    }
    markerStart++;
    markerEnd++;
  }
  throw new Error(`No start-of-packet marker found in '${data}'`);
}

function exampleSolution() {
  const inputs = [
    'mjqjpqmgbljsphdztnvjfqwrcgsmlb',
    'bvwbjplbgvbhsrlpgdmjqwftvncz',
    'nppdvjthqldpwncqszvftbrmjlhg',
    'nznrnfrfntjfmvfwmzdfjlvtqnbhcprsg',
    'zcfzfwzzqfrljwzlrfnpqdbhtmscgvjw',
  ];
  const part1Score = inputs.map((d) => findStartOfPacket(d, 4));
  const part2Score = inputs.map((d) => findStartOfPacket(d, 14));
  console.log(`Solution for example input: Part 1 ${part1Score} | Part 2 ${part2Score}`);
}

function part1Solution() {
  const input = fs.readFileSync('./assets/day-6_tuning-trouble.input.txt', 'utf-8');
  const startOfPacket = findStartOfPacket(input, 4);
  console.log(`Solution for Part 1: ${startOfPacket}`);
}

function part2Solution() {
  const input = fs.readFileSync('./assets/day-6_tuning-trouble.input.txt', 'utf-8');
  const startOfMessage = findStartOfPacket(input, 14);
  console.log(`Solution for Part 2: ${startOfMessage}`);
}


exampleSolution();
part1Solution();
part2Solution();
