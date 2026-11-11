import 'package:activity_kit/activity_kit.dart';
import 'package:readrise_plugin_api/readrise_plugin_api.dart';

import '../balloon_experiment.dart';
import '../matter_explainer.dart';
import '../water_molecule_scene.dart';
import 'classmates.dart';

/// Is air matter? Targets "air weighs nothing" and "light is matter".
const matterLesson = BasicLesson(
  id: 'matter',
  title: 'Matter',
  activities: <ActivityPlugin>[
    PredictActivity(
      question:
          'Two empty balloons balance on a scale. What happens if you pump '
          'air into one?',
      options: [
        'It tips toward the full balloon',
        'It tips toward the empty balloon',
        'It stays level',
      ],
      answer: 0,
      tryIt: 'Tap Pump to fill the right balloon with air.',
      experiment: balloonExperiment,
      outcome: 'Air has mass, so the full balloon is heavier. Air also takes up space. That makes air matter.',
      reactions: {
        1: 'Some balloons float, but plain air still has mass.',
        2: 'Air is easy to forget because you cannot see it.',
      },
    ),
    ExplainerActivity(
      title: 'Everything is matter',
      steps: matterExplainerSteps,
      scene: matterExplainerScene,
    ),
    ExplainerActivity(
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
    SortActivity(
      prompt: 'Is it matter?',
      hint:
          'Ask: does it have mass and take up space? If yes, it is matter. '
          'If it is a kind of energy, it is not.',
      bins: ['Matter', 'Not matter'],
      items: [
        SortItem('Rock', bin: 0, why: 'A rock has mass and takes up space.'),
        SortItem('Light', bin: 1, why: 'Light is energy. It has no mass.'),
        SortItem(
          'Water',
          bin: 0,
          why: 'Water fills a cup, so it takes up space.',
        ),
        SortItem(
          'Sound',
          bin: 1,
          why: 'Sound is energy moving through matter.',
        ),
        SortItem('Air', bin: 0, why: 'Air fills a balloon and has mass.'),
        SortItem('Heat', bin: 1, why: 'Heat is energy. It takes up no space.'),
        SortItem('Wood', bin: 0, why: 'Wood has mass and takes up space.'),
      ],
    ),
    ChoiceQuizActivity(
      questions: [
        ChoiceQuestion(
          prompt: 'Is air matter?',
          options: ['Yes', 'No'],
          answer: 0,
          hint: 'Remember what the balloon did to the scale.',
          feedback: {1: 'The full balloon tipped the scale, so air has mass.'},
          reason: Reason(
            options: [
              'It has mass and takes up space',
              'You can feel the wind',
              'Everything you cannot see is matter',
            ],
            answer: 0,
            feedback: {
              1:
                  'Wind is a clue, but matter means having mass and taking up '
                  'space.',
              2: 'Light is invisible too, and light is not matter.',
            },
          ),
          explanation:
              'Air has mass (it tipped the scale) and takes up space (it '
              'filled the balloon). That makes it matter.',
        ),
        ChoiceQuestion(
          prompt: 'What are atoms?',
          options: [
            'The tiny particles all matter is made of',
            'A kind of energy',
            'Only found in solids',
          ],
          answer: 0,
          hint: 'Think about what everything is made of.',
          feedback: {
            1: 'Energy is not matter, but atoms are the pieces of matter.',
            2: 'Liquids and gases are made of atoms too.',
          },
          explanation:
              'Every kind of matter, solid, liquid, or gas, is made of atoms.',
        ),
        ChoiceQuestion(
          prompt: 'How many atoms are in one water molecule (H2O)?',
          options: ['1', '2', '3', '4'],
          answer: 2,
          hint: 'Count the H atoms (the 2 in H2O) and add the O.',
          feedback: {
            0: 'H2O names more than one atom: H, H, and O.',
            1: 'The 2 counts only the hydrogen. Add the oxygen too.',
            3: 'Water has 2 hydrogen and 1 oxygen. Count again.',
          },
          explanation: 'Two hydrogen atoms plus one oxygen atom makes 3 atoms.',
        ),
      ],
    ),
    WhoIsRightActivity(
      situation: 'Mia and Leo see a sunbeam shining through a dusty room.',
      claims: [
        Claim(mia, 'The sunbeam is matter, because I can see it.'),
        Claim(leo, 'The light is energy. The dust floating in it is matter.'),
      ],
      answer: 1,
      feedback: {
        0:
            'Seeing something does not make it matter. Light has no mass and '
            'takes up no space.',
      },
      explanation:
          'Light is energy: it has no mass and takes up no space. The dust '
          'specks are tiny bits of matter that the light lets you see.',
    ),
  ],
);
