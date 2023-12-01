#!/usr/bin/env node

import { Command, InvalidArgumentError } from 'commander';
import * as Handlebars from 'handlebars';
import * as path from 'path';
import * as fs from 'node:fs/promises';

const typescriptDayTemplateSource = path.resolve('../template/typescript/day-{{day}}_{{title}}');

async function generateDayFiles(output: string, options: {day: string, title: string}) {
  if (options.day === 'today') {
    const dayNumber = new Date().getDate();
    if (dayNumber <= 0 || dayNumber > 24) {
      throw new Error("Can't use 'today' for option --day. Must be between 1 and 24.");
    }
    options.day = `${dayNumber}`;
  }
  const pathOptions = {...options, day: options.day.padStart(2, '0')};

  // TODO Use inquirer for missing options

  const sourceDirectory = typescriptDayTemplateSource;
  const outputDirectoryTemplate = Handlebars.compile(path.basename(sourceDirectory));
  output = path.join(path.resolve(output), outputDirectoryTemplate(pathOptions));
  const outputExists = await fs.access(output, fs.constants.F_OK)
    .then(() => true)
    .catch((error) => error.code === 'ENOENT' ? false : Promise.reject(error));
  if (outputExists) {
    console.log(`Error - Output directory already exists: ${path.relative(process.cwd(), output)}`);
    return;
  } else {
    await fs.mkdir(output, { recursive: true });
  }

  const templateFiles = await fs.readdir(sourceDirectory);
  for (const templateFile of templateFiles) {
    const outputFilenameTemplate = Handlebars.compile(templateFile);
    const outputFilename = outputFilenameTemplate(pathOptions);

    const fileTemplate = Handlebars.compile(await fs.readFile(path.join(sourceDirectory, templateFile), 'utf-8'));
    await fs.writeFile(path.join(output, outputFilename), fileTemplate(options));
  }
  console.log(`Files have been generated at ${path.relative(process.cwd(), output)}`);
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

const program = new Command();
program
  .version('0.1.0')
  .showHelpAfterError();

const generateCommand = program
  .command('generate')
  .description('Generate advent of code elements from template files');

generateCommand
  .command('day')
  .description('Generate base files to solve a days puzzle')
  .argument('<output>', 'Path to the output directory')
  .option('-d, --day <number>', 'Number of the day', parseDayNumber, 'today')
  .requiredOption('-t, --title <title>', 'Title of the puzzle')
  .action(generateDayFiles);

program.parse();
