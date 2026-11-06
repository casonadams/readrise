import 'package:flutter_test/flutter_test.dart';
import 'package:phonics_alphabet/phonics_alphabet.dart';
import 'package:phonics_alphabet/src/feed_monster_activity.dart';
import 'package:phonics_alphabet/src/letter_intro_activity.dart';
import 'package:phonics_alphabet/src/letter_quiz_activity.dart';
import 'package:phonics_alphabet/src/letter_trace_activity.dart';
import 'package:phonics_alphabet/src/letters.dart';
import 'package:readrise_plugin_api/readrise_plugin_api.dart';

void main() {
  final courses = AlphabetCourse.all();

  test('seven courses cover the alphabet in teaching order', () {
    expect(courses, hasLength(7));
    final taught = [
      for (final c in courses)
        for (final l in c.lessons)
          if (l.id != 'review') l.id,
    ];
    expect(taught.join(), allLetters.map((l) => l.char).join());
  });

  test('each course opens only after the one before it', () {
    expect(courses.first.requires, isEmpty);
    for (var i = 1; i < courses.length; i++) {
      expect(courses[i].requires, [courses[i - 1].id]);
    }
    final ids = courses.map((c) => c.id).toList();
    expect(ids.toSet(), hasLength(ids.length));
  });

  test('course titles name their letters', () {
    expect(courses.first.title, 'Alphabet 1: S A T P');
    expect(courses.last.title, 'Alphabet 7: Y Z Q');
  });

  test('pre-K covers the first four sets and kindergarten the rest', () {
    expect(courses.map((c) => c.grade), [
      Grade.preK,
      Grade.preK,
      Grade.preK,
      Grade.preK,
      Grade.kindergarten,
      Grade.kindergarten,
      Grade.kindergarten,
    ]);
  });

  test('each course ends with a review, and lesson ids are unique', () {
    for (final c in courses) {
      expect(c.lessons.last.id, 'review');
      expect(c.lessons.last.title, 'Review');
      final ids = c.lessons.map((l) => l.id).toList();
      expect(ids.toSet(), hasLength(ids.length));
    }
  });

  test('a letter lesson: meet it, write it, pop it, feed the monster', () {
    final lesson = courses.first.lessons.first;
    expect(lesson.title, 'Ss');
    expect(lesson.activities.map((a) => a.runtimeType), [
      LetterIntroActivity,
      LetterTraceActivity,
      LetterQuizActivity,
      FeedMonsterActivity,
    ]);
  });

  test('x has no monster because no common word starts with it', () {
    final x = courses[5].lessons.firstWhere((l) => l.id == 'x');
    expect(x.activities.map((a) => a.runtimeType), [
      LetterIntroActivity,
      LetterTraceActivity,
      LetterQuizActivity,
    ]);
  });

  test('a review is a single balloon quiz', () {
    final review = courses.first.lessons.last;
    expect(review.activities.map((a) => a.runtimeType), [LetterQuizActivity]);
  });
}
