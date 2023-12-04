#!/usr/bin/env node

import { Command } from 'commander';

const command = new Command()
  .command('day <output>', 'Generate base files to solve a days puzzle')

command.parse();
