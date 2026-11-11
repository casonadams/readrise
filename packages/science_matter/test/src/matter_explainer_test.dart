import 'package:flutter_test/flutter_test.dart';
import 'package:science_matter/src/matter_explainer.dart';

import '../support/scene_host.dart';

void main() {
  testWidgets('step 0 shows matter and its two properties only', (
    tester,
  ) async {
    await pumpScene(tester, matterExplainerScene, 0);
    expect(opacityOf(tester, 'Matter'), 1);
    expect(opacityOf(tester, 'Has mass'), 1);
    expect(opacityOf(tester, 'Takes up space'), 1);
    expect(opacityOf(tester, 'Rock'), 0);
    expect(opacityOf(tester, 'Energy'), 0);
  });

  testWidgets('step 1 reveals rock, water and air but not energy', (
    tester,
  ) async {
    await pumpScene(tester, matterExplainerScene, 1);
    for (final item in ['Rock', 'Water', 'Air']) {
      expect(opacityOf(tester, item), 1, reason: item);
    }
    expect(opacityOf(tester, 'Light'), 0);
  });

  testWidgets('energy appears at step 2 and is crossed out at step 3', (
    tester,
  ) async {
    await pumpScene(tester, matterExplainerScene, 2);
    expect(opacityOf(tester, 'Light'), 1);
    expect(opacityOf(tester, 'No mass'), 0);

    await pumpScene(tester, matterExplainerScene, 3);
    expect(opacityOf(tester, 'No mass'), 1);
    expect(opacityOf(tester, 'No space'), 1);
  });
}
