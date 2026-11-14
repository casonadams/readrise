import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phonics_alphabet/src/feed_monster_activity.dart';
import 'package:phonics_alphabet/src/letters.dart';

import '../support/letters.dart';

FeedMonsterActivity activityFor(String c) => FeedMonsterActivity(
  letter: letterOf(c),
  learned: before(c),
  unseen: after(c),
);

List<String> said(TestHost host) => (host.speaker as RecordingSpeaker).spoken;

bool edible(String word, String c) =>
    letterOf(c).pictures.any((p) => p.word == word);

/// Gives the current food to the right place, then waits out the reaction.
Future<void> serve(
  WidgetTester tester,
  TestHost host,
  String c, {
  bool wrong = false,
}) async {
  final good = edible(said(host).last, c);
  final feed = wrong ? !good : good;
  await tester.tap(find.byKey(Key(feed ? 'monster' : 'bin')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 900));
  await tester.pump();
}

void main() {
  testWidgets('asks for the letter, then shows the first food and says it', (
    tester,
  ) async {
    final host = await pumpActivity(tester, activityFor('s'));
    expect(said(host).first, 'Feed me things that start with s');
    expect(find.text('Feed me things that start with'), findsOneWidget);
    expect(find.text('Ss'), findsOneWidget);
    expect(said(host), hasLength(2));
    final food = said(host).last;
    expect(
      allLetters.any((l) => l.pictures.any((p) => p.word == food)),
      isTrue,
    );
  });

  testWidgets('feeding everything correctly finishes with full XP', (
    tester,
  ) async {
    final host = await pumpActivity(tester, activityFor('s'));
    for (var i = 0; i < 6; i++) {
      await serve(tester, host, 's');
    }
    expect(host.results, hasLength(1));
    expect(host.results.single.xp, 30);
    expect(host.results.single.mistakes, 0);
  });

  testWidgets('the wrong choice is a mistake, and the same food returns', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final host = await pumpActivity(tester, activityFor('s'));
    final food = said(host).last;

    await serve(tester, host, 's', wrong: true);

    expect(said(host).last, food, reason: 'the food is offered again');
    expect(host.results, isEmpty);
    handle.dispose();
  });

  testWidgets('mistakes are reported and a missed food is practised again', (
    tester,
  ) async {
    final host = await pumpActivity(tester, activityFor('s'));
    await serve(tester, host, 's', wrong: true);
    var served = 0;
    while (host.results.isEmpty && served < 12) {
      await serve(tester, host, 's');
      served++;
    }
    expect(served, 7);
    expect(host.results.single.mistakes, 1);
    expect(host.results.single.xp, 27);
  });

  testWidgets('x is not playable, so its lesson leaves the monster out', (
    tester,
  ) async {
    expect(letterOf('x').startsWord, isFalse);
  });

  testWidgets('dragging food onto the monster feeds it', (tester) async {
    final host = await pumpActivity(tester, activityFor('s'));
    final food = said(host).last;
    final good = edible(food, 's');
    final from = tester.getCenter(
      find.byWidgetPredicate((w) => w is Draggable).first,
    );
    final to = tester.getCenter(find.byKey(Key(good ? 'monster' : 'bin')));

    final gesture = await tester.startGesture(from);
    await gesture.moveBy(const Offset(0, 30));
    await gesture.moveTo(to);
    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pump();

    expect(said(host).last, isNot(food));
    expect(host.results, isEmpty);
  });

  testWidgets('the monster and bin can be reached by screen readers', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpActivity(tester, activityFor('s'));
    expect(find.bySemanticsLabel('Feed the monster'), findsOneWidget);
    expect(find.bySemanticsLabel('Yuck, throw it away'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('fits a small phone at large text without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(640, 960);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await pumpActivity(tester, activityFor('s'), textScale: 1.8);
    expect(tester.takeException(), isNull);
  });

  test('each attempt offers pictures by its own seed', () {
    final seeds = {
      for (var s = 0; s < 10; s++) activityFor('m').shuffled(Random(s)).seed,
    };
    expect(seeds, hasLength(greaterThan(1)));
  });
}
