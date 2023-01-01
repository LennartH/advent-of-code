import { splitLines } from '@util';

export enum ResourceType {
  Ore = 'ore',
  Clay = 'clay',
  Obsidian = 'obsidian',
  Geode = 'geode',
}
const resourceTypes = Object.values(ResourceType);

export interface RobotFactory {
  blueprints: FactoryBlueprint[];
}

interface FactoryBlueprint {
  recipes: Record<ResourceType, RobotRecipe>;
  limits: Record<Exclude<ResourceType, ResourceType.Geode>, number>;
}
type RobotRecipe = Partial<Record<ResourceType, number>>;

export interface RobotFactoryQuality {
  total: number;
  byBlueprint: number[];
}

const recipePattern = /Each (?<resource>[a-z]+) robot costs (\d+ [a-z]+)(?: and (\d+ [a-z]+))*/g;

export function parseRobotFactory(input: string): RobotFactory {
  const blueprints = splitLines(input).map((line) => {
    const recipes = Object.fromEntries([...line.matchAll(recipePattern)].map((match) => {
      return [match.groups!.resource, Object.fromEntries(match.slice(2).filter((v) => typeof v === 'string').map((cost) => {
        const [amount, resource] = cost.split(' ');
        return [resource, Number(amount)];
      }))];
    }));
    return {
      recipes,
      limits: {
        [ResourceType.Ore]: Math.max(...resourceTypes.map((r) => recipes[r][ResourceType.Ore])),
        [ResourceType.Clay]: recipes[ResourceType.Obsidian][ResourceType.Clay],
        [ResourceType.Obsidian]: recipes[ResourceType.Geode][ResourceType.Obsidian],
      }
    }
  }) as FactoryBlueprint[];
  return { blueprints };
}

interface FactoryState {
  blueprint: FactoryBlueprint;

  timeLeft: number;
  robots: Record<ResourceType, number>;
  resources: Record<ResourceType, number>;
}

export function calculateFactoryQuality(factory: RobotFactory, time: number): RobotFactoryQuality {
  const byBlueprint: number[] = factory.blueprints
    .map((b) => initializeState(b, time))
    .map((s) => calculateMaxGeodeCount(s));
  return {
    total: byBlueprint.reduce((s, v, i) => s + (v * (i + 1)), 0),
    byBlueprint,
  }
}

function initializeState(blueprint: FactoryBlueprint, time: number): FactoryState {
  return {
    blueprint,

    timeLeft: time,
    robots: {
      [ResourceType.Ore]: 1,
      [ResourceType.Clay]: 0,
      [ResourceType.Obsidian]: 0,
      [ResourceType.Geode]: 0,
    },
    resources: {
      [ResourceType.Ore]: 0,
      [ResourceType.Clay]: 0,
      [ResourceType.Obsidian]: 0,
      [ResourceType.Geode]: 0,
    },
  }
}

function calculateMaxGeodeCount(state: FactoryState): number {
  if (state.timeLeft <= 1) {
    return state.resources.geode;
  }
  let best = state.resources.geode;

  for (const robotType of resourceTypes) {
    if (robotType !== ResourceType.Geode && state.robots[robotType] >= state.blueprint.limits[robotType]) {
      continue;
    }
    const timeToBuild = timeUntilNextRobot(state, robotType);
    if (timeToBuild === null) {
      continue;
    }
    const nextState = buildRobot(state, robotType, timeToBuild);
    const nextGeodeLimit = calculateGeodeLimit(nextState);
    if (nextGeodeLimit <= best) {
      continue;
    }
    const score = calculateMaxGeodeCount(nextState);
    best = Math.max(best, score);
  }
  return best;
}

function buildRobot(state: FactoryState, robotType: ResourceType, timeToBuild: number): FactoryState {
  const nextState: FactoryState = {
    blueprint: state.blueprint,
    timeLeft: state.timeLeft,
    robots: { ...state.robots },
    resources: { ...state.resources },
  }
  resourceTypes.forEach((r) => {
    nextState.resources[r] += (nextState.robots[r] * Math.min(state.timeLeft, timeToBuild)) -
                              (nextState.blueprint.recipes[robotType][r] || 0);
  });
  nextState.robots[robotType]++;
  nextState.timeLeft -= timeToBuild;
  return nextState;
}

function timeUntilNextRobot(state: FactoryState, robotType: ResourceType): number | null {
  const recipe = state.blueprint.recipes[robotType];
  if (resourceTypes.some((r) => r in recipe && state.robots[r] === 0)) {
    return null;
  }
  const { resources, robots } = state;
  return (Object.entries(recipe) as [ResourceType, number][])
    .map(
      ([r, c]) => Math.ceil(Math.max(0, c - resources[r]) / robots[r])
    )
    .reduce((max, v) => v > max ? v : max, 0) + 1;
}

function calculateGeodeLimit(state: FactoryState): number {
  let count = state.resources.geode;
  let timeLeft = state.timeLeft;
  let additionalGeodeRobots = 0;
  while (timeLeft > 0) {
    count += state.robots.geode + additionalGeodeRobots;
    additionalGeodeRobots++;
    timeLeft--;
  }
  return count;
}
