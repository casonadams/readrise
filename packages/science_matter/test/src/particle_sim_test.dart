import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:science_matter/src/matter_state.dart';
import 'package:science_matter/src/particle_sim.dart';

ParticleSim settled(
  MatterState state, {
  double energy = 0.5,
  double seconds = 4,
}) {
  final sim = ParticleSim(random: Random(7));
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
      expect((p.y - p.homeY).abs(), lessThan(0.03));
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
}
