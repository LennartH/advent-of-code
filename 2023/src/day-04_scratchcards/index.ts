import { splitLines } from '@util';

// region Types and Globals
interface Card {
  id: number;
  matches: number;
}
// endregion

export function solvePart1(input: string): number {
  const lines = splitLines(input);
  return parseCards(lines)
    .map(({matches}) => matches <= 1 ? matches : Math.pow(2, matches - 1))
    .reduce((s, v) => s + v, 0);
}

export function solvePart2(input: string): number {
  const cards = parseCards(splitLines(input));
  const deck = [...cards];
  let count = 0;
  let card: Card | undefined = deck.pop();
  while (card != null) {
    count++;
    if (card.matches > 0) {
      // Card IDs start at 1, but array is zero indexed. So card.id is index of the following card.
      const copies = cards.slice(card.id, card.id + card.matches);
      deck.push(...copies);
    }
    card = deck.pop();
  }
  return count;
}

// region Shared Code
function parseCards(lines: string[]): Card[] {
  return lines.map((card) => {
    const [header, rest] = card.split(':').map((s) => s.trim());
    const id = Number(header.split(/\s+/)[1]);
    const [winningNumbers, numbers] = rest
      .split('|').map((p) => p.trim().split(/\s+/))
      .map((l) => l.map((v) => Number(v.trim())));
    const matches = winningNumbers.filter((n) => numbers.includes(n)).length;
    return {id, matches};
  });
}
// endregion
