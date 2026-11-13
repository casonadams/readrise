import 'package:activity_kit/activity_kit.dart';
import 'package:flutter/material.dart';
import 'package:science_kit/science_kit.dart';

const _maxTilt = 0.16;
const _balloonColor = Color(0xFFE53935);
const _pumpsToFill = 4;

/// Two identical empty balloons balance. Each pump of air fills the right
/// one: it grows, because air takes up space, and the scale tips toward it,
/// because air has mass.
const balloonExperiment = ControlledExperiment<int>(
  control: TapControl(
    label: 'Pump',
    icon: Icons.air_rounded,
    presses: _pumpsToFill,
    color: _balloonColor,
  ),
  observed: _full,
  view: _BalloonView.new,
  settle: Duration(milliseconds: 1400),
);

bool _full(int pumps) => pumps >= _pumpsToFill;

class _BalloonView extends StatelessWidget {
  const _BalloonView(this.pumps);

  final int pumps;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: FittedBox(
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: pumps / _pumpsToFill),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutBack,
              builder: (context, air, _) => TweenAnimationBuilder<double>(
                tween: Tween(end: air * _maxTilt),
                duration: const Duration(milliseconds: 1200),
                curve: Curves.elasticOut,
                builder: (context, tilt, _) =>
                    BalloonBalance(air: air.clamp(0.0, 1.1), tilt: tilt),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (_full(pumps))
          const Wrap(
            spacing: 8,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              Pop(
                visible: true,
                child: FactPill(
                  'Takes up space',
                  icon: Icons.view_in_ar_rounded,
                ),
              ),
              Pop(
                visible: true,
                delay: Duration(milliseconds: 300),
                child: FactPill('Has mass', icon: Icons.scale_rounded),
              ),
            ],
          ),
      ],
    );
  }
}
