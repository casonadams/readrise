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
    this.sugar = false,
  });

  /// Where this particle sits in a solid or a crystal: across from the left
  /// wall, and up from the floor.
  double homeX;
  double homeDepth;
  final double phase;

  /// A particle of sugar dissolving in the water, rather than water.
  final bool sugar;

  /// Still held in its crystal: it vibrates at its home instead of moving
  /// with the liquid.
  bool held = false;
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
/// Sugar particles (see [setSugar]) sit in a crystal on the floor until they
/// dissolve, then move with the water.
class ParticleSim {
  ParticleSim({required this._random, this.columns = 6, this.rows = 5}) {
    for (var i = 0; i < columns * rows; i++) {
      final (homeX, homeDepth) = _home(i);
      final angle = _random.nextDouble() * 2 * pi;
      particles.add(
        _particle(i, x: homeX, y: height - homeDepth, angle: angle),
      );
    }
  }

  static const radius = 0.04;

  /// The shortest box the solid lattice fits in.
  static const minHeight = 0.6;

  /// Crystal sites per row, and the distance between neighbouring sites.
  static const _crystalColumns = 4;
  static const _crystalSpacing = radius * 2.1;

  /// How often, per second, a dissolved sugar particle and a touching water
  /// particle swap places at middle energy: diffusion, which spreads the
  /// sugar evenly through the water instead of leaving it near the crystal.
  static const _diffusion = 1.5;

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

  /// Keeps [count] liquid or gas particles, at most [columns] x [rows]. They
  /// leave from the top, as surface particles leave a liquid, and arrive at
  /// the floor heading up, as vapor rises from water below.
  void resize(int count) {
    RangeError.checkValueInInterval(count, 0, columns * rows, 'count');
    var water = particles.where((p) => !p.sugar).length;
    while (water > count) {
      particles.remove(
        particles.where((p) => !p.sugar).reduce((a, b) => a.y <= b.y ? a : b),
      );
      water--;
    }
    while (water < count) {
      final x = radius + _random.nextDouble() * (width - 2 * radius);
      final angle = -pi / 2 + _random.nextDouble() - 0.5;
      particles.add(_particle(water, x: x, y: height - radius, angle: angle));
      water++;
    }
  }

  /// Keeps [dissolved] sugar particles moving with the water and
  /// [undissolved] still in a crystal in the middle of the floor. Particles
  /// dissolve from the top of the crystal; fewer dissolved ones re-form it.
  void setSugar({required int dissolved, required int undissolved}) {
    final sugar = particles.where((p) => p.sugar).toList();
    for (final extra in sugar.skip(dissolved + undissolved)) {
      particles.remove(extra);
    }
    for (var i = sugar.length; i < dissolved + undissolved; i++) {
      final added = Particle(
        homeX: 0.5,
        homeDepth: double.infinity,
        x: width / 2,
        y: height - radius,
        vx: 0,
        vy: 0,
        phase: _random.nextDouble() * 2 * pi,
        sugar: true,
      )..held = true;
      particles.add(added);
    }
    final all = particles.where((p) => p.sugar).toList()
      ..sort(
        (a, b) => a.held != b.held
            ? (a.held ? -1 : 1)
            : a.homeDepth.compareTo(b.homeDepth),
      );
    for (final (i, p) in all.indexed) {
      p.held = i < undissolved;
      if (p.held) {
        p.homeX = 0.5 + ((i % _crystalColumns) - 1.5) * _crystalSpacing;
        p.homeDepth = radius + (i ~/ _crystalColumns) * _crystalSpacing;
      }
    }
  }

  (double, double) _home(int i) =>
      (0.15 + (i % columns) * 0.14, 0.1 + (i ~/ columns) * 0.1);

  Particle _particle(
    int i, {
    required double x,
    required double y,
    required double angle,
  }) {
    final (homeX, homeDepth) = _home(i);
    return Particle(
      homeX: homeX,
      homeDepth: homeDepth,
      x: x,
      y: y,
      vx: cos(angle),
      vy: sin(angle),
      phase: _random.nextDouble() * 2 * pi,
    );
  }

