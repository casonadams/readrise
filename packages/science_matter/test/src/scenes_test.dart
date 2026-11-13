import 'package:flutter_test/flutter_test.dart';
import 'package:science_matter/src/heat_scenes.dart';
import 'package:science_matter/src/states_scenes.dart';
import 'package:science_matter/src/water_molecule_scene.dart';

import 'package:readrise_testing/readrise_testing.dart';
import 'package:science_kit/science_kit.dart';

void main() {
  testWidgets('molecule atoms join at step 1, then count, then H2O', (
    tester,
  ) async {
    double gap() =>
        (tester.getCenter(find.text('O')) -
                tester.getCenter(find.text('H').first))
            .distance;

    await pumpScene(tester, waterMoleculeScene, 0);
    final apart = gap();
    expect(opacityOf(tester, '2 hydrogen'), 0);

    await pumpScene(tester, waterMoleculeScene, 1);
    expect(gap(), lessThan(apart / 2));

    await pumpScene(tester, waterMoleculeScene, 2);
    expect(opacityOf(tester, '2 hydrogen'), 1);
    expect(opacityOf(tester, '1 oxygen'), 1);
    expect(opacityOf(tester, 'H\u2082O'), 0);

    await pumpScene(tester, waterMoleculeScene, 3);
    expect(opacityOf(tester, 'H\u2082O'), 1);
    expect(opacityOf(tester, '\u2212'), 0);
    expect(opacityOf(tester, '+'), 0);

    await pumpScene(tester, waterMoleculeScene, 4);
    expect(opacityOf(tester, '\u2212'), 1);
    expect(find.text('+'), findsNWidgets(2));
    expect(opacityOf(tester, '+'), 1);
  });

  testWidgets('trio labels all states and adds arrangement at step 1', (
    tester,
  ) async {
    await pumpScene(tester, statesTrioScene, 0);
    for (final name in ['Solid', 'Liquid', 'Gas']) {
      expect(find.text(name), findsOneWidget);
    }
    expect(opacityOf(tester, 'Packed tight'), 0);

    await pumpScene(tester, statesTrioScene, 1);
    for (final text in [
      'Packed tight',
      'Slide past each other',
      'Fly far apart',
    ]) {
      expect(opacityOf(tester, text), 1, reason: text);
    }
  });

  testWidgets('a state scene shows shape and volume from step 1', (
    tester,
  ) async {
    final scene = stateScene(MatterState.liquid);
    await pumpScene(tester, scene, 0);
    expect(opacityOf(tester, 'Own shape'), 0);

    await pumpScene(tester, scene, 1);
    expect(opacityOf(tester, 'Own shape'), 1);
    expect(opacityOf(tester, 'Own volume'), 1);
  });

  test('speedWord rises with temperature', () {
    expect(speedWord(-20), 'Slow');
    expect(speedWord(50), 'Medium');
    expect(speedWord(120), 'Fast');
  });

  test('changeName names neighbouring changes in both directions', () {
    const s = MatterState.solid, l = MatterState.liquid, g = MatterState.gas;
    expect(changeName(s, l), 'Melting');
    expect(changeName(l, s), 'Freezing');
    expect(changeName(l, g), 'Boiling');
    expect(changeName(g, l), 'Condensing');
    expect(changeName(l, l), isNull);
    expect(changeName(s, g), isNull);
  });

  testWidgets('heat scene ends each stage at its target temperature', (
    tester,
  ) async {
    final scene = heatScene(const [HeatStage(20, 20), HeatStage(20, 90)]);
    await pumpScene(tester, scene, 0);
    expect(find.text('20\u00B0C'), findsOneWidget);
    expect(find.text('Particles: Slow'), findsOneWidget);

    await pumpScene(tester, scene, 1);
    expect(find.text('90\u00B0C'), findsOneWidget);
    expect(find.text('Particles: Fast'), findsOneWidget);
  });

  testWidgets('a stage that changes state names the change and energy', (
    tester,
  ) async {
    final scene = heatScene(const [
      HeatStage(20, 20),
      HeatStage(20, 110),
      HeatStage(20, -20),
    ]);
    await pumpScene(tester, scene, 0);
    expect(find.textContaining('energy'), findsNothing);

    await pumpScene(tester, scene, 1);
    expect(opacityOf(tester, 'Boiling'), 1);
    expect(opacityOf(tester, '+ energy'), 1);

    await pumpScene(tester, scene, 2);
    expect(opacityOf(tester, 'Freezing'), 1);
    expect(opacityOf(tester, '\u2212 energy'), 1);
  });

  testWidgets('the states story shows all three, each one, then all three', (
    tester,
  ) async {
    await pumpScene(tester, statesScene, 0);
    expect(find.text('Liquid'), findsOneWidget);
    expect(find.text('Gas'), findsOneWidget);

    await pumpScene(tester, statesScene, 2);
    expect(find.text('Gas'), findsNothing);
    expect(opacityOf(tester, 'Own volume'), 1);

    await pumpScene(tester, statesScene, 4);
    expect(opacityOf(tester, 'Fly far apart'), 1);
  });
}
