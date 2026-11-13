import 'package:flutter_test/flutter_test.dart';
import 'package:science_kit/science_kit.dart';

void main() {
  group('waterStateAt', () {
    final cases = <double, MatterState>{
      -20: MatterState.solid,
      -0.1: MatterState.solid,
      0: MatterState.liquid,
      25: MatterState.liquid,
      99.9: MatterState.liquid,
      100: MatterState.gas,
      120: MatterState.gas,
    };
    cases.forEach((celsius, state) {
      test('$celsius C -> ${state.name}', () {
        expect(waterStateAt(celsius), state);
      });
    });
  });

  test('energy rises with temperature and stays within 0..1', () {
    expect(energyAt(-50), 0);
    expect(energyAt(200), 1);
    expect(energyAt(50), greaterThan(energyAt(10)));
  });
}
