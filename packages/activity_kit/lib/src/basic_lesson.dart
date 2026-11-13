import 'package:readrise_plugin_api/readrise_plugin_api.dart';

class BasicLesson implements LessonPlugin {
  const BasicLesson({
    required this.id,
    required this.title,
    required this.activities,
  });

  @override
  final LessonId id;

  @override
  final String title;

  @override
  final List<ActivityPlugin> activities;
}
