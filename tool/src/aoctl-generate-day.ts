#!/usr/bin/env node

import { Command, InvalidArgumentError } from 'commander';
import * as Handlebars from 'handlebars';
import * as path from 'path';
import * as fs from 'node:fs/promises';
import { kebabCase, startCase } from 'lodash';

const typescriptDayTemplateSource = path.resolve(process.env.HOME!, 'projects/advent-of-code/template/typescript/day-{{day}}_{{title}}');

const command = new Command()
  .argument('<output>', 'Path to the output directory')
  .option('-d, --day <number>', 'Number of the day', parseDayNumber, 'today')
  .requiredOption('-t, --title <title>', 'Title of the puzzle')
  .action(generateDayFiles);
command.parse();

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

async function generateDayFiles(output: string, options: {day: string, title: string}) {
  if (options.day === 'today') {
    const dayNumber = new Date().getDate();
    if (dayNumber <= 0 || dayNumber > 24) {
      throw new Error("Can't use 'today' for option --day. Must be between 1 and 24.");
    }
    options.day = `${dayNumber}`;
  }
  options.title = startCase(options.title.toLowerCase());
  const pathOptions = {
    ...options,
    title: kebabCase(options.title),
    day: options.day.padStart(2, '0')
  };

  const sourceDirectory = typescriptDayTemplateSource;
  output = path.join(path.resolve(output), renderTemplate(path.basename(sourceDirectory), pathOptions));
  const outputExists = await fs.access(output, fs.constants.F_OK)
    .then(() => true)
    .catch((error) => error.code === 'ENOENT' ? false : Promise.reject(error));
  if (outputExists) {
    console.log(`Error - Output directory already exists: ${path.relative(process.cwd(), output)}`);
    return;
  }
  await fs.mkdir(output, { recursive: true });

  const templateFiles = await fs.readdir(sourceDirectory);
  for (const templateFile of templateFiles) {
    const outputFilename = renderTemplate(templateFile, pathOptions);
    const outputContent = await renderFile(path.join(sourceDirectory, templateFile), options);
    await fs.writeFile(path.join(output, outputFilename), outputContent);
  }
  console.log(`Files have been generated at ${path.relative(process.cwd(), output)}`);
}

async function renderFile<T>(filePath: string, context: T): Promise<string> {
  return renderTemplate(await fs.readFile(filePath, 'utf-8'), context);
}

function renderTemplate<T>(template: string, context: T): string {
  const render = Handlebars.compile<T>(template);
  return render(context);
}
