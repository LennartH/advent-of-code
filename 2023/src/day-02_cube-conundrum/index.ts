import { splitLines } from '@util';

const colors = ['red', 'green', 'blue'] as const;
type Color = typeof colors[number];

interface GameConfig {
  red: number;
  green: number;
  blue: number;
}

interface GameRecord {
  id: number;
  cubeSets: Record<Color, number>[];
}

export function solvePart1(input: string): number {
  const lines = splitLines(input);
  const games = lines.map(parseGame);
  const gameConfig = {
    red: 12,
    green: 13,
    blue: 14,
  };
  const possibleGames = games.filter((r) => isGamePossible(r, gameConfig));
  return possibleGames.reduce((s, r) => s + r.id, 0);
}

export function solvePart2(input: string): number {
  const lines = splitLines(input);
  const games = lines.map(parseGame);
  const maxColorValues = games.map(extractMaxColorValues);
  return maxColorValues.reduce((s, {red, green, blue}) => s + (red * green * blue), 0);
}

function isGamePossible(record: GameRecord, config: GameConfig): boolean {
  const maxValues = extractMaxColorValues(record);
  for (const color of colors) {
    const colorMax = maxValues[color];
    const colorLimit = config[color];
    if (colorMax > colorLimit) {
      return false;
    }
  }
  return true;
}

function extractMaxColorValues(record: GameRecord) {
  return record.cubeSets.reduce((max, record) => {
    for (const color of colors) {
      const colorValue = record[color];
      const colorMax = max[color];
      if (colorValue > colorMax) {
        max[color] = colorValue;
      }
    }
    return max;
  }, { red: 0, green: 0, blue: 0 });
}

function parseGame(line: string): GameRecord {
  const [header, body] = line.split(':');
  const id = Number(header.split(' ')[1]);
  if (isNaN(id)) {
    throw new Error(`Unable to parse id for line: ${line}`);
  }
  const cubeSets = body.split(';').map((entry) => {
    return entry.split(',').reduce((cubeSet, colorValue) => {
      const [value, color] = colorValue.trim().split(' ');
      (cubeSet as Record<string, number>)[color] = Number(value);
      return cubeSet;
    }, {red: 0, green: 0, blue: 0})
  });
  return {id, cubeSets};
}
