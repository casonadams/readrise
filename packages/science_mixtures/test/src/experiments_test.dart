import 'package:flutter_test/flutter_test.dart';
import 'package:readrise_testing/readrise_testing.dart';
import 'package:science_mixtures/src/experiments/melt_or_dissolve.dart';
import 'package:science_mixtures/src/experiments/spoons.dart';
import 'package:science_mixtures/src/experiments/stir.dart';

void main() {
  experimentContract('dissolving', dissolvingExperiment, observe: slideToEnd);
  experimentContract('mass', massExperiment, observe: slideToEnd);
  experimentContract(
    'melt or dissolve',
    meltOrDissolveExperiment,
    observe: slideToEnd,
  );
  experimentContract(
    'spoons',
    spoonsExperiment,
    observe: tapTimes('Add a spoon', 6),
  );

  testWidgets('dissolving: every sugar particle is still counted', (
    tester,
  ) async {
    await pumpExperiment(tester, dissolvingExperiment);
    expect(find.text('Still in the cube: 12'), findsOneWidget);
    await slideToEnd(tester);
    expect(find.text('Still in the cube: 0'), findsOneWidget);
    expect(find.text('Sugar particles: 12'), findsOneWidget);
  });

  testWidgets('mass: the scale reads 110 g before and after stirring', (
    tester,
  ) async {
    await pumpExperiment(tester, massExperiment);
    expect(find.text('110 g'), findsOneWidget);
    await slideToEnd(tester);
    expect(find.text('110 g'), findsOneWidget);
  });

  testWidgets('spoons: three dissolve, then the water is full', (tester) async {
    await pumpExperiment(tester, spoonsExperiment);
    await tapTimes('Add a spoon', 3)(tester);
    expect(find.text('Dissolved: 3'), findsOneWidget);
    await tapTimes('Add a spoon', 2)(tester);
    expect(find.text('Spoons added: 5'), findsOneWidget);
    expect(find.text('Dissolved: 3'), findsOneWidget);
  });
}
