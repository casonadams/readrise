import 'package:flutter_test/flutter_test.dart';
import 'package:readrise/domain/curriculum.dart';
import 'package:readrise/domain/progress.dart';

void main() {
  final skills = curriculum.skills;
  Progress record(Progress p, Skill s, int stars, DateTime day) =>
      p.recordLesson(skill: s, earnedStars: stars, earnedXp: 10, today: day);

  test('later skills unlock only after a star on the previous one', () {
    var p = const Progress();
    expect(p.isUnlocked(curriculum, skills[0]), isTrue);
    expect(p.isUnlocked(curriculum, skills[1]), isFalse);

    p = record(p, skills[0], 1, DateTime(2026, 1, 1));
    expect(p.isUnlocked(curriculum, skills[1]), isTrue);
    expect(p.isUnlocked(curriculum, skills[2]), isFalse);
  });

  test('stars keep the best result; XP accumulates', () {
    var p = record(const Progress(), skills[0], 3, DateTime(2026, 1, 1));
    p = record(p, skills[0], 1, DateTime(2026, 1, 1));
    expect(p.starsFor(skills[0]), 3);
    expect(p.xp, 20);
  });

  test('streak: same day holds, next day grows, gap resets', () {
    var p = record(const Progress(), skills[0], 1, DateTime(2026, 3, 8));
    p = record(p, skills[0], 1, DateTime(2026, 3, 8, 20));
    expect(p.streak, 1);
    p = record(p, skills[0], 1, DateTime(2026, 3, 9));
    expect(p.streak, 2);
    p = record(p, skills[0], 1, DateTime(2026, 3, 12));
    expect(p.streak, 1);
  });

  test('displayed streak lapses after a missed day', () {
    final p = record(const Progress(), skills[0], 1, DateTime(2026, 3, 8));
    expect(p.streakOn(DateTime(2026, 3, 9)), 1);
    expect(p.streakOn(DateTime(2026, 3, 10)), 0);
  });

  test('survives JSON round trip', () {
    final p = record(const Progress(), skills[0], 2, DateTime(2026, 3, 8));
    final back = Progress.fromJson(p.toJson());
    expect(back.xp, p.xp);
    expect(back.streak, p.streak);
    expect(back.lastPractice, p.lastPractice);
    expect(back.stars, p.stars);
  });
}
