import 'package:readrise_plugin_api/readrise_plugin_api.dart';

import 'letter.dart';
import 'letter_intro_activity.dart';
import 'letter_quiz_activity.dart';

class LetterLesson implements LessonPlugin {
  LetterLesson({
    required this.letter,
    required List<Letter> learned,
    required List<Letter> unseen,
  }) : activities = [
         LetterIntroActivity(letter),
         LetterQuizActivity(letter: letter, learned: learned, unseen: unseen),
       ];

  final Letter letter;

  @override
  String get id => letter.char;

  @override
  String get title => letter.display;

  @override
  final List<ActivityPlugin> activities;
}
