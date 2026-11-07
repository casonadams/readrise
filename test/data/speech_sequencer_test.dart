import 'package:flutter_test/flutter_test.dart';
import 'package:readrise/data/speech_sequencer.dart';

class Line {
  Line(this.text, this.onDone, this.onError);

  final String text;
  final void Function() onDone;
  final void Function() onError;
}

class FakeEngine implements SpeechEngine {
  final List<Line> started = [];
  int cancels = 0;

  @override
  void start(
    String text, {
    required void Function() onDone,
    required void Function() onError,
  }) => started.add(Line(text, onDone, onError));

  @override
  void cancel() => cancels++;
}

const delay = Duration(milliseconds: 60);

/// Runs [body], then lets any safety timer run out so none is left pending.
void speakerTest(String name, Future<void> Function(WidgetTester) body) {
  testWidgets(name, (tester) async {
    await body(tester);
    await tester.pump(const Duration(seconds: 11));
  });
}

void main() {
  late FakeEngine engine;
  late SpeechSequencer speaker;

  setUp(() {
    engine = FakeEngine();
    speaker = SpeechSequencer(engine);
  });

  Future<void> start(WidgetTester tester) => tester.pump(delay);

  speakerTest('the line starts after a short pause, not instantly', (
    tester,
  ) async {
    speaker.speak('a');
    expect(engine.started, isEmpty);
    await tester.pump(const Duration(milliseconds: 30));
    expect(engine.started, isEmpty);
    await start(tester);
    expect(engine.started.map((l) => l.text), ['a']);
  });

  speakerTest('speak completes when the line ends', (tester) async {
    var done = false;
    speaker.speak('a').then((_) => done = true);
    await start(tester);
    await tester.pump();
    expect(done, isFalse);

    engine.started.single.onDone();
    await tester.pump();
    expect(done, isTrue);
  });

  speakerTest('an error never leaves the caller waiting', (tester) async {
    var done = false;
    speaker.speak('a').then((_) => done = true);
    await start(tester);
    engine.started.single.onError();
    await tester.pump();
    expect(done, isTrue);
  });

  speakerTest('a line the engine never reports on times out quickly', (
    tester,
  ) async {
    var done = false;
    speaker.speak('a').then((_) => done = true);
    await start(tester);
    await tester.pump(const Duration(milliseconds: 2000));
    expect(done, isFalse);
    await tester.pump(const Duration(milliseconds: 200));
    expect(done, isTrue);
  });

  speakerTest('a new line cancels the old one and releases its caller', (
    tester,
  ) async {
    var firstDone = false;
    speaker.speak('a').then((_) => firstDone = true);
    await start(tester);
    final cancelsBefore = engine.cancels;

    speaker.speak('b');
    await tester.pump();
    expect(firstDone, isTrue, reason: 'interrupted lines complete');
    expect(engine.cancels, greaterThan(cancelsBefore));

    await start(tester);
    expect(engine.started.map((l) => l.text), ['a', 'b']);
  });

  speakerTest('only the last of several quick lines is ever spoken', (
    tester,
  ) async {
    speaker.speak('a');
    speaker.speak('b');
    speaker.speak('c');
    await start(tester);
    expect(engine.started.map((l) => l.text), ['c']);
  });

  speakerTest('late events from an interrupted line are ignored', (
    tester,
  ) async {
    speaker.speak('a');
    await start(tester);
    final old = engine.started.single;

    var secondDone = false;
    speaker.speak('b').then((_) => secondDone = true);
    await start(tester);

    old.onError();
    old.onDone();
    await tester.pump();
    expect(secondDone, isFalse, reason: 'b is still being spoken');

    engine.started.last.onDone();
    await tester.pump();
    expect(secondDone, isTrue);
  });

  speakerTest('the timeout restarts for each line', (tester) async {
    speaker.speak('a');
    await start(tester);
    await tester.pump(const Duration(seconds: 2));
    speaker.speak('b');
    await start(tester);
    var done = false;
    speaker.speak('c').then((_) => done = true);
    await start(tester);
    await tester.pump(const Duration(milliseconds: 2000));
    expect(done, isFalse);
  });

  test('a longer line is given longer to finish', () {
    expect(
      defaultSpeechTimeout('Feed me things that start with s'),
      greaterThan(defaultSpeechTimeout('a')),
    );
    expect(defaultSpeechTimeout('a'), lessThan(const Duration(seconds: 3)));
    expect(
      defaultSpeechTimeout('Feed me things that start with s'),
      lessThan(const Duration(seconds: 8)),
    );
  });

  speakerTest('speaking works again after a line finished', (tester) async {
    speaker.speak('a');
    await start(tester);
    engine.started.single.onDone();
    await tester.pump();

    speaker.speak('b');
    await start(tester);
    expect(engine.started.map((l) => l.text), ['a', 'b']);
  });
}
