export function splitLines(text: string, trimText = true, trimLines = true): string[] {
  if (trimText) {
    text = text.trim();
  }
  return text.split('\n').map((l) => trimLines ? l.trim() : l);
}

export function revertString(text: string): string {
  return text.split('').reverse().join('');
}

export const lowerCaseAlphabet = 'abcdefghijklmnopqrstuvwxyz';
export const upperCaseAlphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
