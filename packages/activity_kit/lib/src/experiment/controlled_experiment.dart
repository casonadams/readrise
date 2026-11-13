import 'dart:async';

import 'package:flutter/widgets.dart';

import 'control.dart';
import 'experiment.dart';

/// An experiment driven by one [control]: [view] draws the setup for the
/// control's value. Once [observed] holds, it waits [settle] for the result
/// to play out, then reports it once.
class ControlledExperiment<T> implements Experiment {
  const ControlledExperiment({
    required this.control,
    required this.observed,
    required this.view,
    this.settle = Duration.zero,
  });

  final Control<T> control;
  final bool Function(T value) observed;
  final Widget Function(T value) view;
  final Duration settle;

  @override
  Widget build(
    BuildContext context, {
    required bool active,
    required VoidCallback onObserved,
  }) => _ControlledExperimentView<T>(
    experiment: this,
    active: active,
    onObserved: onObserved,
  );
}

class _ControlledExperimentView<T> extends StatefulWidget {
  const _ControlledExperimentView({
    required this.experiment,
    required this.active,
    required this.onObserved,
  });

  final ControlledExperiment<T> experiment;
  final bool active;
  final VoidCallback onObserved;

  @override
  State<_ControlledExperimentView<T>> createState() =>
      _ControlledExperimentViewState<T>();
}

class _ControlledExperimentViewState<T>
    extends State<_ControlledExperimentView<T>> {
  late T _value = widget.experiment.control.initial;
  bool _reported = false;
  Timer? _settle;

  @override
  void dispose() {
    _settle?.cancel();
    super.dispose();
  }

  void _change(T value) {
    setState(() => _value = value);
    if (_reported || !widget.experiment.observed(value)) return;
    _reported = true;
    if (widget.experiment.settle == Duration.zero) {
      widget.onObserved();
    } else {
      _settle = Timer(widget.experiment.settle, () => widget.onObserved());
    }
  }

  @override
  Widget build(BuildContext context) {
    final experiment = widget.experiment;
    return Column(
      children: [
        Expanded(child: experiment.view(_value)),
        experiment.control.build(
          context,
          _value,
          widget.active ? _change : null,
        ),
      ],
    );
  }
}
