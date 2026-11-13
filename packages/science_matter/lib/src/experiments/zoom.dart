import 'dart:math';
import 'dart:ui' show lerpDouble;

import 'package:activity_kit/activity_kit.dart';
import 'package:flutter/material.dart';
import 'package:science_kit/science_kit.dart';

/// A jar of air seen through a magnifier. Zooming in grows the lens until
/// it shows the gas particles, and the empty space between them.
const zoomExperiment = ControlledExperiment<double>(
  control: SliderControl(
    label: 'Zoom',
    low: Icons.zoom_out_rounded,
    high: Icons.zoom_in_rounded,
  ),
  observed: _zoomedIn,
  view: _ZoomView.new,
);

bool _zoomedIn(double zoom) => zoom >= 0.98;

class _ZoomView extends StatelessWidget {
  const _ZoomView(this.zoom);

  final double zoom;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return LayoutBuilder(
      builder: (context, box) {
        final jarWidth = box.maxWidth * 0.62;
        final jarHeight = box.maxHeight * 0.92;
        final room = min(box.maxWidth, box.maxHeight) - 12;
        final lens = lerpDouble(
          min(64.0, room),
          room,
          Curves.easeIn.transform(zoom),
        )!;
        return Stack(
          alignment: Alignment.center,
          children: [
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: 1 - zoom * 0.8,
              child: _Jar(width: jarWidth, height: jarHeight),
            ),
            Container(
              width: lens,
              height: lens,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: scheme.primary, width: 5),
                boxShadow: [
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: 0.25),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: const ClipOval(
                child: ParticleView(state: MatterState.gas, energy: 0.4),
              ),
            ),
            if (zoom < 0.05)
              Positioned(
                bottom: box.maxHeight * 0.12,
                child: Text(
                  'A jar of air',
                  style: text.titleMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            Positioned(
              bottom: 8,
              child: Pop(
                visible: _zoomedIn(zoom),
                child: const FactPill(
                  'Between particles: nothing at all',
                  icon: Icons.crop_free_rounded,
                  color: Color(0xFF7B1FA2),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Jar extends StatelessWidget {
  const _Jar({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: width,
      height: height,
      child: Column(
        children: [
          Container(
            width: width * 0.7,
            height: 16,
            decoration: BoxDecoration(
              color: scheme.onSurfaceVariant,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          Expanded(
            child: Container(
              width: width,
              decoration: BoxDecoration(
                color: Colors.lightBlue.withValues(alpha: 0.08),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(18),
                  bottom: Radius.circular(36),
                ),
                border: Border.all(color: scheme.outline, width: 3),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
