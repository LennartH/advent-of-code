import * as fs from 'fs';

export function readLines(path: fs.PathOrFileDescriptor, trimFileContent = true, trimLines = true): string[] {
  return splitLines(readFile(path, false), trimFileContent, trimLines);
}

export function readFile(path: fs.PathOrFileDescriptor, trimFileContent = true): string {
  const content = fs.readFileSync(path, 'utf-8');
  return trimFileContent ? content.trim() : content;
}

export function splitLines(text: string, trimText = true, trimLines = true): string[] {
  if (trimText) {
    text = text.trim();
  }
  return text.split('\n').map((l) => trimLines ? l.trim() : l);
}
