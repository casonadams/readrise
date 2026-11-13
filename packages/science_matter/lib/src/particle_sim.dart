import 'dart:math';

import 'matter_state.dart';

class Particle {
  Particle({
    required this.homeX,
    required this.homeDepth,
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.phase,
  });

  /// Where this particle sits in a solid: across from the left wall, and up
  /// from the floor.
  final double homeX;
  final double homeDepth;
  final double phase;
  double x;
  double y;
  double vx;
  double vy;
}

/// A qualitative particle model in a box [width] by [height] units, shaped
/// like the view that shows it (y grows downward). Solid: particles vibrate
/// around lattice sites on the floor. Liquid: gravity pools them at the
/// bottom, where they jostle, slide past each other, and level out. Gas: they
/// fly through the whole box and bounce off each other and the walls.
class ParticleSim {
  ParticleSim({Random? random, this.columns = 6, this.rows = 5})
    : _random = random ?? Random() {
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < columns; c++) {
        final homeX = 0.15 + c * 0.14;
        final homeDepth = 0.1 + r * 0.1;
        final angle = _random.nextDouble() * 2 * pi;
        particles.add(
          Particle(
            homeX: homeX,
            homeDepth: homeDepth,
            x: homeX,
            y: height - homeDepth,
            vx: cos(angle),
            vy: sin(angle),
            phase: _random.nextDouble() * 2 * pi,
          ),
        );
      }
    }
  }

  static const radius = 0.04;

  /// The shortest box the solid lattice fits in.
  static const minHeight = 0.6;

  static const _gravity = 4.0;
  static const _maxLiquidSpeed = 1.2;
  static const _liquidPasses = 4;

  final int columns;
  final int rows;
  final Random _random;
  final List<Particle> particles = [];
  double _time = 0;
  double _width = 1;
  double _height = 1;

  /// The box's width: 1, or more when the box is flatter than [minHeight].
  double get width => _width;

  /// The box's height, at least [minHeight].
  double get height => _height;

  /// Gives the box the real shape of its view: [aspect] is height over width.
  /// A box flatter than [minHeight] grows wider instead, so particles fill
  /// all of it and the solid lattice still fits.
  void fit(double aspect) {
    _height = max(minHeight, aspect);
    _width = _height / aspect;
  }

  /// Advances the simulation by [dt] seconds. [energy] is 0..1.
  void step(double dt, MatterState state, double energy) {
    if (dt <= 0) return;
    _time += dt;
    switch (state) {
      case MatterState.solid:
        _vibrate(dt, energy);
      case MatterState.liquid:
        _pour(dt, energy);
      case MatterState.gas:
        _fly(dt, energy);
    }
  }

  void _vibrate(double dt, double energy) {
    final amplitude = 0.008 + 0.014 * energy;
    final pull = min(1.0, 8 * dt);
    for (final p in particles) {
      final tx =
          p.homeX + (width - 1) / 2 + amplitude * sin(_time * 18 + p.phase);
      final ty = height - p.homeDepth + amplitude * cos(_time * 15 + p.phase);
      p.x += (tx - p.x) * pull;
      p.y += (ty - p.y) * pull;
    }
  }

  /// Gravity and thermal kicks move the particles; overlaps are then pushed
  /// apart and those pushes become velocity, so a heap flows and levels out
  /// like water instead of standing like sand.
  void _pour(double dt, double energy) {
    final kick = (0.4 + 0.8 * energy) * sqrt(dt);
    final damping = 1 - min(1.0, dt);
    final startX = [for (final p in particles) p.x];
    final startY = [for (final p in particles) p.y];
    for (final p in particles) {
      p.vx = (p.vx + (_random.nextDouble() * 2 - 1) * kick) * damping;
      p.vy =
          (p.vy + (_random.nextDouble() * 2 - 1) * kick + _gravity * dt) *
          damping;
      p.x += p.vx * dt;
      p.y += p.vy * dt;
    }
    for (var pass = 0; pass < _liquidPasses; pass++) {
      _separate();
      _keepInside();
    }
    for (final (i, p) in particles.indexed) {
      p.vx = (p.x - startX[i]) / dt;
      p.vy = (p.y - startY[i]) / dt;
      final speed = sqrt(p.vx * p.vx + p.vy * p.vy);
      if (speed > _maxLiquidSpeed) {
        p.vx *= _maxLiquidSpeed / speed;
        p.vy *= _maxLiquidSpeed / speed;
      }
    }
  }

  /// Free flight with elastic bounces; a thermostat sets the average speed
  /// from [energy] without forcing every particle to the same speed.
  void _fly(double dt, double energy) {
    final target = 0.35 + 0.35 * energy;
    var sum = 0.0;
    for (final p in particles) {
      sum += p.vx * p.vx + p.vy * p.vy;
    }
    final rms = sqrt(sum / particles.length);
    if (rms < 1e-6) {
      for (final p in particles) {
        final angle = _random.nextDouble() * 2 * pi;
        p.vx = cos(angle) * target;
        p.vy = sin(angle) * target;
      }
    } else {
      final scale = 1 + (target / rms - 1) * min(1.0, 4 * dt);
      for (final p in particles) {
        p.vx *= scale;
        p.vy *= scale;
      }
    }
    for (final p in particles) {
      p.x += p.vx * dt;
      p.y += p.vy * dt;
    }
    _bounceOffWalls();
    _collide();
  }

  void _keepInside() {
    const low = radius;
    final right = width - radius;
    final floor = height - radius;
    for (final p in particles) {
      p.x = p.x.clamp(low, right);
      p.y = p.y.clamp(low, floor);
    }
  }

  void _bounceOffWalls() {
    const low = radius;
    final right = width - radius;
    final floor = height - radius;
    for (final p in particles) {
      if (p.x < low) {
        p.x = low;
        p.vx = p.vx.abs();
      } else if (p.x > right) {
        p.x = right;
        p.vx = -p.vx.abs();
      }
      if (p.y < low) {
        p.y = low;
        p.vy = p.vy.abs();
      } else if (p.y > floor) {
        p.y = floor;
        p.vy = -p.vy.abs();
      }
    }
  }

  /// Pushes every overlapping pair apart along the line between them.
  void _separate() {
    _forEachOverlap((a, b, nx, ny, overlap) {
      a.x -= nx * overlap;
      a.y -= ny * overlap;
      b.x += nx * overlap;
      b.y += ny * overlap;
    });
  }

  /// Separates overlapping pairs and, if they are closing in, swaps their
  /// speed along the line between them: an elastic bounce.
  void _collide() {
    _forEachOverlap((a, b, nx, ny, overlap) {
      a.x -= nx * overlap;
      a.y -= ny * overlap;
      b.x += nx * overlap;
      b.y += ny * overlap;
      final closing = (b.vx - a.vx) * nx + (b.vy - a.vy) * ny;
      if (closing >= 0) return;
      a.vx += closing * nx;
      a.vy += closing * ny;
      b.vx -= closing * nx;
      b.vy -= closing * ny;
    });
  }

  /// Calls [touch] for each overlapping pair with the unit vector from a to
  /// b and half the overlap.
  void _forEachOverlap(
    void Function(Particle a, Particle b, double nx, double ny, double overlap)
    touch,
  ) {
    const minDistance = radius * 2;
    for (var i = 0; i < particles.length; i++) {
      for (var j = i + 1; j < particles.length; j++) {
        final a = particles[i];
        final b = particles[j];
        final dx = b.x - a.x;
        final dy = b.y - a.y;
        final distance = sqrt(dx * dx + dy * dy);
        if (distance >= minDistance || distance == 0) continue;
        touch(a, b, dx / distance, dy / distance, (minDistance - distance) / 2);
      }
    }
  }
}
