#!/usr/bin/env node

import axios from 'axios';
import { Command, InvalidArgumentError, Option } from 'commander';
import dotenv from 'dotenv';
import * as Handlebars from 'handlebars';
import { kebabCase, startCase } from 'lodash';
import * as fs from 'node:fs/promises';
import * as fssync from 'fs';
import * as path from 'path';

const rootPath = path.resolve(__dirname, '../..');

dotenv.config({
  path: [
    '.env',
    path.join(rootPath, '.env'),
  ]
});

const aocTokenEnv = 'AOC_TOKEN';
const readmePath = path.join(rootPath, 'README.md');  // FIXME this changes the actual readme when testing stuff...
const templateDir = path.join(rootPath, 'template');
const languages = fssync.readdirSync(templateDir, { withFileTypes: true }) .filter(e => e.isDirectory()) .map(e => e.name);

const now = new Date();

const minDay = 1;
const maxDay = 25;
const currentDay = now.getDate();
const currentDayDefault = currentDay > maxDay ? undefined : currentDay.toString();

const minYear = 2015;
const currentYear = now.getFullYear();
const maxYear = now.getMonth() === 11 ? currentYear : currentYear - 1;
const currentYearDefault = currentYear.toString();

// TODO Add option to dry-run
// TODO Support adding additional language to an existing solution with fewer options (or as separate command)
const command = new Command()
  .argument('<output>', 'Path to the output directory')
  .addOption(new Option('-l, --language <language>', 'Template language to use').choices(languages).default('python').makeOptionMandatory())
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
  language: string;
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

  const sourcePath = path.resolve(templateDir, `${options.language}/day-{{day}}_{{title}}`);
  const outputDirectory = renderTemplate(path.basename(sourcePath), pathOptions);
  const outputPath = path.join(path.resolve(output), outputDirectory);
  const outputPathExists = await fs.access(outputPath, fs.constants.F_OK)
    .then(() => true)
    .catch((error) => error.code === 'ENOENT' ? false : Promise.reject(error));
  if (!outputPathExists) {
    await fs.mkdir(outputPath, { recursive: true });
  } else if (options.updateReadme) {
    console.log("Warning - Output directory already exists, readme will not be updated");
    options.updateReadme = false;
  }

  const templateFiles = await fs.readdir(sourcePath);
  for (const templateFile of templateFiles) {
    const outputFilename = renderTemplate(templateFile, pathOptions);
    const outputFilePath = path.join(outputPath, outputFilename);
    const outputFileExists = await fs.access(outputFilePath, fs.constants.F_OK)
      .then(() => true)
      .catch((error) => error.code === 'ENOENT' ? false : Promise.reject(error));
    if (outputFileExists) {
      console.log(`Warning - Skipping ${outputFilename}: File already exists`);
      continue;
    }

    const outputContent = await renderFile(path.join(sourcePath, templateFile), options);
    await fs.writeFile(outputFilePath, outputContent);
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
      // TODO Implement caching independent from title (e.g. cache downloaded input files by year and day in $HOME/.aoctl/inputs)
      const inputFilePath = path.join(outputPath, 'input');
      const inputFileExists = await fs.access(inputFilePath, fs.constants.F_OK)
        .then(() => true)
        .catch((error) => error.code === 'ENOENT' ? false : Promise.reject(error));
      if (inputFileExists) {
        console.log(`Info - Input file already exists`);
      } else {
        await fetchPuzzleInput(year, day, inputFilePath);
      }
    }
  }
}


// TODO Build relative path link from config instead of hard coded paths
// TODO Handle days with solutions in different languages
const solutionUrl: Record<string, ReturnType<typeof Handlebars.compile>> = {
  typescript: Handlebars.compile('./{{year}}/src/{{directory}}/index.ts'),
  duckdb: Handlebars.compile('./{{year}}/{{directory}}/solution.sql'),
  python: Handlebars.compile('./{{year}}/{{directory}}/solution.py'),
}
const puzzleUrl = Handlebars.compile('https://adventofcode.com/{{year}}/day/{{day}}');
const readmeListHeader = Handlebars.compile('### {{year}}');
const readmeEntry = Handlebars.compile('- **Day {{day}}: {{title}}** [Solution]({{solutionUrl}}) / [Puzzle]({{puzzleUrl}})');

async function addEntryToReadme(readmePath: string, options: {year: string, day: string, title: string, directory: string, language: string}) {
  let readmeContent = await fs.readFile(readmePath, 'utf-8');

  const listHeader = readmeListHeader(options);
  let headerIndex = readmeContent.indexOf(listHeader);
  let listStartIndex = readmeContent.indexOf('\n-', headerIndex) + 1;
  if (headerIndex < 0) {
    const yearValue = Number(options.year);
    const yearHeaders = readmeContent.match(/### \d{4}/g) || [];
    const existingYears = yearHeaders?.map((h) => Number(h.split(' ')[1]));

    if (existingYears.length === 0 || yearValue < Math.min(...existingYears)) {
      readmeContent += `\n${listHeader}\n\n`;
    } else {
      for (let i = 0; i < existingYears.length; i++) {
        const currentYear = existingYears[i];
        if (yearValue > currentYear) {
          const nextHeaderIndex = readmeContent.indexOf(yearHeaders[i]);
          readmeContent = readmeContent.slice(0, nextHeaderIndex) + `${listHeader}\n\n` + readmeContent.slice(nextHeaderIndex);
          break;
        }
      }
    }

    headerIndex = readmeContent.indexOf(listHeader);
    listStartIndex = headerIndex + listHeader.length + 2;
  }

  // TODO Insert at correct position if days are done out of order
  const beforeList = readmeContent.slice(0, listStartIndex);
  const afterList = readmeContent.slice(listStartIndex);
  const newEntry = readmeEntry({
    ...options,
    solutionUrl: solutionUrl[options.language](options),
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
        'User-Agent': 'github.com/LennartH/advent-of-code/tree/main/tool',
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
