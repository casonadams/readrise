import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:science_kit/science_kit.dart';

ParticleSim settled(
  MatterState state, {
  double energy = 0.5,
  double seconds = 4,
  double height = 1,
}) {
  final sim = ParticleSim(random: Random(7))..fit(height);
  for (var i = 0; i < seconds * 60; i++) {
    sim.step(1 / 60, state, energy);
  }
  return sim;
}

double meanSpeed(ParticleSim sim) =>
    sim.particles
        .map((p) => sqrt(p.vx * p.vx + p.vy * p.vy))
        .reduce((a, b) => a + b) /
    sim.particles.length;

void main() {
  test('solid: particles stay near their lattice sites', () {
    final sim = settled(MatterState.solid);
    for (final p in sim.particles) {
      expect((p.x - p.homeX).abs(), lessThan(0.03));
      expect((p.y - (sim.height - p.homeDepth)).abs(), lessThan(0.03));
    }
  });

  test('liquid: particles stay in the lower part of the box', () {
    final sim = settled(MatterState.liquid);
    for (final p in sim.particles) {
      expect(p.y, greaterThanOrEqualTo(0.5));
      expect(p.x, inInclusiveRange(0, 1));
      expect(p.y, lessThanOrEqualTo(1));
    }
  });

  test('gas: particles spread through the whole box', () {
    final sim = settled(MatterState.gas, energy: 0.8);
    final ys = sim.particles.map((p) => p.y);
    expect(ys.reduce(min), lessThan(0.3));
    expect(ys.reduce(max), greaterThan(0.7));
    for (final p in sim.particles) {
      expect(p.x, inInclusiveRange(0, 1));
      expect(p.y, inInclusiveRange(0, 1));
    }
  });

  test('gas: particles fill a box wider than it is tall, edge to edge', () {
    final sim = settled(MatterState.gas, energy: 0.8, height: 0.3);
    expect(sim.width, closeTo(2, 1e-9));
    final xs = sim.particles.map((p) => p.x);
    expect(xs.reduce(min), lessThan(0.3));
    expect(xs.reduce(max), greaterThan(sim.width - 0.3));
  });

  test('solid: the lattice sits in the middle of a wide box', () {
    final sim = settled(MatterState.solid, height: 0.3);
    final xs = sim.particles.map((p) => p.x);
    final middle = (xs.reduce(min) + xs.reduce(max)) / 2;
    expect(middle, closeTo(sim.width / 2, 0.03));
  });

  test('more energy means faster particles', () {
    expect(
      meanSpeed(settled(MatterState.gas, energy: 1, seconds: 1)),
      greaterThan(meanSpeed(settled(MatterState.gas, energy: 0, seconds: 1))),
    );
    expect(
      meanSpeed(settled(MatterState.liquid, energy: 1, seconds: 1)),
      greaterThan(
        meanSpeed(settled(MatterState.liquid, energy: 0, seconds: 1)),
      ),
    );
  });

  test('gas is faster than liquid at the same energy', () {
    expect(
      meanSpeed(settled(MatterState.gas, seconds: 1)),
      greaterThan(meanSpeed(settled(MatterState.liquid, seconds: 1))),
    );
  });

  test('cooling a gas settles it into the lower box (condensing)', () {
    final sim = settled(MatterState.gas, seconds: 2);
    for (var i = 0; i < 6 * 60; i++) {
      sim.step(1 / 60, MatterState.liquid, 0.5);
    }
    for (final p in sim.particles) {
      expect(p.y, greaterThanOrEqualTo(0.5));
    }
  });

  test('a liquid does not pile particles on top of each other', () {
    final sim = settled(MatterState.liquid);
    var closest = double.infinity;
    for (var i = 0; i < sim.particles.length; i++) {
      for (var j = i + 1; j < sim.particles.length; j++) {
        final a = sim.particles[i], b = sim.particles[j];
        closest = min(closest, sqrt(pow(a.x - b.x, 2) + pow(a.y - b.y, 2)));
      }
    }
    expect(closest, greaterThan(ParticleSim.radius));
  });

  test('liquid: particles pool at the bottom instead of floating', () {
    final sim = settled(MatterState.liquid);
    final ys = sim.particles.map((p) => p.y).toList();
    expect(ys.reduce(min), greaterThan(0.68));
    expect(ys.reduce((a, b) => a + b) / ys.length, greaterThan(0.8));
  });

  test('gas: two particles meeting head on bounce off each other', () {
    final sim = ParticleSim(random: Random(7), columns: 2, rows: 1);
    final [a, b] = sim.particles;
    a
      ..x = 0.45
      ..y = 0.5
      ..vx = 0.5
      ..vy = 0;
    b
      ..x = 0.55
      ..y = 0.5
      ..vx = -0.5
      ..vy = 0;
    for (var i = 0; i < 10; i++) {
      sim.step(1 / 60, MatterState.gas, 0.3);
    }
    expect(a.vx, lessThan(0));
    expect(b.vx, greaterThan(0));
    expect(b.x - a.x, greaterThanOrEqualTo(ParticleSim.radius * 2 - 1e-9));
  });

  test('liquid: a heap against one wall levels out within a second', () {
    for (var seed = 0; seed < 6; seed++) {
      final sim = ParticleSim(random: Random(seed));
      for (final (i, p) in sim.particles.indexed) {
        p
          ..x = 0.96 - (i % 5) * 0.08
          ..y = 0.96 - (i ~/ 5) * 0.08
          ..vx = 0
          ..vy = 0;
      }
      for (var i = 0; i < 60; i++) {
        sim.step(1 / 60, MatterState.liquid, 0.5);
      }
      final xs = sim.particles.map((p) => p.x);
      final ys = sim.particles.map((p) => p.y);
      expect(xs.reduce(min), lessThan(0.12), reason: 'seed $seed');
      expect(ys.reduce(min), greaterThan(0.68), reason: 'seed $seed');
    }
  });

  group('in a box taller than it is wide', () {
    const height = 1.7;

    test('a solid rests on the floor', () {
      final sim = settled(MatterState.solid, height: height);
      final ys = sim.particles.map((p) => p.y);
      expect(ys.reduce(max), greaterThan(height - 0.15));
      expect(ys.reduce(min), greaterThan(height - 0.65));
    });

    test('a liquid pools at the bottom', () {
      final sim = settled(MatterState.liquid, height: height);
      for (final p in sim.particles) {
        expect(p.y, greaterThan(height - 0.35));
        expect(p.y, lessThanOrEqualTo(height));
      }
    });

    test('a gas fills the whole box', () {
      final sim = settled(MatterState.gas, energy: 0.8, height: height);
      final ys = sim.particles.map((p) => p.y);
      expect(ys.reduce(min), lessThan(0.4));
      expect(ys.reduce(max), greaterThan(height - 0.4));
      for (final p in sim.particles) {
        expect(p.y, inInclusiveRange(0, height));
      }
    });
  });

  test('fewer particles: the highest ones leave first', () {
    final sim = settled(MatterState.liquid);
    final ys = [for (final p in sim.particles) p.y]..sort();
    sim.resize(20);
    expect(sim.particles, hasLength(20));
    expect(
      sim.particles.map((p) => p.y).reduce(min),
      greaterThanOrEqualTo(ys[10]),
    );
  });

  test('more particles: new ones enter at the floor heading up', () {
    final sim = ParticleSim(random: Random(7))..resize(0);
    sim.resize(5);
    expect(sim.particles, hasLength(5));
    for (final p in sim.particles) {
      expect(p.y, closeTo(sim.height - ParticleSim.radius, 1e-9));
      expect(p.vy, lessThan(0));
    }
  });
}
