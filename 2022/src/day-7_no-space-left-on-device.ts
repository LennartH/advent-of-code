import * as fs from 'fs';

const commandNames = ['cd', 'ls'] as const;
type CommandName = typeof commandNames[number];

class Command {
  readonly name: CommandName;
  readonly arguments: string[];
  readonly output: string | null;

  constructor(input: string) {
    const outputSeparator = input.indexOf('\n');
    const line = outputSeparator > 0 ? input.slice(0, outputSeparator) : input;
    const parts = line.split(' ');
    if (!commandNames.includes(parts[0] as never)) {
      throw new Error(`Invalid command '${parts[0]}'`);
    }
    this.name = parts[0] as never;
    this.arguments = parts.slice(1);
    this.output = outputSeparator > 0 ? input.slice(outputSeparator + 1).trim() : null;
  }

  process(filesystem: Filesystem) {
    if (this.name === 'cd') {
      const targetDirectoryName = this.arguments[0];
      if (targetDirectoryName === '/') {
        filesystem.workingDirectory = filesystem.rootDirectory;
      } else if (targetDirectoryName === '..') {
        if (!filesystem.workingDirectory.parent) {
          throw new Error('The current working directory has no parent');
        }
        filesystem.workingDirectory = filesystem.workingDirectory.parent;
      } else {
        const childDirectory = filesystem.workingDirectory.children.filter((c): c is Directory => c instanceof Directory)
          .find((d) => d.name === targetDirectoryName);
        if (!childDirectory) {
          throw new Error(`Directory '${targetDirectoryName}' not found`);
        }
        filesystem.workingDirectory = childDirectory;
      }
    } else if (this.name === 'ls') {
      this.output?.split('\n').map((l) => l.trim().split(' ')).forEach(([sizeOrDir, name]) => {
        if (sizeOrDir === 'dir') {
          filesystem.workingDirectory.children.push(new Directory(name, filesystem.workingDirectory));
        } else {
          const size = Number(sizeOrDir);
          filesystem.workingDirectory.children.push(new File(name, filesystem.workingDirectory, size));
        }
      })
    } else {
      throw new Error(`Not implemented for command '${this.name}'`);
    }
  }
}

function parseCommands(input: string): Command[] {
  const commandInputs = input.split('$').slice(1).map((i) => i.trim());
  return commandInputs.map((i) => new Command(i));
}

// region Files and Directories
abstract class FileEntry {
  name: string;
  parent: Directory | null;

  abstract get size(): number;

  protected constructor(name: string, parent?: Directory) {
    this.name = name;
    this.parent = parent || null;
  }
}

class File extends FileEntry {
  constructor(
    name: string,
    parent: Directory,
    public size: number,
  ) {
    super(name, parent);
  }
}

class Directory extends FileEntry {
  children: (File | Directory)[];

  private _size: number = -1;

  get size(): number {
    this._size = this.children.reduce((s, c) => s + c.size, 0);
    return this._size;
  }

  constructor(name: string, parent: Directory, children?: (File | Directory)[]) {
    super(name, parent);
    this.children = children || [];
  }
}

class RootDirectory extends Directory {
  constructor() {
    super('/', null as never);
  }
}
// endregion

class Filesystem {
  workingDirectory: Directory;
  readonly rootDirectory: RootDirectory;

  constructor() {
    this.rootDirectory = new RootDirectory();
    this.workingDirectory = this.rootDirectory;
  }

  get size(): number {
    return this.rootDirectory.size;
  }

  allDirectories(): Directory[] {
    const directories: Directory[] = [this.rootDirectory];
    for (let index = 0; index < directories.length; index++) {
      directories.push(...directories[index].children.filter((c): c is Directory => c instanceof Directory));
    }
    return directories;
  }
}

function exampleSolution() {
  const input = `
    $ cd /
    $ ls
    dir a
    14848514 b.txt
    8504156 c.dat
    dir d
    $ cd a
    $ ls
    dir e
    29116 f
    2557 g
    62596 h.lst
    $ cd e
    $ ls
    584 i
    $ cd ..
    $ cd ..
    $ cd d
    $ ls
    4060174 j
    8033020 d.log
    5626152 d.ext
    7214296 k
  `.trim();
  const commands = parseCommands(input);
  const filesystem = new Filesystem();
  commands.forEach((c) => c.process(filesystem));

  const part1Result = filesystem.allDirectories().filter((d) => d.size <= 100000).reduce((s, d) => s + d.size, 0);
  const part2Result = filesystem.allDirectories().filter((d) => d.size >= 8381165).reduce((a, b) => a.size < b.size ? a : b).size;
  console.log(`Solution for example input: Part 1 ${part1Result} | Part 2 ${part2Result}`);
}

function part1Solution() {
  const input = fs.readFileSync('./assets/day-7_no-space-left-on-device.input.txt', 'utf-8').trim();
  const commands = parseCommands(input);
  const filesystem = new Filesystem();
  commands.forEach((c) => c.process(filesystem));
  const totalSizeOfSmallDirectories = filesystem.allDirectories().filter((d) => d.size <= 100000).reduce((s, d) => s + d.size, 0);
  console.log(`Solution for Part 1: ${totalSizeOfSmallDirectories}`);
}

function part2Solution() {
  const input = fs.readFileSync('./assets/day-7_no-space-left-on-device.input.txt', 'utf-8').trim();
  const commands = parseCommands(input);
  const filesystem = new Filesystem();
  commands.forEach((c) => c.process(filesystem));
  const spaceNeeded = 30000000 - (70000000 - filesystem.size);
  const deletionSize = filesystem.allDirectories().filter((d) => d.size >= spaceNeeded).reduce((a, b) => a.size < b.size ? a : b).size;
  console.log(`Solution for Part 2: ${deletionSize}`);
}


exampleSolution();
part1Solution();
part2Solution();
