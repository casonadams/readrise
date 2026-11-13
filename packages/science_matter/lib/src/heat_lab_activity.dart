import 'package:activity_kit/activity_kit.dart';
import 'package:flutter/material.dart';
import 'package:readrise_plugin_api/readrise_plugin_api.dart';
import 'package:science_kit/science_kit.dart';

class HeatGoal {
  const HeatGoal({required this.prompt, required this.target});

  final String prompt;
  final MatterState target;
}

/// Drag a thermometer for a sample of water and watch its particles. Each goal
/// asks for a state of matter; reaching it unlocks the next goal.
class HeatLabActivity implements ActivityPlugin {
  const HeatLabActivity({required this.goals, this.maxXp = 20});

  static const minCelsius = -20.0;
  static const maxCelsius = 120.0;

  final List<HeatGoal> goals;
  final int maxXp;

  @override
  Widget build(BuildContext context, ActivityHost host) =>
      _HeatLabView(activity: this, host: host);
}

class _HeatLabView extends StatefulWidget {
  const _HeatLabView({required this.activity, required this.host});

  final HeatLabActivity activity;
  final ActivityHost host;

  @override
  State<_HeatLabView> createState() => _HeatLabViewState();
}

class _HeatLabViewState extends State<_HeatLabView> {
  double _celsius = HeatLabActivity.minCelsius;
  int _goal = 0;

  List<HeatGoal> get _goals => widget.activity.goals;
  MatterState get _state => waterStateAt(_celsius);
  bool get _reached => _state == _goals[_goal].target;
  bool get _last => _goal + 1 == _goals.length;

  void _advance() {
    if (_last) {
      widget.host.complete(ActivityResult(xp: widget.activity.maxXp));
      return;
    }
    setState(() => _goal++);
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: FeedbackLayout(
      feedback: _reached
          ? AnswerPanel(
              key: ValueKey(_goal),
              title: 'Goal reached!',
              explanation:
                  'At ${_celsius.round()}\u00B0C the water is a '
                  '${_state.name}.',
              onContinue: _advance,
            )
          : null,
      page: (context, _) => _page(context),
    ),
  );

  Widget _page(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final state = _state;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Goal ${_goal + 1} of ${_goals.length}', style: text.labelLarge),
        const SizedBox(height: 4),
        Text(_goals[_goal].prompt, style: text.titleLarge),
        const SizedBox(height: 16),
        Expanded(
          child: ParticleView(state: state, energy: energyAt(_celsius)),
        ),
        const SizedBox(height: 12),
        Text(
          '${_celsius.round()}\u00B0C  \u2022  '
          '${state.name[0].toUpperCase()}${state.name.substring(1)}',
          textAlign: TextAlign.center,
          style: text.headlineSmall,
        ),
        Slider(
          min: HeatLabActivity.minCelsius,
          max: HeatLabActivity.maxCelsius,
          divisions: 140,
          value: _celsius,
          label: '${_celsius.round()}\u00B0C',
          semanticFormatterCallback: (v) => '${v.round()} degrees Celsius',
          onChanged: (v) => setState(() => _celsius = v),
        ),
        Text(
          'Water freezes below 0\u00B0C and boils at 100\u00B0C.',
          textAlign: TextAlign.center,
          style: text.bodyMedium,
        ),
        // Room for the goal panel, so it covers the controls, not the water.
        const SizedBox(height: 48),
      ],
    );
  }
}
