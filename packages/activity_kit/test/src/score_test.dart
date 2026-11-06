import 'package:activity_kit/src/score.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final cases = <String, (int, int, int, int)>{
    'all first try -> full': (4, 0, 4, 20),
    'all recovered -> half': (0, 4, 4, 10),
    'mixed': (2, 2, 4, 15),
    'nothing right -> zero': (0, 0, 4, 0),
  };
  cases.forEach((name, c) {
    test(name, () {
      expect(scoreXp(firstTry: c.$1, recovered: c.$2, total: c.$3), c.$4);
    });
  });

  test('respects a custom maximum', () {
    expect(scoreXp(firstTry: 3, recovered: 0, total: 3, max: 30), 30);
  });
}