  /// Advances the simulation by [dt] seconds. [energy] is 0..1.
  void step(double dt, MatterState state, double energy) {
    if (dt <= 0) return;
    _time += dt;
    switch (state) {
      case MatterState.solid:
        _vibrate(dt, energy, particles);
      case MatterState.liquid:
        _pour(dt, energy);
        _vibrate(dt, energy, particles.where((p) => p.held));
      case MatterState.gas:
        _fly(dt, energy);
        _vibrate(dt, energy, particles.where((p) => p.held));
    }
  }

  void _vibrate(double dt, double energy, Iterable<Particle> vibrating) {
    final amplitude = 0.008 + 0.014 * energy;
    final pull = min(1.0, 8 * dt);
    for (final p in vibrating) {
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
    final free = [
      for (final p in particles)
        if (!p.held) p,
    ];
    final kick = (0.4 + 0.8 * energy) * sqrt(dt);
    final damping = 1 - min(1.0, dt);
    final startX = [for (final p in free) p.x];
    final startY = [for (final p in free) p.y];
    for (final p in free) {
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
    _diffuse(dt, energy);
    for (final (i, p) in free.indexed) {
      p.vx = (p.x - startX[i]) / dt;
      p.vy = (p.y - startY[i]) / dt;
      final speed = sqrt(p.vx * p.vx + p.vy * p.vy);
      if (speed > _maxLiquidSpeed) {
        p.vx *= _maxLiquidSpeed / speed;
        p.vy *= _maxLiquidSpeed / speed;
      }
    }
  }

  void _diffuse(double dt, double energy) {
    final chance = _diffusion * (0.5 + energy) * dt;
    const reach = radius * 2.3;
    for (final sugar in particles) {
      if (!sugar.sugar || sugar.held) continue;
      for (final water in particles) {
        if (water.sugar) continue;
        final dx = water.x - sugar.x;
        final dy = water.y - sugar.y;
        if (dx * dx + dy * dy > reach * reach) continue;
        if (_random.nextDouble() >= chance) continue;
        final (x, y) = (sugar.x, sugar.y);
        sugar
          ..x = water.x
          ..y = water.y;
        water
          ..x = x
          ..y = y;
        break;
      }
    }
  }

  /// Free flight with elastic bounces; a thermostat sets the average speed
  /// from [energy] without forcing every particle to the same speed.
  void _fly(double dt, double energy) {
    final free = [
      for (final p in particles)
        if (!p.held) p,
    ];
    if (free.isEmpty) return;
    final target = 0.35 + 0.35 * energy;
    var sum = 0.0;
    for (final p in free) {
      sum += p.vx * p.vx + p.vy * p.vy;
    }
    final rms = sqrt(sum / free.length);
    if (rms < 1e-6) {
      for (final p in free) {
        final angle = _random.nextDouble() * 2 * pi;
        p.vx = cos(angle) * target;
        p.vy = sin(angle) * target;
      }
    } else {
      final scale = 1 + (target / rms - 1) * min(1.0, 4 * dt);
      for (final p in free) {
        p.vx *= scale;
        p.vy *= scale;
      }
    }
    for (final p in free) {
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

  /// Pushes every overlapping pair apart along the line between them; a
  /// particle held in a crystal does not move, so the other moves for both.
  void _push(Particle a, Particle b, double nx, double ny, double overlap) {
    final (moveA, moveB) = switch ((a.held, b.held)) {
      (true, true) => (0.0, 0.0),
      (true, false) => (0.0, 2 * overlap),
      (false, true) => (2 * overlap, 0.0),
      (false, false) => (overlap, overlap),
    };
    a.x -= nx * moveA;
    a.y -= ny * moveA;
    b.x += nx * moveB;
    b.y += ny * moveB;
  }

  void _separate() => _forEachOverlap(_push);

  /// Separates overlapping pairs and, if they are closing in, swaps their
  /// speed along the line between them: an elastic bounce.
  void _collide() {
    _forEachOverlap((a, b, nx, ny, overlap) {
      _push(a, b, nx, ny, overlap);
      if (a.held || b.held) return;
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
