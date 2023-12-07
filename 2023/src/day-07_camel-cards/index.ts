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
  games.sort(compareGames);
  return games
    .map((g, i) => g.bid * (i + 1))
    .reduce((s, v) => s + v, 0);
}

export function solvePart2(input: string): number {
  const games = parseGames(splitLines(input), 'with jokers');
  games.sort((a, b) => compareGames(a, b, 'with jokers'));
  return games
    .map((g, i) => g.bid * (i + 1))
    .reduce((s, v) => s + v, 0);
}

// region Shared Code
function parseGames(lines: string[], withJokers?: 'with jokers'): Game[] {
  return lines.map((line) => {
    const [hand, bid] = line.split(' ');
    return {
      hand: parseHand(hand, withJokers),
      bid: Number(bid),
    }
  });
}

function compareGames({hand: a}: Game, {hand: b}: Game, withJokers?: 'with jokers'): number {
  if (a.rank !== b.rank) {
    return a.rank - b.rank;
  }
  for (let i = 0; i < 5; i++) {
    const cardRankA = getCardRank(a.cards[i], withJokers);
    const cardRankB = getCardRank(b.cards[i], withJokers);
    if (cardRankA === cardRankB) {
      continue;
    }
    return cardRankA - cardRankB;
  }
  return 0;
}

function getCardRank(cardFace: string, withJokers?: 'with jokers'): number {
  return withJokers && cardFace === 'J' ? 1 : cardRank[cardFace];
}

export function parseHand(hand: string, withJokers?: 'with jokers'): Hand {
  const cards = hand.split('');
  const countByFace = cards.reduce((counts, card) => {
    if (counts[card] == null) {
      counts[card] = 0;
    }
    counts[card]++;
    return counts;
  }, {} as Record<string, number>);
  let numberOfJokers = 0;
  if (withJokers) {
    numberOfJokers = countByFace['J'] || 0;
    countByFace['J'] = 0;
  }
  const faceCounts = Object.values(countByFace);

  const maxFaceCount = Math.max(...faceCounts) + numberOfJokers;
  // It's impossible to get two pairs if the hand contains a joker, so we ignore them
  const isTwoPair = faceCounts.filter((c) => c === 2).length === 2;

  // High card
  let handRank = 1;
  if (maxFaceCount >= 5) {
    handRank = 7;
  } else if (maxFaceCount >= 4) {
    handRank = 6;
  } else if (
    // Natural full house
    (faceCounts.some((c) => c === 3) && faceCounts.some((c) => c === 2)) ||
    // Full house with joker
    (isTwoPair && numberOfJokers === 1)
  ) {
    handRank = 5;
  } else if (maxFaceCount >= 3) {
    handRank = 4;
  } else if (isTwoPair) {
    handRank = 3;
  } else if (maxFaceCount >= 2) {
    handRank = 2;
  }

  return {cards, rank: handRank};
}
// endregion
