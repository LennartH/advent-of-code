import { Point2D, PointLike } from './point';

describe('create point', () => {
  test.each<[string, PointLike, Point2D]>([
    ['from plain object', { x: 1, y: 2 }, new Point2D(1, 2)],
    ['from delta object', { deltaX: 1, deltaY: 2 }, new Point2D(1, 2)],
    ['from dx object', { dx: 1, dy: 2 }, new Point2D(1, 2)],
    ['from size object', { width: 1, height: 2 }, new Point2D(1, 2)],
    ['from tuple', [1, 2], new Point2D(1, 2)],
    ['from array', [1, 2, 3] as never, new Point2D(1, 2)],
  ])('%s', (_, data, expected) => {
    const point = new Point2D(data);
    expect(point).toEqual(expected);
  });
  test('from no-args constructor', () => {
    const point = new Point2D();
    expect(point).toEqual(new Point2D(0, 0));
  });
});

describe('as string', () => {
  const point = new Point2D(-1,1);
  test('short', () => expect(point.toString()).toEqual('-1,1'));
  test('short', () => expect(point.toString(true)).toEqual('(-1, 1)'));
})

describe('euclidean distance', () => {
  test.each([
    [  'I', new Point2D( 3,  7), 7.61577],
    [ 'II', new Point2D(-3,  7), 7.61577],
    ['III', new Point2D(-3, -7), 7.61577],
    [ 'IV', new Point2D( 3, -7), 7.61577],
  ])('of point in quadrant %s to origin', (_, point, expected) => {
    expect(point.euclideanDistanceTo(0, 0)).toBeCloseTo(expected, 4);
  })
  test.each([
    [  'I', [new Point2D(1, 2), new Point2D( 3,  7)], 5.38516],
    [ 'II', [new Point2D(1, 2), new Point2D(-3,  7)], 6.40312],
    ['III', [new Point2D(1, 2), new Point2D(-3, -7)], 9.84886],
    [ 'IV', [new Point2D(1, 2), new Point2D( 3, -7)], 9.21954],
  ])('between points with quadrant %s relation', (_, [p1, p2], expected) => {
    expect(p1.euclideanDistanceTo(p2)).toBeCloseTo(expected, 4);
    expect(p2.euclideanDistanceTo(p1)).toBeCloseTo(expected, 4);
  })

  describe('squared', () => {
    test.each([
      [  'I', new Point2D( 3,  7), 58],
      [ 'II', new Point2D(-3,  7), 58],
      ['III', new Point2D(-3, -7), 58],
      [ 'IV', new Point2D( 3, -7), 58],
    ])('of point in quadrant %s to origin', (_, point, expected) => {
      expect(point.euclideanDistanceSquaredTo(0, 0)).toBe(expected);
    })
    test.each([
      [  'I', [new Point2D(1, 2), new Point2D( 3,  7)], 29],
      [ 'II', [new Point2D(1, 2), new Point2D(-3,  7)], 41],
      ['III', [new Point2D(1, 2), new Point2D(-3, -7)], 97],
      [ 'IV', [new Point2D(1, 2), new Point2D( 3, -7)], 85],
    ])('between points with quadrant %s relation', (_, [p1, p2], expected) => {
      expect(p1.euclideanDistanceSquaredTo(p2)).toBe(expected);
      expect(p2.euclideanDistanceSquaredTo(p1)).toBe(expected);
    })
  })
})

describe('manhattan distance', () => {
  test.each([
    [  'I', new Point2D( 3,  7), 10],
    [ 'II', new Point2D(-3,  7), 10],
    ['III', new Point2D(-3, -7), 10],
    [ 'IV', new Point2D( 3, -7), 10],
  ])('of point in quadrant %s to origin', (_, point, expected) => {
    expect(point.manhattanDistanceTo(0, 0)).toBeCloseTo(expected, 4);
  })
  test.each([
    [  'I', [new Point2D(1, 2), new Point2D( 3,  7)],  7],
    [ 'II', [new Point2D(1, 2), new Point2D(-3,  7)],  9],
    ['III', [new Point2D(1, 2), new Point2D(-3, -7)], 13],
    [ 'IV', [new Point2D(1, 2), new Point2D( 3, -7)], 11],
  ])('between points with quadrant %s relation', (_, [p1, p2], expected) => {
    expect(p1.manhattanDistanceTo(p2)).toBeCloseTo(expected, 4);
    expect(p2.manhattanDistanceTo(p1)).toBeCloseTo(expected, 4);
  })
});

describe('basic operations', () => {
  type BasicOperationArgs = [number] | [number, number] | [PointLike];

  test.each<[string, BasicOperationArgs, Point2D]>([
    ['scalar', [1], new Point2D(1, 1)],
    ['x and y', [1, 2], new Point2D(1, 2)],
    ['plain object', [{x: 1, y: 2}], new Point2D(1, 2)],
  ])('translate by %s', (_, args, expected) => {
    const point = new Point2D();
    point.translateBy(args[0] as never, args[1] as never);
    expect(point).toEqual(expected);
  });

  test.each<[string, BasicOperationArgs, Point2D]>([
    ['scalar', [2], new Point2D(2, 2)],
    ['x and y', [2, 3], new Point2D(2, 3)],
    ['plain object', [{x: 2, y: 3}], new Point2D(2, 3)],
  ])('scale by %s', (_, args, expected) => {
    const point = new Point2D(1, 1);
    point.scaleBy(args[0] as never, args[1] as never);
    expect(point).toEqual(expected);
  });
});

describe('clamp', () => {
  test.each<[string, [number, number], Point2D, Point2D]>([
    ['that is larger', [10, 15], new Point2D(1, 12), new Point2D(10, 12)],
    ['that is smaller', [-3, 3], new Point2D(1, 12), new Point2D(1, 3)],
    ['that is around', [-3, 15], new Point2D(1, 12), new Point2D(1, 12)],
  ])('by scalar %s', (_, [min, max], point, expected) => {
    point = point.clone().clamp(min, max);
    expect(point).toEqual(expected);
  })
  test.each<[string, [PointLike, PointLike], Point2D, Point2D]>([
    ['that is larger', [{x: 3, y: 15}, {x: 30, y: 30}], new Point2D(1, 12), new Point2D(3, 15)],
    ['that is smaller', [{x: -3, y: -3}, {x: -1, y: 10}], new Point2D(1, 12), new Point2D(-1, 10)],
    ['that is around', [{x: -3, y: 10}, {x: 4, y: 15}], new Point2D(1, 12), new Point2D(1, 12)],
  ])('by point %s', (_, [min, max], point, expected) => {
    point = point.clone().clamp(min, max);
    expect(point).toEqual(expected);
  })
});
