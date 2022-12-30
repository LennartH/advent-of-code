import { splitLines } from '@util';

export enum Resource {
  Ore = 'ore',
  Clay = 'clay',
  Obsidian = 'obsidian',
  Geode = 'geode',
}
const allResources = [Resource.Ore, Resource.Clay, Resource.Obsidian, Resource.Geode];

export interface RobotFactory {
  blueprints: FactoryBlueprint[];
}

type FactoryBlueprint = Record<Resource, RobotRecipe>;
type RobotRecipe = Partial<Record<Resource, number>>;

export interface RobotFactoryQuality {
  total: number;
  byBlueprint: number[];
}

const recipePattern = /Each (?<resource>[a-z]+) robot costs (\d+ [a-z]+)(?: and (\d+ [a-z]+))*/g;

export function parseRobotFactory(input: string): RobotFactory {
  const blueprints = splitLines(input).map((line) => Object.fromEntries([...line.matchAll(recipePattern)].map((match) => {
    return [match.groups!.resource, Object.fromEntries(match.slice(2).filter((v) => typeof v === 'string').map((cost) => {
      const [amount, resource] = cost.split(' ');
      return [resource, Number(amount)];
    }))];
  }))) as FactoryBlueprint[];
  return { blueprints };
}

interface FactoryState {
  blueprint: FactoryBlueprint;

  elapsedMinutes: number;
  resources: Record<Resource, number>;
  resourcesPerMinute: Record<Resource, number>;
}

export function calculateFactoryQuality(factory: RobotFactory, minutes: number): RobotFactoryQuality {
  const byBlueprint: number[] = factory.blueprints.map((b, i) => calculateBlueprintQuality(i + 1, b, minutes));
  return {
    total: byBlueprint.reduce((s, v, i) => s + (v * (i + 1)), 0),
    byBlueprint,
  }
}

function calculateBlueprintQuality(id: number, blueprint: FactoryBlueprint, minutes: number): number {
  console.log(`\n\n##########################\n### Blueprint ${id < 10 ? id + ' ' : id} #########\n##########################`)
  const state = createStateForBlueprint(blueprint);
  while (state.elapsedMinutes < minutes) {
    state.elapsedMinutes++;
    console.log(`\n== Minute ${state.elapsedMinutes} ==`)

    console.log('-- Debug Info')
    console.log(`      Robots: ${allResources.map((r) => `${robotsPerMinute(state, r)} ${r} robot/m`).join(' | ')}`)
    console.log(`  Geode Gain: ${allResources.filter((r) => r !== Resource.Geode).map((r) => `${geodeGainForResource(state, r, 1)} per ${r}`).join(' | ')}`)
    console.log(`  Time Until: ${allResources.map((resource) => {
      const timeUntilCompletion = minutesUntilNextRobot(state, resource);
      return timeUntilCompletion != null ? `${timeUntilCompletion}m until ${resource} robot` : `Unable to build ${resource} robot`;
    }).join(' | ')}`)
    // console.log(`  Fitness #1: ${allResources.map((resource) => {
    //   let score = 0;
    //   const geodeGain = resource === Resource.Geode ? 1 : geodeGainForResource(state, resource, 1);
    //   const timeUntilCompletion = minutesUntilNextRobot(state, resource);
    //   if (timeUntilCompletion != null) {
    //     const timeLeftAfterCompletion = Math.max(0, minutes - timeUntilCompletion - state.elapsedMinutes);
    //     score = timeLeftAfterCompletion * geodeGain;
    //   }
    //   return `${score} if ${resource} robot`
    // }).join(' | ')}`)
    console.log(`  Fitness #2: ${allResources.map((resource) => {
      let score = 0;
      const geodeGain = resource === Resource.Geode ? 1 : geodeGainForResource(state, resource, 1);
      const timeUntilCompletion = minutesUntilNextRobot(state, resource);
      if (timeUntilCompletion != null) {
        const timeLeftAfterCompletion = Math.max(0, minutes - timeUntilCompletion - state.elapsedMinutes);
        const robotsRate = robotsPerMinute(state, resource);
        score = robotsRate * timeLeftAfterCompletion * geodeGain;
      }
      return `${score} if ${resource} robot`
    }).join(' | ')}`)
    console.log('-------------')

    const robotToBuild = chooseRobotToBuild(state, minutes);
    let robotCanBeBuild = canBuildRecipe(state, robotToBuild);
    console.log(`  Building a ${robotToBuild} robot next would be best.`)

    if (robotCanBeBuild) {
      const recipe = state.blueprint[robotToBuild];
      buildRobot(state, robotToBuild);
      console.log(`  Spend ${allResources.filter((r) => (recipe[r] || 0 > 0)).map((r) => `${recipe[r]} ${r}`).join(' and ')} to start building a ${robotToBuild} robot.`);
    }

    for (const resource of allResources) {
      const resourcePerMinute = state.resourcesPerMinute[resource];
      state.resources[resource] += resourcePerMinute;
      if (resourcePerMinute > 0) {
        console.log(`  ${resourcePerMinute} ${resource} robot collect ${resourcePerMinute} ${resource}; you now have ${state.resources[resource]} ${resource}.`);
      }
    }

    if (robotCanBeBuild) {
      state.resourcesPerMinute[robotToBuild]++;
      console.log(`  The new ${robotToBuild} robot is ready; you now have ${state.resourcesPerMinute[robotToBuild]} of them.`)
    }
  }
  return state.resources.geode;
}

