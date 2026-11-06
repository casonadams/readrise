import 'dart:math';

import 'matter_state.dart';

class Particle {
  Particle({
    required this.homeX,
    required this.homeY,
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.phase,
  });

  final double homeX;
  final double homeY;
  final double phase;
  double x;
  double y;
  double vx;
  double vy;
}

/// A qualitative particle model in a unit square (y grows downward).
/// Solid: particles vibrate around lattice sites. Liquid: they move past each
/// other in the lower part of the box. Gas: they fly through the whole box.
class ParticleSim {
  ParticleSim({Random? random, this.columns = 6, this.rows = 5})
    : _random = random ?? Random() {
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < columns; c++) {
        final homeX = 0.15 + c * 0.14;
        final homeY = 0.5 + r * 0.1;
        final angle = _random.nextDouble() * 2 * pi;
        particles.add(
          Particle(
            homeX: homeX,
            homeY: homeY,
            x: homeX,
            y: homeY,
            vx: cos(angle),
            vy: sin(angle),
            phase: _random.nextDouble() * 2 * pi,
          ),
        );
      }
    }
  }

  static const radius = 0.04;
  static const _liquidTop = 0.55;

  final int columns;
  final int rows;
  final Random _random;
  final List<Particle> particles = [];
  double _time = 0;

  /// Advances the simulation by [dt] seconds. [energy] is 0..1.
  void step(double dt, MatterState state, double energy) {
    _time += dt;
    switch (state) {
      case MatterState.solid:
        _vibrate(dt, energy);
      case MatterState.liquid:
        _drift(dt, speed: 0.12 + 0.12 * energy, top: _liquidTop);
        _separate();
      case MatterState.gas:
        _drift(dt, speed: 0.35 + 0.35 * energy, top: 0);
    }
  }

  void _vibrate(double dt, double energy) {
    final amplitude = 0.008 + 0.014 * energy;
    final pull = min(1.0, 8 * dt);
    for (final p in particles) {
      final tx = p.homeX + amplitude * sin(_time * 18 + p.phase);
      final ty = p.homeY + amplitude * cos(_time * 15 + p.phase);
      p.x += (tx - p.x) * pull;
      p.y += (ty - p.y) * pull;
    }
  }

  void _drift(double dt, {required double speed, required double top}) {
    const minX = radius;
    const maxX = 1 - radius;
    const maxY = 1 - radius;
    final minY = top + radius;
    for (final p in particles) {
      final norm = sqrt(p.vx * p.vx + p.vy * p.vy);
      p.vx = p.vx / norm * speed;
      p.vy = p.vy / norm * speed;
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      if (p.x < minX) {
        p.x = minX;
        p.vx = p.vx.abs();
      } else if (p.x > maxX) {
        p.x = maxX;
        p.vx = -p.vx.abs();
      }
      if (p.y > maxY) {
        p.y = maxY;
        p.vy = -p.vy.abs();
      } else if (p.y < minY) {
        p.y = p.y < top ? p.y + 0.4 * dt : minY;
        p.vy = p.vy.abs();
      }
    }
  }

  /// Keeps liquid particles touching but not overlapping.
  void _separate() {
    const minDistance = radius * 2;
    for (var i = 0; i < particles.length; i++) {
      for (var j = i + 1; j < particles.length; j++) {
        final a = particles[i];
        final b = particles[j];
        final dx = b.x - a.x;
        final dy = b.y - a.y;
        final distance = sqrt(dx * dx + dy * dy);
        if (distance >= minDistance || distance == 0) continue;
        final push = (minDistance - distance) / 2 / distance;
        a.x -= dx * push;
        a.y -= dy * push;
        b.x += dx * push;
        b.y += dy * push;
      }
    }
  }
}
