import 'package:readrise_plugin_api/readrise_plugin_api.dart';

import 'feed_monster_activity.dart';
import 'letter.dart';
import 'letter_intro_activity.dart';
import 'letter_quiz_activity.dart';
import 'letter_trace_activity.dart';

/// Meet a letter, write it, pop it, then feed it to the monster. Letters
/// without a word that starts with them (x) skip the monster.
class LetterLesson implements LessonPlugin {
  LetterLesson({
    required this.letter,
    required List<Letter> learned,
    required List<Letter> unseen,
  }) : activities = [
         LetterIntroActivity(letter),
         LetterTraceActivity(letter),
         LetterQuizActivity.lesson(
           letter: letter,
           learned: learned,
           unseen: unseen,
         ),
         if (letter.startsWord)
           FeedMonsterActivity(
             letter: letter,
             learned: learned,
             unseen: unseen,
           ),
       ];

  final Letter letter;

  @override
  String get id => letter.char;

  @override
  String get title => letter.display;

  @override
  final List<ActivityPlugin> activities;
}

/// A balloon-popping review of every letter in a set.
class ReviewLesson implements LessonPlugin {
  ReviewLesson({required List<Letter> letters, required List<Letter> known})
    : activities = [LetterQuizActivity.review(letters: letters, known: known)];

  @override
  String get id => 'review';

  @override
  String get title => 'Review';

  @override
  final List<ActivityPlugin> activities;
}
