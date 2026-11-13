import 'dart:math';

import 'package:activity_kit/activity_kit.dart';
import 'package:flutter/material.dart';

const _stage = Size(320, 250);
const _bondLength = 92.0;
const _halfAngle = 52.25 * pi / 180;
const _oxygenRadius = 42.0;
const _hydrogenRadius = 27.0;
const _bob = 6.0;

/// Standard molecule-model colours: oxygen red, hydrogen white.
const _oxygenColor = Color(0xFFE53935);
const _hydrogenColor = Color(0xFFF5F5F5);
const _negative = Color(0xFFC62828);
const _positive = Color(0xFF1565C0);

const _joinedO = Offset(160, 92);
final _joinedH1 =
    _joinedO + Offset(-sin(_halfAngle), cos(_halfAngle)) * _bondLength;
final _joinedH2 =
    _joinedO + Offset(sin(_halfAngle), cos(_halfAngle)) * _bondLength;
const _looseO = Offset(168, 190);
const _looseH1 = Offset(48, 52);
const _looseH2 = Offset(278, 70);

/// Step 0: loose atoms drift. Step 1: they join into a molecule. Step 2: the
/// atoms are counted. Step 3: the formula appears. Step 4: the charges appear.
Widget waterMoleculeScene(BuildContext context, int step) =>
    _MoleculeScene(step: step);

class _MoleculeScene extends StatefulWidget {
  const _MoleculeScene({required this.step});

  final int step;

  @override
  State<_MoleculeScene> createState() => _MoleculeSceneState();
}

class _MoleculeSceneState extends State<_MoleculeScene>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drift = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat();

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.step;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: FittedBox(
            child: SizedBox.fromSize(
              size: _stage,
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: step >= 1 ? 1 : 0),
                duration: const Duration(milliseconds: 1100),
                curve: Curves.easeInOutBack,
                builder: (context, join, _) => AnimatedBuilder(
                  animation: _drift,
                  builder: (context, _) => _molecule(join, step >= 4),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Pop(
          visible: step >= 2,
          child: const Wrap(
            spacing: 10,
            children: [
              FactPill('2 hydrogen', color: Color(0xFF616161)),
              FactPill('1 oxygen', color: _oxygenColor),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Pop(
          visible: step >= 3,
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'H\u2082',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const TextSpan(
                  text: 'O',
                  style: TextStyle(color: _oxygenColor),
                ),
              ],
            ),
            style: Theme.of(context).textTheme.displaySmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }

  Widget _molecule(double join, bool charged) {
    final t = _drift.value * 2 * pi;
    final loose = (1 - join).clamp(0.0, 1.0);
    Offset place(Offset from, Offset to, double phase) =>
        Offset.lerp(from, to, join)! +
        Offset(cos(t + phase), sin(t + phase)) * _bob * loose;

    final o = place(_looseO, _joinedO, 0);
    final h1 = place(_looseH1, _joinedH1, 2);
    final h2 = place(_looseH2, _joinedH2, 4);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CustomPaint(
          size: _stage,
          painter: _BondPainter(
            oxygen: o,
            hydrogens: [h1, h2],
            opacity: ((join - 0.75) / 0.25).clamp(0.0, 1.0),
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        _Halo(at: o, radius: _oxygenRadius, color: _negative, on: charged),
        _Halo(at: h1, radius: _hydrogenRadius, color: _positive, on: charged),
        _Halo(at: h2, radius: _hydrogenRadius, color: _positive, on: charged),
        _Atom(
          at: o,
          symbol: 'O',
          radius: _oxygenRadius,
          color: _oxygenColor,
          ink: Colors.white,
        ),
        _Atom(
          at: h1,
          symbol: 'H',
          radius: _hydrogenRadius,
          color: _hydrogenColor,
          ink: const Color(0xFF424242),
        ),
        _Atom(
          at: h2,
          symbol: 'H',
          radius: _hydrogenRadius,
          color: _hydrogenColor,
          ink: const Color(0xFF424242),
        ),
        _Charge(
          at: o,
          radius: _oxygenRadius,
          sign: '\u2212',
          color: _negative,
          on: charged,
        ),
        _Charge(
          at: h1,
          radius: _hydrogenRadius,
          sign: '+',
          color: _positive,
          on: charged,
          onLeft: true,
        ),
        _Charge(
          at: h2,
          radius: _hydrogenRadius,
          sign: '+',
          color: _positive,
          on: charged,
        ),
      ],
    );
  }
}

class _Atom extends StatelessWidget {
  const _Atom({
    required this.at,
    required this.symbol,
    required this.radius,
    required this.color,
    required this.ink,
  });

  final Offset at;
  final String symbol;
  final double radius;
  final Color color;
  final Color ink;

  @override
  Widget build(BuildContext context) => Positioned(
    left: at.dx - radius,
    top: at.dy - radius,
    child: Container(
      width: radius * 2,
      height: radius * 2,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.35, -0.4),
          radius: 0.95,
          colors: [
            Color.lerp(color, Colors.white, 0.45)!,
            color,
            Color.lerp(color, Colors.black, 0.22)!,
          ],
          stops: const [0, 0.6, 1],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        symbol,
        style: TextStyle(
          color: ink,
          fontSize: radius * 0.75,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
  );
}

/// A soft glow around an atom showing where its charge sits.
class _Halo extends StatelessWidget {
  const _Halo({
    required this.at,
    required this.radius,
    required this.color,
    required this.on,
  });

  final Offset at;
  final double radius;
  final Color color;
  final bool on;

  @override
  Widget build(BuildContext context) {
    final size = radius * 2 + 28;
    return Positioned(
      left: at.dx - size / 2,
      top: at.dy - size / 2,
      child: AnimatedOpacity(
        opacity: on ? 1 : 0,
        duration: const Duration(milliseconds: 600),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color.withValues(alpha: 0.35),
                color.withValues(alpha: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Charge extends StatelessWidget {
  const _Charge({
    required this.at,
    required this.radius,
    required this.sign,
    required this.color,
    required this.on,
    this.onLeft = false,
  });

  final Offset at;
  final double radius;
  final String sign;
  final Color color;
  final bool on;
  final bool onLeft;

  @override
  Widget build(BuildContext context) {
    const size = 28.0;
    final dx = radius * 0.72;
    return Positioned(
      left: at.dx + (onLeft ? -dx - size : dx) - (onLeft ? -6 : 6),
      top: at.dy - radius * 0.72 - size + 6,
      child: Pop(
        visible: on,
        delay: const Duration(milliseconds: 300),
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Text(
            sign,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}

class _BondPainter extends CustomPainter {
  const _BondPainter({
    required this.oxygen,
    required this.hydrogens,
    required this.opacity,
    required this.color,
  });

  final Offset oxygen;
  final List<Offset> hydrogens;
  final double opacity;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity == 0) return;
    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    for (final h in hydrogens) {
      canvas.drawLine(oxygen, h, paint);
    }
  }

  @override
  bool shouldRepaint(_BondPainter old) =>
      old.oxygen != oxygen ||
      old.opacity != opacity ||
      old.color != color ||
      old.hydrogens[0] != hydrogens[0] ||
      old.hydrogens[1] != hydrogens[1];
}
