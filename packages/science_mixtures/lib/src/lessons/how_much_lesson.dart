import 'package:activity_kit/activity_kit.dart';
import 'package:readrise_plugin_api/readrise_plugin_api.dart';
import 'package:science_kit/science_kit.dart';

import '../experiments/spoons.dart';
import '../scenes.dart';
import 'mass_lesson.dart';
import 'melt_or_dissolve_lesson.dart';

const _all = SortBin('All dissolves');
const _some = SortBin('Some stays at the bottom');

/// Water can only dissolve so much. Targets "stir long enough and any
/// amount dissolves" (Blanco & Prieto 1997, pupils' views on how stirring
/// and temperature affect dissolving, International Journal of Science
/// Education 19(3)).
final howMuchLesson = ScienceLesson(
  id: LessonId('how-much'),
  title: 'How much?',
  warmUp: WarmUp(
    recalls: [meltOrDissolveLesson, massLesson],
    questions: const [
      ChoiceQuestion(
        id: ItemId('how-much-warm-mass'),
        prompt:
            'You dissolve 5 g of salt in 100 g of water. What is the mass of '
            'the salt water?',
        ordered: true,
        choices: [
          Wrong('100 g', 'Dissolved salt still has mass.'),
          Right('105 g'),
          Wrong('110 g', 'Only 5 g of salt was added.'),
        ],
        hint: 'Add the water and the salt together.',
        explanation: '100 g + 5 g = 105 g, because every particle stays.',
      ),
      ChoiceQuestion(
        id: ItemId('how-much-warm-heat'),
        prompt: 'Which change always needs heat?',
        choices: [
          Wrong('Dissolving', 'Sugar dissolves in cold lemonade.'),
          Right('Melting'),
          Wrong('Both', 'Only melting needs heat; dissolving needs a liquid.'),
        ],
        hint: 'Think about sugar in cold lemonade.',
        explanation: 'Melting needs heat. Dissolving only needs a liquid.',
      ),
    ],
  ),
  predict: const PredictActivity(
    question:
        'You keep stirring spoon after spoon of sugar into one glass of '
        'water. What happens?',
    choices: [
      Wrong(
        'It all dissolves, however much you add',
        'A common idea, and it holds for the first few spoons!',
      ),
      Wrong('The water turns solid', 'The water stays liquid the whole time.'),
      Right('After a few spoons, extra sugar stays at the bottom'),
    ],
    tryIt: 'Tap to add one spoon of sugar at a time.',
    experiment: spoonsExperiment,
    outcome:
        'The water can only hold so much sugar. After that, extra sugar '
        'stays solid at the bottom.',
  ),
  explain: [
    ExplainerActivity(
      title: 'How much can dissolve?',
      steps: const [
        ExplainerStep('One spoon of sugar dissolves easily.'),
        ExplainerStep('A few more spoons dissolve too.'),
        ExplainerStep(
          'Then the water is full. A solution that cannot dissolve any more '
          'is called saturated.',
        ),
        ExplainerStep(
          'Extra sugar stays solid at the bottom, however long you stir.',
        ),
        ExplainerStep('Warm water can dissolve more sugar than cold water.'),
      ],
      scene: spoonsScene,
    ),
  ],
  practise: const [
    SortActivity(
      prompt: 'Will it all dissolve?',
      hint: 'A little in a lot of water dissolves; a lot in a little does not.',
      bins: [_all, _some],
      items: [
        SortItem(
          'One spoon of sugar in a big glass',
          bin: _all,
          why: 'There is plenty of room for a little sugar.',
        ),
        SortItem(
          'Twenty spoons of sugar in a small glass',
          bin: _some,
          why: 'The water is full long before twenty spoons.',
        ),
        SortItem(
          'A pinch of salt in a pot of soup',
          bin: _all,
          why: 'A pinch is tiny next to a whole pot.',
        ),
        SortItem(
          'A cup of salt in a cup of water',
          bin: _some,
          why: 'That is far more salt than the water can hold.',
        ),
        SortItem(
          'A spoon of drink powder in a jug',
          bin: _all,
          why: 'A jug of water has room for one spoon.',
        ),
        SortItem(
          'Ten spoons of sugar in cold tea',
          bin: _some,
          why: 'Cold tea is full after a few spoons.',
        ),
      ],
    ),
  ],
  check: const [
    ChoiceQuestion(
      id: ItemId('how-much-stir'),
      prompt:
          'Sugar sits at the bottom of a saturated glass. You stir for ten '
          'more minutes. What happens?',
      choices: [
        Wrong(
          'It all dissolves in the end',
          'Stirring speeds up dissolving but cannot make more room.',
        ),
        Right('The extra sugar stays at the bottom'),
        Wrong(
          'The dissolved sugar comes back out',
          'Stirring does not undo dissolving.',
        ),
      ],
      hint: 'What does saturated mean?',
      reason: Reason(
        choices: [
          Right('The water cannot hold any more sugar'),
          Wrong(
            'Stirring makes sugar heavier',
            'Stirring never changes the mass of a particle.',
          ),
          Wrong(
            'Stirring only works on salt',
            'Stirring helps sugar and salt dissolve faster, up to the limit.',
          ),
        ],
      ),
      explanation:
          'A saturated solution is full. Stirring cannot make room for more '
          'sugar.',
    ),
    ChoiceQuestion(
      id: ItemId('how-much-warm-water'),
      prompt: 'How can you get more sugar to dissolve in a saturated glass?',
      choices: [
        Right('Warm the water'),
        Wrong('Stir it longer', 'Stirring makes it faster, not more.'),
        Wrong('Put it in the fridge', 'Cold water holds even less sugar.'),
      ],
      hint: 'Which water had room for more sugar: warm or cold?',
      explanation:
          'Warm water can dissolve more sugar than cold water, so warming it '
          'makes room for more.',
    ),
    ChoiceQuestion(
      id: ItemId('how-much-saturated'),
      prompt: 'What does saturated mean?',
      choices: [
        Wrong('Very wet', 'In science, saturated means a solution is full.'),
        Wrong(
          'It has no sugar in it',
          'A saturated solution holds all the sugar it can.',
        ),
        Right('It cannot dissolve any more'),
      ],
      hint: 'Think of the glass with sugar left at the bottom.',
      explanation: 'A saturated solution has dissolved as much as it can hold.',
    ),
  ],
  debate: const WhoIsRightActivity(
    situation:
        'Mia and Leo keep adding sugar to a glass of lemonade. Sugar starts '
        'piling up at the bottom.',
    claims: [
      Claim(
        leo,
        Wrong(
          'If we stir harder, all of it will dissolve.',
          'Stirring speeds dissolving up, but a full solution takes no more.',
        ),
      ),
      Claim(mia, Right('The lemonade is full. It cannot dissolve any more.')),
    ],
    explanation:
        'The lemonade is saturated. The extra sugar will stay at the bottom '
        'unless the lemonade is warmed.',
  ),
);
