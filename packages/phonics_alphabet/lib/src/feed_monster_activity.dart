import 'dart:math';

import 'package:activity_kit/activity_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:readrise_plugin_api/readrise_plugin_api.dart';

import 'letter.dart';
import 'letter_text.dart';
import 'monster_session.dart';

/// Feed the Monster: drag pictures that start with the monster's letter into
/// its mouth and the rest into the bin. Tapping the monster or the bin works
/// too.
class FeedMonsterActivity implements ActivityPlugin, Randomizable {
  const FeedMonsterActivity({
    required this.letter,
    required this.learned,
    required this.unseen,
    this.seed = 0,
  });

  final Letter letter;
  final List<Letter> learned;
  final List<Letter> unseen;

  /// Seeds which pictures are offered and in what order.
  final int seed;

  @override
  FeedMonsterActivity shuffled(Random random) => FeedMonsterActivity(
    letter: letter,
    learned: learned,
    unseen: unseen,
    seed: random.nextSeed(),
  );

  @override
  Widget build(BuildContext context, ActivityHost host) =>
      _MonsterView(activity: this, host: host);
}

enum _Mood { waiting, happy, yuck, sad }

class _MonsterView extends StatefulWidget {
  const _MonsterView({required this.activity, required this.host});

  final FeedMonsterActivity activity;
  final ActivityHost host;

  @override
  State<_MonsterView> createState() => _MonsterViewState();
}

class _MonsterViewState extends State<_MonsterView> {
  late final MonsterSession _session = MonsterSession(
    letter: widget.activity.letter,
    learned: widget.activity.learned,
    unseen: widget.activity.unseen,
    random: Random(widget.activity.seed),
  );
  _Mood _mood = _Mood.waiting;
  bool _busy = false;
  bool _dragging = false;
  int _shake = 0;

  Letter get _letter => widget.activity.letter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await widget.host.speaker.speak(
        'Feed me things that start with ${_letter.char}',
      );
      if (mounted) _speakFood();
    });
  }

  void _speakFood() {
    if (_session.isComplete) return;
    widget.host.speaker.speak(_session.current.picture.word);
  }

  Future<void> _answer({required bool feed}) async {
    if (_busy || _session.isComplete) return;
    final right = _session.answer(feed: feed);
    HapticFeedback.mediumImpact();
    setState(() {
      _busy = true;
      _dragging = false;
      if (right) {
        _mood = feed ? _Mood.happy : _Mood.waiting;
      } else {
        _mood = feed ? _Mood.yuck : _Mood.sad;
        _shake++;
      }
    });
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    if (_session.isComplete) {
      widget.host.complete(
        ActivityResult(xp: _session.xp, mistakes: _session.mistakes),
      );
      return;
    }
    setState(() {
      _busy = false;
      _mood = _Mood.waiting;
    });
    _speakFood();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final food = _session.isComplete ? null : _session.current;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: LayoutBuilder(
        builder: (context, box) {
          final stageHeight = (box.maxHeight * 0.34).clamp(96.0, 190.0);
          return Column(
            children: [
              LinearProgressIndicator(
                value: _session.progress,
                minHeight: 14,
                borderRadius: BorderRadius.circular(7),
              ),
              const SizedBox(height: 12),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Feed me things that start with',
                      maxLines: 1,
                      softWrap: false,
                      style: text.titleMedium,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _letter.display,
                      maxLines: 1,
                      softWrap: false,
                      textScaler: TextScaler.noScaling,
                      style: letterTextStyle(48, color: scheme.primary),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: food == null
                      ? const SizedBox.shrink()
                      : FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Shake(
                            trigger: _shake,
                            child: _FoodCard(
                              food: food,
                              enabled: !_busy,
                              onTap: _speakFood,
                              onDragStarted: () =>
                                  setState(() => _dragging = true),
                              onDragEnd: () =>
                                  setState(() => _dragging = false),
                            ),
                          ),
                        ),
                ),
              ),
              SizedBox(
                height: stageHeight,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      flex: 3,
                      child: DragTarget<Food>(
                        onWillAcceptWithDetails: (_) => !_busy,
                        onAcceptWithDetails: (_) => _answer(feed: true),
                        builder: (context, candidates, _) => _Target(
                          key: const Key('monster'),
                          label: 'Feed the monster',
                          onTap: () => _answer(feed: true),
                          child: _Monster(
                            mood: _mood,
                            mouthOpen: candidates.isNotEmpty || _dragging,
                            color: scheme.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 1,
                      child: DragTarget<Food>(
                        onWillAcceptWithDetails: (_) => !_busy,
                        onAcceptWithDetails: (_) => _answer(feed: false),
                        builder: (context, candidates, _) => _Target(
                          key: const Key('bin'),
                          label: 'Yuck, throw it away',
                          onTap: () => _answer(feed: false),
                          child: AnimatedScale(
                            scale: candidates.isNotEmpty ? 1.2 : 1,
                            duration: const Duration(milliseconds: 150),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    '\u{1F5D1}\uFE0F',
                                    style: TextStyle(fontSize: 52),
                                  ),
                                  Text('Yuck!', style: text.labelLarge),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          );
        },
      ),
    );
  }
}

class _Target extends StatelessWidget {
  const _Target({
    required this.label,
    required this.onTap,
    required this.child,
    super.key,
  });

  final String label;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    button: true,
    label: label,
    excludeSemantics: true,
    onTap: onTap,
    child: InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Padding(padding: const EdgeInsets.all(8), child: child),
    ),
  );
}

