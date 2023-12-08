#!/usr/bin/env node

import { Command, InvalidArgumentError } from 'commander';
import * as Handlebars from 'handlebars';
import * as path from 'path';
import * as fs from 'node:fs/promises';
import { kebabCase, startCase } from 'lodash';
import axios from 'axios';
import dotenv from 'dotenv';

dotenv.config();

// TODO Add tests
// TODO Better logging

// TODO Move templates into tool directory
// TODO Determine path of this file and make source path relative to this file
const aocTokenEnv = 'AOC_TOKEN';
const typescriptDayTemplateSource = path.resolve(process.env.HOME!, 'projects/advent-of-code/template/typescript/day-{{day}}_{{title}}');
const readmePath = path.resolve('README.md');

// TODO Add option to select template language
// TODO Add option to dry-run
const command = new Command()
  .argument('<output>', 'Path to the output directory')
  .requiredOption('-t, --title <title>', 'Title of the puzzle')
  .option('-d, --day <number>', 'Number of the day', parseDayNumber, 'today')
  .option('-y, --year <number>', 'Number of the year', parseYear, new Date().getFullYear().toString())
  .option('-u, --update-readme', 'Add entry for the current or given year to the readme', true)
  .option('--no-update-readme', 'Do not update readme')
  .option('-i, --load-input', `Load puzzle input using ${aocTokenEnv} as session token`, true)
  .option('--no-load-input', 'Do not load the puzzle input')
  .action(generateDayFiles);
command.parse();

interface GenerateDayOptions {
  day: string;
  year: string;
  title: string;
  updateReadme: boolean;
  loadInput: boolean;
}

function parseDayNumber(value: string): string {
  if (value === 'today') {
    return value;
  }

  const dayNumber = Number(value);
  if (isNaN(dayNumber)) {
    throw new InvalidArgumentError('Must be a number.');
  }
  if (dayNumber <= 0 || dayNumber > 24) {
    throw new InvalidArgumentError('Must be between 1 and 24.');
  }
  return `${dayNumber}`;
}

function parseYear(value: string): string | boolean {
  if (!value.match(/^\d{4}$/)) {
    throw new InvalidArgumentError('Must be a 4 digit number.')
  }
  return value;
}

async function generateDayFiles(output: string, options: GenerateDayOptions) {
  const contentOptions = cleanOptions(options);
  const pathOptions = {
    ...contentOptions,
    title: kebabCase(contentOptions.title),
    day: contentOptions.day.padStart(2, '0')
  };

  const sourcePath = typescriptDayTemplateSource;
  const outputDirectory = renderTemplate(path.basename(sourcePath), pathOptions);
  const outputPath = path.join(path.resolve(output), outputDirectory);
  const outputExists = await fs.access(outputPath, fs.constants.F_OK)
    .then(() => true)
    .catch((error) => error.code === 'ENOENT' ? false : Promise.reject(error));
  if (outputExists) {
    console.log(`Error - Output directory already exists: ${path.relative(process.cwd(), outputPath)}`);
    return;
  }
  await fs.mkdir(outputPath, { recursive: true });

  const templateFiles = await fs.readdir(sourcePath);
  for (const templateFile of templateFiles) {
    const outputFilename = renderTemplate(templateFile, pathOptions);
    const outputContent = await renderFile(path.join(sourcePath, templateFile), contentOptions);
    await fs.writeFile(path.join(outputPath, outputFilename), outputContent);
  }
  console.log(`Files have been generated at ${path.relative(process.cwd(), outputPath)}`);

  if (contentOptions.updateReadme) {
    const readmeOptions = {
      year: contentOptions.year,
      day: contentOptions.day,
      title: contentOptions.title,
      directory: outputDirectory,
    }
    await addEntryToReadme(readmePath, readmeOptions);
    console.log(`Added entry for Day '${contentOptions.day}: ${contentOptions.title}' to readme`);
  }

  if (contentOptions.loadInput) {
    if (!process.env[aocTokenEnv]) {
      console.log(`Error: ${aocTokenEnv} not found`)
    } else {
      const {year, day} = contentOptions;
      const inputFilePath = path.join(outputPath, 'input');
      await fetchPuzzleInput(year, day, inputFilePath);
      console.log(`Puzzle input saved to ${path.relative(process.cwd(), inputFilePath)}`);
    }
  }
}


// TODO Determine repository URL from git remote
const solutionUrl = Handlebars.compile('https://github.com/LennartH/advent-of-code/blob/main/{{year}}/src/{{directory}}/index.ts');
const puzzleUrl = Handlebars.compile('https://adventofcode.com/{{year}}/day/{{day}}');
const readmeListHeader = Handlebars.compile('### {{year}}');
const readmeEntry = Handlebars.compile('- **Day {{day}}: {{title}}** [Solution]({{solutionUrl}}) / [Puzzle]({{puzzleUrl}})');

async function addEntryToReadme(readmePath: string, options: {year: string, day: string, title: string, directory: string}) {
  const readmeContent = await fs.readFile(readmePath, 'utf-8');

  const listHeader = readmeListHeader(options);
  const headerIndex = readmeContent.indexOf(listHeader);
  if (headerIndex < 0) {
    // TODO Add list header instead
    console.log(`Error: Unable to locate list header for year ${options.year}`);
    return;
  }
  const listStartIndex = readmeContent.indexOf('-', headerIndex);

  const beforeList = readmeContent.slice(0, listStartIndex);
  const afterList = readmeContent.slice(listStartIndex);

  const newEntry = readmeEntry({
    ...options,
    solutionUrl: solutionUrl(options),
    puzzleUrl: puzzleUrl(options),
  });
  const updatedContent = `${beforeList}${newEntry}\n${afterList}`;

  await fs.writeFile(readmePath, updatedContent);
}

async function fetchPuzzleInput(year: number | string, day: number | string, outputPath: string): Promise<void> {
  const response = await axios.get(`https://adventofcode.com/${year}/day/${day}/input`, {
    headers: {
      'Cookie': `session=${process.env[aocTokenEnv]}`
    }
  });
  await fs.writeFile(outputPath, response.data);
}

// TODO Cleanup
function cleanOptions(options: GenerateDayOptions): Required<GenerateDayOptions> {

  const cleaned: Required<GenerateDayOptions> = {...options} as never;
  cleaned.title = startCase(options.title.toLowerCase());

  if (options.day === 'today') {
    const dayNumber = new Date().getDate();
    if (dayNumber <= 0 || dayNumber > 24) {
      throw new Error("Can't use 'today' for option --day. Must be between 1 and 24.");
    }
    cleaned.day = `${dayNumber}`;
  }

  return cleaned;
}

async function renderFile<T>(filePath: string, context: T): Promise<string> {
  return renderTemplate(await fs.readFile(filePath, 'utf-8'), context);
}

function renderTemplate<T>(template: string, context: T): string {
  const render = Handlebars.compile<T>(template);
  return render(context);
}
