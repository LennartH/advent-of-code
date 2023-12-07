import { splitLines } from '@util';

// region Types and Globals
interface Game {
  hand: Hand;
  bid: number;
}

interface Hand {
  cards: string[];
  rank: number;
}

const cardRank: Record<string, number> = {
  2: 2,
  3: 3,
  4: 4,
  5: 5,
  6: 6,
  7: 7,
  8: 8,
  9: 9,
  T: 10,
  J: 11,
  Q: 12,
  K: 13,
  A: 14,
};
// endregion

export function solvePart1(input: string): number {
  const games = parseGames(splitLines(input));
  games.sort(({hand: a}, {hand: b}) => {
    if (a.rank !== b.rank) {
      return a.rank - b.rank;
    }
    for (let i = 0; i < 5; i++) {
      const cardRankA = cardRank[a.cards[i]];
      const cardRankB = cardRank[b.cards[i]];
      if (cardRankA === cardRankB) {
        continue;
      }
      return cardRankA - cardRankB;
    }
    return 0;
  });
  return games
    .map((g, i) => g.bid * (i + 1))
    .reduce((s, v) => s + v, 0);
}

export function solvePart2(input: string): number {
  const lines = splitLines(input);
  // TODO Implement solution
  return Number.NaN;
}

// region Shared Code
function parseGames(lines: string[]): Game[] {
  return lines.map((line) => {
    const [hand, bid] = line.split(' ');
    return {
      hand: parseHand(hand),
      bid: Number(bid),
    }
  });
}

function parseHand(hand: string): Hand {
  const cards = hand.split('');
  const countByFace = cards.reduce((counts, card) => {
    if (counts[card] == null) {
      counts[card] = 0;
    }
    counts[card]++;
    return counts;
  }, {} as Record<string, number>);
  const faceCounts = Object.values(countByFace);

  // High card
  let handRank = 1;
  if (faceCounts.some((c) => c === 5)) {
    // Five of a kind
    handRank = 7;
  } else if (faceCounts.some((c) => c === 4)) {
    // Four of a kind
    handRank = 6;
  } else if (faceCounts.some((c) => c === 3) && faceCounts.some((c) => c === 2)) {
    // Full house
    handRank = 5;
  } else if (faceCounts.some((c) => c === 3)) {
    // Three of a kind
    handRank = 4;
  } else if (faceCounts.filter((c) => c === 2).length === 2) {
    // Two pair
    handRank = 3;
  } else if (faceCounts.some((c) => c === 2)) {
    // One pair
    handRank = 2;
  }
  return {cards, rank: handRank};
}
// endregion
