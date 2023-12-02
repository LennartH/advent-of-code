#!/usr/bin/env node

import { Command } from 'commander';

const program = new Command();
program
  .name('aoctl')
  .version('0.1.0')
  .description('Simple tooling for advent of code')
  .showHelpAfterError();

program
  .command('generate', 'Generate advent of code elements from template files');

program.parse();
