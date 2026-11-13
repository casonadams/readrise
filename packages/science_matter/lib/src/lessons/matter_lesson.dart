import 'package:activity_kit/activity_kit.dart';
import 'package:readrise_plugin_api/readrise_plugin_api.dart';
import 'package:science_kit/science_kit.dart';

import '../experiments/balloon.dart';
import '../matter_explainer.dart';
import '../water_molecule_scene.dart';

const _matter = SortBin('Matter');
const _notMatter = SortBin('Not matter');

/// Is air matter? Targets "air weighs nothing" and "light is matter".
final matterLesson = ScienceLesson(
  id: const LessonId('matter'),
  title: 'Matter',
  predict: const PredictActivity(
    question:
        'Two empty balloons balance on a scale. What happens if you pump '
        'air into one?',
    choices: [
      Right('It tips toward the full balloon'),
      Wrong(
        'It tips toward the empty balloon',
        'Some balloons float, but plain air still has mass.',
      ),
      Wrong(
        'It stays level',
        'Air is easy to forget because you cannot see it.',
      ),
    ],
    tryIt: 'Tap Pump to fill the right balloon with air.',
    experiment: balloonExperiment,
    outcome:
        'Air has mass, so the full balloon is heavier. Air also takes up space. '
        'That makes air matter.',
  ),
  explain: [
    const ExplainerActivity(
      title: 'Everything is matter',
      steps: matterExplainerSteps,
      scene: matterExplainerScene,
    ),
    const ExplainerActivity(
      title: 'Tiny particles',
      steps: [
        ExplainerStep('All matter is made of tiny particles called atoms.'),
        ExplainerStep('Atoms join together in groups called molecules.'),
        ExplainerStep(
          'One water molecule has 3 atoms: 2 hydrogen atoms and 1 oxygen atom.',
        ),
        ExplainerStep('That is why water is written H2O.'),
        ExplainerStep(
          'Oxygen pulls electrons closer, so it is slightly negative (\u2212). '
          'The hydrogen atoms are slightly positive (+).',
        ),
      ],
      scene: waterMoleculeScene,
    ),
  ],
  practise: [
    const SortActivity(
      prompt: 'Is it matter?',
      hint:
          'Ask: does it have mass and take up space? If yes, it is matter. '
          'If it is a kind of energy, it is not.',
      bins: [_matter, _notMatter],
      items: [
        SortItem(
          'Rock',
          bin: _matter,
          why: 'A rock has mass and takes up space.',
        ),
        SortItem(
          'Light',
          bin: _notMatter,
          why: 'Light is energy. It has no mass.',
        ),
        SortItem(
          'Water',
          bin: _matter,
          why: 'Water fills a cup, so it takes up space.',
        ),
        SortItem(
          'Sound',
          bin: _notMatter,
          why: 'Sound is energy moving through matter.',
        ),
        SortItem('Air', bin: _matter, why: 'Air fills a balloon and has mass.'),
        SortItem(
          'Heat',
          bin: _notMatter,
          why: 'Heat is energy. It takes up no space.',
        ),
        SortItem(
          'Wood',
          bin: _matter,
          why: 'Wood has mass and takes up space.',
        ),
      ],
    ),
  ],
  check: [
    ChoiceQuestion(
      id: ItemId('matter-air'),
      ordered: true,
      prompt: 'Is air matter?',
      choices: [
        Right('Yes'),
        Wrong('No', 'The full balloon tipped the scale, so air has mass.'),
      ],
      hint: 'Remember what the balloon did to the scale.',
      reason: Reason(
        choices: [
          Right('It has mass and takes up space'),
          Wrong(
            'You can feel the wind',
            'Wind is a clue, but matter means having mass and taking up '
                'space.',
          ),
          Wrong(
            'Everything you cannot see is matter',
            'Light is invisible too, and light is not matter.',
          ),
        ],
      ),
      explanation:
          'Air has mass (it tipped the scale) and takes up space (it '
          'filled the balloon). That makes it matter.',
    ),
    ChoiceQuestion(
      id: ItemId('matter-atoms'),
      prompt: 'What are atoms?',
      choices: [
        Right('The tiny particles all matter is made of'),
        Wrong(
          'A kind of energy',
          'Energy is not matter, but atoms are the pieces of matter.',
        ),
        Wrong(
          'Only found in solids',
          'Liquids and gases are made of atoms too.',
        ),
      ],
      hint: 'Think about what everything is made of.',
      explanation:
          'Every kind of matter, solid, liquid, or gas, is made of atoms.',
    ),
    ChoiceQuestion(
      id: ItemId('matter-h2o-atoms'),
      ordered: true,
      prompt: 'How many atoms are in one water molecule (H2O)?',
      choices: [
        Wrong('1', 'H2O names more than one atom: H, H, and O.'),
        Wrong('2', 'The 2 counts only the hydrogen. Add the oxygen too.'),
        Right('3'),
        Wrong('4', 'Water has 2 hydrogen and 1 oxygen. Count again.'),
      ],
      hint: 'Count the H atoms (the 2 in H2O) and add the O.',
      explanation: 'Two hydrogen atoms plus one oxygen atom makes 3 atoms.',
    ),
  ],
  debate: const WhoIsRightActivity(
    situation: 'Mia and Leo see a sunbeam shining through a dusty room.',
    claims: [
      Claim(
        mia,
        Wrong(
          'The sunbeam is matter, because I can see it.',
          'Seeing something does not make it matter. Light has no mass and '
              'takes up no space.',
        ),
      ),
      Claim(
        leo,
        Right('The light is energy. The dust floating in it is matter.'),
      ),
    ],
    explanation:
        'Light is energy: it has no mass and takes up no space. The dust '
        'specks are tiny bits of matter that the light lets you see.',
  ),
);
