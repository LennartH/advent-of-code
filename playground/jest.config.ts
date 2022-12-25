import type { JestConfigWithTsJest } from 'ts-jest';
import { pathsToModuleNameMapper } from 'ts-jest';
import * as fs from 'fs';

const { compilerOptions } = JSON.parse(fs.readFileSync(`${__dirname}/./tsconfig.json`, 'utf-8'))

/*
 * For a detailed explanation regarding each configuration property and type check, visit:
 * https://jestjs.io/docs/configuration
 */
const jestConfig: JestConfigWithTsJest = {
  preset: 'ts-jest',
  clearMocks: true,
  collectCoverage: false,

  roots: compilerOptions.rootDirs,
  modulePaths: [compilerOptions.baseUrl],
  moduleNameMapper: pathsToModuleNameMapper(compilerOptions.paths, { prefix: '<rootDir>/' }),
};

export default jestConfig;
