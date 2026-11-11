import 'package:activity_kit/activity_kit.dart';
import 'package:flutter/material.dart';

import 'pop.dart';

const matterExplainerSteps = [
  ExplainerStep('Matter is anything that has mass and takes up space.'),
  ExplainerStep('Rocks, water, and even the air you breathe are matter.'),
  ExplainerStep('Light, heat, and sound are forms of energy.'),
  ExplainerStep('Energy is not matter. It has no mass and takes up no space.'),
];

typedef _Thing = (IconData, String, Color);

const _matterThings = <_Thing>[
  (Icons.landscape_rounded, 'Rock', Color(0xFF8D6E63)),
  (Icons.water_drop_rounded, 'Water', Color(0xFF1E88E5)),
  (Icons.air_rounded, 'Air', Color(0xFF26A69A)),
];

const _energyThings = <_Thing>[
  (Icons.light_mode_rounded, 'Light', Color(0xFFF9A825)),
  (Icons.local_fire_department_rounded, 'Heat', Color(0xFFEF6C00)),
  (Icons.graphic_eq_rounded, 'Sound', Color(0xFF8E24AA)),
];

const _stagger = Duration(milliseconds: 180);

const _stage = Size(350, 365);
const _gap = 12.0;
const _panelWidth = (350 - _gap) / 2;

/// "Everything is matter": a Matter panel that ticks off mass and space, then
/// slides aside for an Energy panel that crosses them out.
Widget matterExplainerScene(BuildContext context, int step) {
  final scheme = Theme.of(context).colorScheme;
  return Center(
    child: FittedBox(
      fit: BoxFit.scaleDown,
      child: SizedBox.fromSize(
        size: _stage,
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              left: step >= 2 ? 0 : (_stage.width - _panelWidth) / 2,
              top: 0,
              bottom: 0,
              width: _panelWidth,
              child: _Panel(
                title: 'Matter',
                color: scheme.primary,
                hasProperties: true,
                showPanel: true,
                showProperties: true,
                showThings: step >= 1,
                things: _matterThings,
              ),
            ),
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: _panelWidth,
              child: _Panel(
                title: 'Energy',
                color: const Color(0xFFEF6C00),
                hasProperties: false,
                showPanel: step >= 2,
                showProperties: step >= 3,
                showThings: step >= 2,
                things: _energyThings,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.title,
    required this.color,
    required this.hasProperties,
    required this.showPanel,
    required this.showProperties,
    required this.showThings,
    required this.things,
  });

  final String title;
  final Color color;
  final bool hasProperties;
  final bool showPanel;
  final bool showProperties;
  final bool showThings;
  final List<_Thing> things;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Pop(
      visible: showPanel,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 8),
        decoration: BoxDecoration(
          color: Color.alphaBlend(
            color.withValues(alpha: 0.08),
            Theme.of(context).colorScheme.surfaceContainerLowest,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: text.titleLarge?.copyWith(color: color)),
            const SizedBox(height: 10),
            Pop(
              visible: showProperties,
              delay: const Duration(milliseconds: 200),
              child: _Property(
                label: hasProperties ? 'Has mass' : 'No mass',
                yes: hasProperties,
              ),
            ),
            const SizedBox(height: 6),
            Pop(
              visible: showProperties,
              delay: const Duration(milliseconds: 400),
              child: _Property(
                label: hasProperties ? 'Takes up space' : 'No space',
                yes: hasProperties,
              ),
            ),
            const SizedBox(height: 14),
            for (var i = 0; i < things.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Pop(
                  visible: showThings,
                  delay: _stagger * (i + 1),
                  child: _ThingTile(thing: things[i]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Property extends StatelessWidget {
  const _Property({required this.label, required this.yes});

  final String label;
  final bool yes;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final mark = yes ? const Color(0xFF2E7D32) : scheme.error;
    return Row(
      children: [
        Icon(
          yes ? Icons.check_circle_rounded : Icons.cancel_rounded,
          size: 20,
          color: mark,
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(label, style: Theme.of(context).textTheme.labelLarge),
        ),
      ],
    );
  }
}

class _ThingTile extends StatelessWidget {
  const _ThingTile({required this.thing});

  final _Thing thing;

  @override
  Widget build(BuildContext context) {
    final (icon, label, color) = thing;
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(label, style: Theme.of(context).textTheme.titleMedium),
        ),
      ],
    );
  }
}
