import 'package:activity_kit/activity_kit.dart';
import 'package:faker/faker.dart' hide Color;
import 'package:flutter/painting.dart';
import 'package:readrise_plugin_api/readrise_plugin_api.dart';

/// Made-up lesson content for tests where the words do not matter. Seeded,
/// so a failing test fails the same way every run.
class ContentFaker {
  ContentFaker({int seed = 1}) : _faker = Faker(seed: seed);

  final Faker _faker;
  final Set<String> _used = {};
  var _items = 0;

  /// A few words this faker has not returned before, so a finder for it
  /// matches one widget.
  String phrase() {
    while (true) {
      final text = _faker.lorem.words(3).join(' ');
      if (_used.add(text)) return text;
    }
  }

  String sentence() => _faker.lorem.sentence();

  Right right() => Right(phrase());

  Wrong wrong() => Wrong(phrase(), sentence());

  /// [wrongs] wrong choices with one right choice at [rightAt].
  List<Choice> choices({int wrongs = 2, int rightAt = 0}) => [
    for (var i = 0; i <= wrongs; i++) i == rightAt ? right() : wrong(),
  ];

  ChoiceQuestion question({List<Choice>? choices, Reason? reason}) =>
      ChoiceQuestion(
        id: ItemId('item-${_items++}'),
        prompt: sentence(),
        choices: choices ?? this.choices(),
        explanation: sentence(),
        hint: sentence(),
        reason: reason,
      );

  Reason reason({List<Choice>? choices}) =>
      Reason(choices: choices ?? this.choices());

  PredictActivity prediction(Experiment experiment, {List<Choice>? choices}) =>
      PredictActivity(
        question: sentence(),
        choices: choices ?? this.choices(),
        tryIt: sentence(),
        experiment: experiment,
        outcome: sentence(),
      );

  Kid kid() => Kid(
    _faker.person.firstName(),
    skin: const Color(0xFFC68642),
    hair: const Color(0xFF3E2723),
  );

  WhoIsRightActivity debate({List<Choice>? claims}) => WhoIsRightActivity(
    situation: sentence(),
    claims: [for (final c in claims ?? choices(wrongs: 1)) Claim(kid(), c)],
    explanation: sentence(),
  );

  SortActivity sort({int bins = 2, int itemsPerBin = 2}) {
    final binList = [for (var i = 0; i < bins; i++) SortBin(phrase())];
    return SortActivity(
      prompt: sentence(),
      hint: sentence(),
      bins: binList,
      items: [
        for (final bin in binList)
          for (var i = 0; i < itemsPerBin; i++)
            SortItem(phrase(), bin: bin, why: sentence()),
      ],
    );
  }
}
