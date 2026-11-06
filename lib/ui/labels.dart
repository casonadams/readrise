import 'package:readrise_plugin_api/readrise_plugin_api.dart';

String gradeLabel(Grade grade) => switch (grade) {
  Grade.preK => 'Pre-K',
  Grade.kindergarten => 'Kindergarten',
  _ => 'Grade ${grade.index - 1}',
};

String starsText(int stars) =>
    [for (var s = 1; s <= 3; s++) s <= stars ? '\u2605' : '\u2606'].join();
