import 'package:flutter_test/flutter_test.dart';
import 'package:phonics_alphabet/src/trace/glyph_mask.dart';
import 'package:phonics_alphabet/src/trace/trace_checker.dart';

/// An "L": a vertical bar down the left and a bar along the bottom.
final lMask = GlyphMask.fromRows([
  '..............',
  '.###..........',
  '.###..........',
  '.###..........',
  '.###..........',
  '.###..........',
  '.###..........',
  '.###..........',
  '.###..........',
  '.###..........',
  '.############.',
  '.############.',
  '.############.',
  '..............',
]);

Offset at(double x, double y) => Offset(x, y);

void traceL(TraceChecker c) {
  c.startStroke(at(0.18, 0.10));
  c.extendStroke(at(0.18, 0.80));
  c.extendStroke(at(0.80, 0.80));
  c.endStroke();
}

void main() {
  test('tracing the whole letter completes it', () {
    final c = TraceChecker(lMask);
    expect(c.isComplete, isFalse);
    traceL(c);
    expect(c.coverage, greaterThan(0.9));
    expect(c.accuracy, greaterThan(0.9));
    expect(c.isComplete, isTrue);
  });

  test(
    'a jump between two far points is filled in, so speed does not matter',
    () {
      final c = TraceChecker(lMask);
      c.startStroke(at(0.18, 0.10));
      c.extendStroke(at(0.18, 0.80));
      c.extendStroke(at(0.80, 0.80));
      expect(c.isComplete, isTrue);
    },
  );

  test('half the letter is not enough', () {
    final c = TraceChecker(lMask);
    c.startStroke(at(0.18, 0.10));
    c.extendStroke(at(0.18, 0.80));
    expect(c.coverage, inInclusiveRange(0.3, 0.65));
    expect(c.isComplete, isFalse);
  });

  test(
    'scribbling over the whole box covers the letter but does not count',
    () {
      final c = TraceChecker(lMask);
      for (var y = 0.02; y < 1; y += 0.05) {
        c.startStroke(at(0.02, y));
        c.extendStroke(at(0.98, y));
      }
      expect(c.coverage, greaterThan(0.9));
      expect(c.accuracy, lessThan(0.6));
      expect(c.isComplete, isFalse);
    },
  );

  test('drawing far away from the letter gets nowhere', () {
    final c = TraceChecker(lMask);
    c.startStroke(at(0.9, 0.05));
    c.extendStroke(at(0.9, 0.5));
    expect(c.coverage, 0);
    expect(c.accuracy, 0);
    expect(c.isComplete, isFalse);
  });

  test('a little wobble off the line is forgiven', () {
    final c = TraceChecker(lMask);
    c.startStroke(at(0.22, 0.10));
    c.extendStroke(at(0.22, 0.80));
    c.extendStroke(at(0.80, 0.82));
    expect(c.isComplete, isTrue);
  });

  test('several separate strokes add up', () {
    final c = TraceChecker(lMask);
    c.startStroke(at(0.18, 0.10));
    c.extendStroke(at(0.18, 0.80));
    c.endStroke();
    expect(c.isComplete, isFalse);
    c.startStroke(at(0.18, 0.80));
    c.extendStroke(at(0.80, 0.80));
    c.endStroke();
    expect(c.isComplete, isTrue);
  });

  test('reset forgets everything', () {
    final c = TraceChecker(lMask);
    traceL(c);
    c.reset();
    expect(c.coverage, 0);
    expect(c.accuracy, 0);
    expect(c.isComplete, isFalse);
    traceL(c);
    expect(c.isComplete, isTrue);
  });

  test('points outside the box are ignored without crashing', () {
    final c = TraceChecker(lMask);
    c.startStroke(at(-0.5, -0.5));
    c.extendStroke(at(1.5, 1.5));
    expect(c.isComplete, isFalse);
  });

  test('an empty mask can never be completed', () {
    final c = TraceChecker(
      GlyphMask.fromRows(['....', '....', '....', '....']),
    );
    c.startStroke(at(0.5, 0.5));
    c.extendStroke(at(0.6, 0.6));
    expect(c.isComplete, isFalse);
  });
}
