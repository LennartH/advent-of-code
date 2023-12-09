#!/usr/bin/env node

import { Command, InvalidArgumentError } from 'commander';
import * as Handlebars from 'handlebars';
import * as path from 'path';
import * as fs from 'node:fs/promises';
import { kebabCase, min, startCase } from 'lodash';
import axios from 'axios';
import dotenv from 'dotenv';

dotenv.config();

// TODO Add tests

// TODO Move templates into tool directory
// TODO Determine path of this file and make source path relative to this file
const aocTokenEnv = 'AOC_TOKEN';
const typescriptDayTemplateSource = path.resolve(process.env.HOME!, 'projects/advent-of-code/template/typescript/day-{{day}}_{{title}}');
const readmePath = path.resolve('README.md');

const now = new Date();

const minDay = 1;
const maxDay = 25;
const currentDay = now.getDate();
const currentDayDefault = currentDay > maxDay ? undefined : currentDay.toString();

const minYear = 2015;
const currentYear = now.getFullYear();
const maxYear = now.getMonth() === 11 ? currentYear : currentYear - 1;
const currentYearDefault = currentYear.toString();

// TODO Add option to select template language
// TODO Add option to dry-run
const command = new Command()
  .argument('<output>', 'Path to the output directory')
  .requiredOption('-t, --title <title>', 'Title of the puzzle')
  .requiredOption('-d, --day <number>', `Number of the day [${minDay}-${maxDay}]`, parseDayNumber, currentDayDefault)
  .option('-y, --year <number>', `Number of the year [${minYear}-${maxYear}]`, parseYear, currentYearDefault)
  .option('-u, --update-readme', 'Add an entry for the generated file to the readme', true)
  .option('--no-update-readme', 'Do not update readme')
  .option('-i, --load-input', `Load puzzle input using ${aocTokenEnv} as session token`, true)
  .option('--no-load-input', 'Do not load the puzzle input')
  .action(generateDayFiles);
command.parse();

interface GenerateDayOptions {
  title: string;
  day: string;
  year: string;
  updateReadme: boolean;
  loadInput: boolean;
}

function parseDayNumber(value: string): string {
  if (!value.match(/^\d{1,2}$/)) {
    throw new InvalidArgumentError(`Must be a number between ${minDay} and ${maxDay}.`)
  }
  const dayNumber = Number(value);
  if (dayNumber < minDay || dayNumber > maxDay) {
    throw new InvalidArgumentError(`Must be a number between ${minDay} and ${maxDay}.`);
  }
  return dayNumber.toString();
}

function parseYear(value: string): string | boolean {
  if (!value.match(/^\d{4}$/)) {
    throw new InvalidArgumentError(`Must be a number between ${minYear} and ${maxYear}.`)
  }
  const yearNumber = Number(value);
  if (yearNumber < minYear || yearNumber > maxYear) {
    throw new InvalidArgumentError(`Must be a number between ${minYear} and ${maxYear}.`);
  }
  return yearNumber.toString();
}

async function generateDayFiles(output: string, options: GenerateDayOptions) {
  options.title = startCase(options.title.toLowerCase());
  const pathOptions = {
    ...options,
    title: kebabCase(options.title),
    day: options.day.padStart(2, '0')
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
    const outputContent = await renderFile(path.join(sourcePath, templateFile), options);
    await fs.writeFile(path.join(outputPath, outputFilename), outputContent);
  }
  console.log(`Files have been generated at ${path.relative(process.cwd(), outputPath)}`);

  if (options.updateReadme) {
    const readmeOptions = {
      ...options,
      directory: outputDirectory,
    };
    await addEntryToReadme(readmePath, readmeOptions);
  }

  if (options.loadInput) {
    if (!process.env[aocTokenEnv]) {
      console.log(`Error: ${aocTokenEnv} not found`)
    } else {
      const {year, day} = options;
      const inputFilePath = path.join(outputPath, 'input');
      await fetchPuzzleInput(year, day, inputFilePath);
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
    console.log(`Error - Unable to locate list header for year: ${options.year}`);
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
  console.log(`Added entry for Day '${options.day}: ${options.title}' to readme`);
}

async function fetchPuzzleInput(year: number | string, day: number | string, outputPath: string): Promise<void> {
  try {
    const response = await axios.get(`https://adventofcode.com/${year}/day/${day}/input`, {
      headers: {
        'Cookie': `session=${process.env[aocTokenEnv]}`
      }
    });
    await fs.writeFile(outputPath, response.data);
    console.log(`Puzzle input saved to ${path.relative(process.cwd(), outputPath)}`);
  } catch (error) {
    console.log(`Error fetching puzzle input - ${error}`)
  }
}

async function renderFile<T>(filePath: string, context: T): Promise<string> {
  return renderTemplate(await fs.readFile(filePath, 'utf-8'), context);
}

function renderTemplate<T>(template: string, context: T): string {
  const render = Handlebars.compile<T>(template);
  return render(context);
}
