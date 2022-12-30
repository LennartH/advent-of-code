const line = 'Blueprint 1: Each ore robot costs 4 ore. Each clay robot costs 2 ore. Each obsidian robot costs 3 ore and 14 clay. Each geode robot costs 2 ore and 7 obsidian.';

const pattern = /Each (?<resource>[a-z]+) robot costs (\d+ [a-z]+)(?: and (\d+ [a-z]+))*/g;

const result = [...line.matchAll(pattern)];
// console.log(result[0].slice(2).map((cost) => {
//   const [amount, resource] = cost.split(' ');
//   return [resource, Number(amount)];
// }));
console.log(Object.fromEntries([...line.matchAll(pattern)].map((match) => {
  return [match.groups!.resource, Object.fromEntries(match.slice(2).filter((v) => typeof v === 'string').map((cost) => {
    const [amount, resource] = cost.split(' ');
    return [resource, Number(amount)];
  }))];
})));