function chooseRobotToBuild(state: FactoryState, totalMinutes: number): Resource {
  // const scoreByResource = Object.fromEntries(allResources.map((resource) => {
  //   let score = 0;
  //   const geodeGain = resource === Resource.Geode ? 1 : geodeGainForResource(state, resource, 1);
  //   const timeUntilCompletion = minutesUntilNextRobot(state, resource);
  //   if (timeUntilCompletion != null) {
  //     const timeLeftAfterCompletion = Math.max(0, totalMinutes - timeUntilCompletion - state.elapsedMinutes);
  //     const robotsRate = robotsPerMinute(state, resource);
  //     score = robotsRate * timeLeftAfterCompletion * geodeGain;
  //   }
  //   return [resource, score];
  // }))
  // const orderedResources = [...allResources];
  // orderedResources.sort((a, b) => scoreByResource[b] - scoreByResource[a]);

  const buildTime = Object.fromEntries(allResources.map((r) => [r, minutesUntilNextRobot(state, r)]));
  const geodeGain = Object.fromEntries(allResources.map((r) => [r, r === Resource.Geode ? 1 : geodeGainForResource(state, r, 1)]));
  const orderedResources = [...allResources].sort((a, b) => {
    const dtA = buildTime[a];
    const dtB = buildTime[b];
    if (dtA == null || dtB == null) {
      if (dtA == null && dtB == null) {
        return 0;
      }
      return dtA == null ? 1 : -1;
    }
    if (Math.abs(dtA - dtB) < 3) {
      return geodeGain[b] - geodeGain[a];
    }
    return dtA - dtB;
  })
  console.log(`  -- Resource Priority: ${orderedResources.join(', ')}`)
  return orderedResources[0];
}

function minutesUntilNextRobot(state: FactoryState, forResource: Resource): number | null {
  const recipe = state.blueprint[forResource];
  if (allResources.some((r) => r in recipe && state.resourcesPerMinute[r] === 0)) {
    return null;
  }
  const { resources, resourcesPerMinute } = state;
  return (Object.entries(recipe) as [Resource, number][])
    .map(
      ([r, c]) => Math.ceil(Math.max(0, c - resources[r]) / resourcesPerMinute[r])
    )
    .reduce((max, v) => v > max ? v : max, 0) + 1;
}

function canBuildRecipe(state: FactoryState, forResource: Resource): boolean {
  const { blueprint, resources } = state;
  const recipe = blueprint[forResource];
  for (const resource of allResources) {
    if (resources[resource] < (recipe[resource] || 0)) {
      return false;
    }
  }
  return true;
}

function buildRobot(state: FactoryState, forResource: Resource) {
  const { blueprint, resources } = state;
  const recipe = blueprint[forResource];
  for (const resource of allResources) {
    resources[resource] -= recipe[resource] || 0;
  }
}

function geodeGainForResource(state: FactoryState, forResource: Resource, resourceDelta: number): number {
  if (forResource === Resource.Ore) {
    const currentClayRobotRate = robotsPerMinute(state, Resource.Clay);
    const adjustedClayRobotRate = robotsPerMinute(state, Resource.Clay, {[Resource.Ore]: resourceDelta});
    const geodeGainIfClay = geodeGainForResource(state, Resource.Clay, adjustedClayRobotRate - currentClayRobotRate);

    const currentObsidianRobotRate = robotsPerMinute(state, Resource.Obsidian);
    const adjustedObsidianRobotRate = robotsPerMinute(state, Resource.Obsidian, {[Resource.Ore]: resourceDelta});
    const geodeGainIfObsidian = geodeGainForResource(state, Resource.Obsidian, adjustedObsidianRobotRate - currentObsidianRobotRate);

    return Math.max(geodeGainIfClay, geodeGainIfObsidian);
  } else if (forResource === Resource.Clay) {
    const currentObsidianRobotRate = robotsPerMinute(state, Resource.Obsidian);
    const adjustedObsidianRobotRate = robotsPerMinute(state, Resource.Obsidian, {[Resource.Clay]: resourceDelta});
    return geodeGainForResource(state, Resource.Obsidian, adjustedObsidianRobotRate - currentObsidianRobotRate);
  } else if (forResource === Resource.Obsidian) {
    const currentGeodeRobotRate = robotsPerMinute(state, Resource.Geode);
    const adjustedGeodeRobotRate = robotsPerMinute(state, Resource.Geode, {[Resource.Obsidian]: resourceDelta})
    return adjustedGeodeRobotRate - currentGeodeRobotRate;
  }
  throw new Error(`Not implemented for resource '${forResource}'`)
}

function robotsPerMinute(state: FactoryState, forResource: Resource, resourcesDelta: Partial<Record<Resource, number>> = {}): number {
  const { blueprint, resourcesPerMinute } = state;
  const recipe = blueprint[forResource];
  let buildSpeed = Number.MAX_SAFE_INTEGER;
  for (const resource of allResources) {
    if (resource in recipe) {
      const resourcePerMinute = resourcesPerMinute[resource] + (resourcesDelta[resource] || 0);
      if (resourcePerMinute === 0) {
        return 0;
      }
      buildSpeed = Math.min(buildSpeed, resourcePerMinute / recipe[resource]!)
    }
  }
  return buildSpeed;
}

function createStateForBlueprint(blueprint: FactoryBlueprint): FactoryState {
  return {
    elapsedMinutes: 0,

    blueprint,
    resources: {
      [Resource.Ore]: 0,
      [Resource.Clay]: 0,
      [Resource.Obsidian]: 0,
      [Resource.Geode]: 0,
    },
    resourcesPerMinute: {
      [Resource.Ore]: 1,
      [Resource.Clay]: 0,
      [Resource.Obsidian]: 0,
      [Resource.Geode]: 0,
    },
  }
}
