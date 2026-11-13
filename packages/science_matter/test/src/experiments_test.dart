import 'package:flutter_test/flutter_test.dart';
import 'package:readrise_testing/readrise_testing.dart';
import 'package:science_matter/src/experiments/balloon.dart';
import 'package:science_matter/src/experiments/evaporation.dart';
import 'package:science_matter/src/experiments/heat.dart';
import 'package:science_matter/src/experiments/zoom.dart';

void main() {
  experimentContract(
    'balloon',
    balloonExperiment,
    observe: tapTimes('Pump', 4),
  );
  experimentContract('zoom', zoomExperiment, observe: slideToEnd);
  experimentContract('heat a gas', heatGasExperiment, observe: slideToEnd);
  experimentContract('stove', stoveExperiment, observe: slideToEnd);
  experimentContract('evaporation', evaporationExperiment, observe: slideToEnd);

  testWidgets('balloon: three pumps are not enough; the fourth shows mass', (
    tester,
  ) async {
    final reports = await pumpExperiment(tester, balloonExperiment);
    await tapTimes('Pump', 3)(tester);
    await tester.pump(const Duration(seconds: 2));
    expect(reports, isEmpty);

    await tapTimes('Pump', 1)(tester);
    await tester.pump(const Duration(seconds: 2));
    expect(reports, hasLength(1));
    expect(find.text('Has mass'), findsOneWidget);
  });

  testWidgets('evaporation: particles move to the air and none disappear', (
    tester,
  ) async {
    await pumpExperiment(tester, evaporationExperiment);
    expect(find.text('In the glass: 30'), findsOneWidget);
    expect(find.text('In the air: 0'), findsOneWidget);

    await slideToEnd(tester);
    expect(find.text('In the glass: 20'), findsOneWidget);
    expect(find.text('In the air: 10'), findsOneWidget);
  });
}
