import 'package:flutter/widgets.dart';

/// The hands-on part of a prediction. While [active] is false the learner
/// sees the setup but cannot run it; once the result is visible, the
/// experiment calls [onObserved] exactly once.
abstract interface class Experiment {
  Widget build(
    BuildContext context, {
    required bool active,
    required VoidCallback onObserved,
  });
}
