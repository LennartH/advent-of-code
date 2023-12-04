#!/usr/bin/env node

import { Command, InvalidArgumentError } from 'commander';
import * as Handlebars from 'handlebars';
import * as path from 'path';
import * as fs from 'node:fs/promises';
import { kebabCase, startCase } from 'lodash';

// TODO Add tests

// TODO Move templates into tool directory
// TODO Determine path of this file and make source path relative to this file
const typescriptDayTemplateSource = path.resolve(process.env.HOME!, 'projects/advent-of-code/template/typescript/day-{{day}}_{{title}}');
const readmePath = path.resolve('README.md');

// TODO Add option to select template language
// TODO Add option to load puzzle input from API
const command = new Command()
  .argument('<output>', 'Path to the output directory')
  .option('-d, --day <number>', 'Number of the day', parseDayNumber, 'today')
  .requiredOption('-t, --title <title>', 'Title of the puzzle')
  .option('-u, --update-readme [year]', 'Add entry for the current or given year to the readme', parseYear, true)
  .option('--no-update-readme', 'Do not update readme')
  .action(generateDayFiles);
command.parse();

interface GenerateDayOptions {
  day: string;
  title: string;
  updateReadme: boolean | string;
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
      year: contentOptions.updateReadme as string,
      day: contentOptions.day,
      title: contentOptions.title,
      directory: outputDirectory,
    }
    await addEntryToReadme(readmePath, readmeOptions);
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

function cleanOptions(options: GenerateDayOptions): Required<GenerateDayOptions> {
  const {title, day, updateReadme} = options;

  const cleaned: Required<GenerateDayOptions> = {} as never;
  cleaned.title = startCase(title.toLowerCase());
  cleaned.updateReadme = updateReadme === true ? `${new Date().getFullYear()}` : updateReadme;

  if (day === 'today') {
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
