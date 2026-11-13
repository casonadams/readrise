import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:readrise_plugin_api/readrise_plugin_api.dart';

import 'activity_header.dart';
import 'feedback_banner.dart';
import 'score.dart';
import 'shake.dart';

/// A bin items are sorted into; bins with the same label are the same bin.
class SortBin {
  const SortBin(this.label);

  final String label;

  @override
  bool operator ==(Object other) => other is SortBin && other.label == label;

  @override
  int get hashCode => label.hashCode;
}

class SortItem {
  const SortItem(this.label, {required this.bin, this.why});

  final String label;
  final SortBin bin;

  /// Why it belongs there; shown once it is placed.
  final String? why;
}

/// Drag each item into the right bin, or tap a bin to place it there.
/// A wrong bin is counted as a mistake and answered with the [hint]; using
/// the hint or missing first makes that item worth half.
class SortActivity implements ActivityPlugin, Validated {
  const SortActivity({
    required this.prompt,
    required this.bins,
    required this.items,
    this.hint,
    this.maxXp = 20,
  });

  final String prompt;
  final List<SortBin> bins;
  final List<SortItem> items;

  /// The rule that decides the bins, offered on request and after a miss.
  final String? hint;
  final int maxXp;

  @override
  void validate() {
    for (final item in items) {
      if (!bins.contains(item.bin)) {
        throw ArgumentError(
          '$prompt: ${item.label} belongs in ${item.bin.label}, '
          'which is not one of the bins',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, ActivityHost host) =>
      _SortView(activity: this, host: host);
}

const _binColors = [Color(0xFF1E88E5), Color(0xFFEF6C00), Color(0xFF00897B)];

Color _binColor(int bin) => _binColors[bin % _binColors.length];

class _SortView extends StatefulWidget {
  const _SortView({required this.activity, required this.host});

  final SortActivity activity;
  final ActivityHost host;

  @override
  State<_SortView> createState() => _SortViewState();
}

class _SortViewState extends State<_SortView> {
  int _next = 0;
  int? _flashBin;
  final Map<int, int> _shakes = {};
  bool _currentMissed = false;
  bool _hintShown = false;
  (FeedbackKind, String, String)? _feedback;
  int _firstTry = 0;
  int _recovered = 0;
  int _mistakes = 0;
  late final List<List<SortItem>> _placed = [
    for (final _ in widget.activity.bins) <SortItem>[],
  ];

  SortActivity get _a => widget.activity;
  bool get _done => _next == _a.items.length;

  void _showHint() => setState(() {
    _hintShown = true;
    _currentMissed = true;
    _feedback = (FeedbackKind.hint, 'Hint', _a.hint!);
  });

  Future<void> _drop(int bin) async {
    if (_done) return;
    final item = _a.items[_next];
    if (item.bin == _a.bins[bin]) {
      HapticFeedback.selectionClick();
      setState(() {
        _placed[bin].add(item);
        _currentMissed ? _recovered++ : _firstTry++;
        _currentMissed = false;
        _next++;
        _feedback = (
          FeedbackKind.correct,
          '${item.label}: ${_a.bins[bin].label}',
          item.why ?? 'Nice sorting!',
        );
      });
      return;
    }
    HapticFeedback.lightImpact();
    setState(() {
      _mistakes++;
      _currentMissed = true;
      _flashBin = bin;
      _shakes[bin] = (_shakes[bin] ?? 0) + 1;
      _feedback = (
        FeedbackKind.wrong,
        'Not quite!',
        _a.hint ?? 'Try another box.',
      );
      if (_a.hint != null) _hintShown = true;
    });
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (mounted) setState(() => _flashBin = null);
  }

  void _finish() => widget.host.complete(
    ActivityResult(
      xp: scoreXp(
        firstTry: _firstTry,
        recovered: _recovered,
        total: _a.items.length,
        max: _a.maxXp,
      ),
      mistakes: _mistakes,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final feedback = _feedback;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ActivityHeader(
            kind: ActivityKind.sort,
            trailing: Row(
              children: [
                Text(
                  '$_next of ${_a.items.length}',
                  style: text.labelLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 90,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(end: _next / _a.items.length),
                      duration: const Duration(milliseconds: 300),
                      builder: (context, value, _) => LinearProgressIndicator(
                        value: value,
                        minHeight: 8,
                        color: ActivityKind.sort.color,
                        backgroundColor: scheme.outlineVariant,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(_a.prompt, style: text.titleLarge),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 108),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween(begin: 0.8, end: 1.0).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutBack,
                    ),
                  ),
                  child: child,
                ),
              ),
              child: _done
                  ? Column(
                      key: const ValueKey('done'),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.celebration_rounded,
                          size: 40,
                          color: Color(0xFFEF6C00),
                        ),
                        Text('All sorted!', style: text.headlineSmall),
                      ],
                    )
                  : Column(
                      key: ValueKey(_next),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Draggable<SortItem>(
                          data: _a.items[_next],
                          feedback: Material(
                            color: Colors.transparent,
                            child: Transform.rotate(
                              angle: -0.05,
                              child: _ItemCard(
                                _a.items[_next].label,
                                lifted: true,
                              ),
                            ),
                          ),
                          childWhenDragging: Opacity(
                            opacity: 0.3,
                            child: _ItemCard(_a.items[_next].label),
                          ),
                          child: _ItemCard(_a.items[_next].label),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Drag it to a box, or tap a box',
                          style: text.labelMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: Column(
              children: [
                if (feedback != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: FeedbackBanner(
                        key: ValueKey(feedback),
                        kind: feedback.$1,
                        title: feedback.$2,
                        message: feedback.$3,
                      ),
                    ),
                  ),
                if (!_done && !_hintShown && _a.hint != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _showHint,
                      icon: const Icon(Icons.lightbulb_outline),
                      label: const Text('Need a hint?'),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < _a.bins.length; i++)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(left: i == 0 ? 0 : 10),
                      child: Shake(
                        trigger: _shakes[i] ?? 0,
                        child: DragTarget<SortItem>(
                          onWillAcceptWithDetails: (_) => true,
                          onAcceptWithDetails: (_) => _drop(i),
                          builder: (context, candidates, _) => _Bin(
                            title: _a.bins[i].label,
                            color: _binColor(i),
                            items: _placed[i],
                            hovered: candidates.isNotEmpty,
                            flashing: _flashBin == i,
                            onTap: () => _drop(i),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (_done) ...[
            const SizedBox(height: 16),
            FilledButton(onPressed: _finish, child: const Text('Continue')),
          ],
        ],
      ),
    );
  }
}

class _Bin extends StatelessWidget {
  const _Bin({
    required this.title,
    required this.color,
    required this.items,
    required this.hovered,
    required this.flashing,
    required this.onTap,
  });

  final String title;
  final Color color;
  final List<SortItem> items;
  final bool hovered;
  final bool flashing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final edge = flashing ? scheme.error : color;
    return AnimatedScale(
      scale: hovered ? 1.03 : 1,
      duration: const Duration(milliseconds: 150),
      child: Material(
        color: Color.alphaBlend(
          (flashing ? scheme.error : color).withValues(
            alpha: hovered || flashing ? 0.16 : 0.07,
          ),
          scheme.surfaceContainerLowest,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(
            color: edge.withValues(alpha: hovered || flashing ? 1 : 0.35),
            width: hovered ? 3 : 2,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Semantics(
            button: true,
            label: _semanticLabel,
            excludeSemantics: true,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: text.titleMedium?.copyWith(color: color),
                        ),
                      ),
                      if (items.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${items.length}',
                            style: text.labelMedium?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final item in items)
                            _PlacedItem(item.label, color: color),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String get _semanticLabel => items.isEmpty
      ? title
      : '$title, ${items.length} ${items.length == 1 ? 'item' : 'items'}: '
            '${items.map((i) => i.label).join(', ')}';
}

class _ItemCard extends StatelessWidget {
  const _ItemCard(this.label, {this.lifted = false});

  final String label;
  final bool lifted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 24, 14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.primary, width: 2),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: lifted ? 0.35 : 0.18),
            blurRadius: lifted ? 24 : 12,
            offset: Offset(0, lifted ? 10 : 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.drag_indicator_rounded, color: scheme.outline),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlacedItem extends StatelessWidget {
  const _PlacedItem(this.label, {required this.color}) : super(key: null);

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    key: ValueKey('placed:$label'),
    tween: Tween(begin: 0, end: 1),
    duration: const Duration(milliseconds: 350),
    curve: Curves.easeOutBack,
    builder: (context, t, child) => Transform.scale(scale: t, child: child),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
    ),
  );
}