class _FoodCard extends StatelessWidget {
  const _FoodCard({
    required this.food,
    required this.enabled,
    required this.onTap,
    required this.onDragStarted,
    required this.onDragEnd,
  });

  final Food food;
  final bool enabled;
  final VoidCallback onTap;
  final VoidCallback onDragStarted;
  final VoidCallback onDragEnd;

  @override
  Widget build(BuildContext context) {
    final card = Semantics(
      label:
          'Picture of ${food.picture.word}. Drag it, or tap the monster or the bin.',
      container: true,
      excludeSemantics: true,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Text(food.picture.emoji, style: const TextStyle(fontSize: 96)),
        ),
      ),
    );
    if (!enabled) return card;
    return Draggable<Food>(
      data: food,
      onDragStarted: onDragStarted,
      onDragEnd: (_) => onDragEnd(),
      feedback: Material(
        color: Colors.transparent,
        child: Transform.scale(scale: 1.15, child: card),
      ),
      childWhenDragging: Opacity(opacity: 0.25, child: card),
      child: GestureDetector(onTap: onTap, child: card),
    );
  }
}

/// A round monster whose mouth opens as food nears and whose face shows how
/// the last feeding went.
class _Monster extends StatelessWidget {
  const _Monster({
    required this.mood,
    required this.mouthOpen,
    required this.color,
  });

  final _Mood mood;
  final bool mouthOpen;
  final Color color;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(end: mouthOpen ? 1 : 0),
    duration: const Duration(milliseconds: 160),
    builder: (context, open, _) => AspectRatio(
      aspectRatio: 1.15,
      child: CustomPaint(
        painter: _MonsterPainter(mood: mood, open: open, color: color),
      ),
    ),
  );
}

class _MonsterPainter extends CustomPainter {
  const _MonsterPainter({
    required this.mood,
    required this.open,
    required this.color,
  });

  final _Mood mood;
  final double open;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final body = Paint()..color = color;
    final dark = Paint()..color = Colors.black87;
    final white = Paint()..color = Colors.white;

    canvas.drawOval(Rect.fromLTWH(w * 0.05, h * 0.12, w * 0.9, h * 0.86), body);
    for (final x in [0.22, 0.78]) {
      canvas.drawCircle(Offset(w * x, h * 0.14), w * 0.05, body);
    }

    final eyeY = h * 0.38;
    for (final x in [0.34, 0.66]) {
      canvas.drawCircle(Offset(w * x, eyeY), w * 0.11, white);
      final look = mood == _Mood.sad ? 0.025 : 0.0;
      canvas.drawCircle(Offset(w * x, eyeY + h * look), w * 0.05, dark);
    }
    if (mood == _Mood.sad || mood == _Mood.yuck) {
      final brow = Paint()
        ..color = Colors.black87
        ..strokeWidth = w * 0.025
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(w * 0.25, h * 0.24),
        Offset(w * 0.40, h * 0.27),
        brow,
      );
      canvas.drawLine(
        Offset(w * 0.75, h * 0.24),
        Offset(w * 0.60, h * 0.27),
        brow,
      );
    }

    final mouthCenter = Offset(w * 0.5, h * 0.68);
    final openness = mood == _Mood.happy
        ? 0.15
        : mood == _Mood.yuck
        ? 0.35
        : 0.2 + 0.8 * open;
    final mouth = Rect.fromCenter(
      center: mouthCenter,
      width: w * (0.5 + 0.1 * openness),
      height: h * (0.06 + 0.3 * openness),
    );
    if (mood == _Mood.happy) {
      final smile = Path()
        ..moveTo(w * 0.3, h * 0.62)
        ..quadraticBezierTo(w * 0.5, h * 0.88, w * 0.7, h * 0.62)
        ..close();
      canvas.drawPath(smile, dark);
    } else if (mood == _Mood.sad) {
      final frown = Paint()
        ..color = Colors.black87
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.03
        ..strokeCap = StrokeCap.round;
      final path = Path()
        ..moveTo(w * 0.35, h * 0.78)
        ..quadraticBezierTo(w * 0.5, h * 0.64, w * 0.65, h * 0.78);
      canvas.drawPath(path, frown);
    } else {
      canvas.drawOval(mouth, dark);
      if (mood == _Mood.yuck) {
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(w * 0.5, mouth.bottom - h * 0.02),
            width: w * 0.16,
            height: h * 0.12,
          ),
          Paint()..color = Colors.pink.shade300,
        );
      }
    }
    if (mood != _Mood.sad && mood != _Mood.happy && openness > 0.4) {
      final tooth = Path()
        ..moveTo(mouth.left + mouth.width * 0.2, mouth.top + 2)
        ..lineTo(mouth.left + mouth.width * 0.28, mouth.top + h * 0.06)
        ..lineTo(mouth.left + mouth.width * 0.36, mouth.top + 2)
        ..close();
      canvas.drawPath(tooth, white);
    }
  }

  @override
  bool shouldRepaint(_MonsterPainter old) =>
      old.mood != mood || old.open != open || old.color != color;
}
