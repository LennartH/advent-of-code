import { PathOrFileDescriptor, readFileSync } from 'fs';
import { splitLines } from './string';


export function readLines(path: PathOrFileDescriptor, trimFileContent = true, trimLines = true): string[] {
  return splitLines(readFile(path, false), trimFileContent, trimLines);
}

export function readFile(path: PathOrFileDescriptor, trimFileContent = true): string {
  const content = readFileSync(path, 'utf-8');
  return trimFileContent ? content.trim() : content;
}
