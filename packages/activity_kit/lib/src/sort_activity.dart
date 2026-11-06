import 'package:flutter/material.dart';
import 'package:readrise_plugin_api/readrise_plugin_api.dart';

import 'score.dart';

class SortItem {
  const SortItem(this.label, {required this.bin});

  final String label;

  /// Index into the activity's bins where this item belongs.
  final int bin;
}

/// Drag each item into the right bin, or tap a bin to place it there.
class SortActivity implements ActivityPlugin {
  const SortActivity({
    required this.prompt,
    required this.bins,
    required this.items,
    this.maxXp = 20,
  });

  final String prompt;
  final List<String> bins;
  final List<SortItem> items;
  final int maxXp;

  @override
  Widget build(BuildContext context, ActivityHost host) =>
      _SortView(activity: this, host: host);
}

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
  bool _currentMissed = false;
  int _firstTry = 0;
  int _recovered = 0;
  int _mistakes = 0;
  late final List<List<SortItem>> _placed = [
    for (final _ in widget.activity.bins) <SortItem>[],
  ];

  SortActivity get _a => widget.activity;
  bool get _done => _next == _a.items.length;

  Future<void> _drop(int bin) async {
    if (_done) return;
    final item = _a.items[_next];
    if (item.bin == bin) {
      setState(() {
        _placed[bin].add(item);
        _currentMissed ? _recovered++ : _firstTry++;
        _currentMissed = false;
        _next++;
      });
      return;
    }
    setState(() {
      _mistakes++;
      _currentMissed = true;
      _flashBin = bin;
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
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LinearProgressIndicator(
            value: _next / _a.items.length,
            minHeight: 12,
            borderRadius: BorderRadius.circular(6),
          ),
          const SizedBox(height: 16),
          Text(_a.prompt, style: text.titleLarge),
          const SizedBox(height: 24),
          SizedBox(
            height: 88,
            child: Center(
              child: _done
                  ? Text('All sorted!', style: text.headlineSmall)
                  : Draggable<SortItem>(
                      data: _a.items[_next],
                      feedback: Material(
                        color: Colors.transparent,
                        child: _ItemCard(_a.items[_next].label),
                      ),
                      childWhenDragging: Opacity(
                        opacity: 0.3,
                        child: _ItemCard(_a.items[_next].label),
                      ),
                      child: _ItemCard(_a.items[_next].label),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < _a.bins.length; i++)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(left: i == 0 ? 0 : 12),
                      child: DragTarget<SortItem>(
                        onWillAcceptWithDetails: (_) => true,
                        onAcceptWithDetails: (_) => _drop(i),
                        builder: (context, candidates, _) => InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => _drop(i),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _flashBin == i
                                  ? scheme.errorContainer
                                  : candidates.isNotEmpty
                                  ? scheme.primaryContainer
                                  : scheme.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_a.bins[i], style: text.titleMedium),
                                const SizedBox(height: 8),
                                Expanded(
                                  child: SingleChildScrollView(
                                    child: Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: [
                                        for (final item in _placed[i])
                                          Chip(label: Text(item.label)),
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

class _ItemCard extends StatelessWidget {
  const _ItemCard(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Card(
    elevation: 3,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
      child: Text(label, style: Theme.of(context).textTheme.headlineSmall),
    ),
  );
}
