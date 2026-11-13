import 'package:activity_kit/activity_kit.dart';
import 'package:readrise_plugin_api/readrise_plugin_api.dart';

import '../experiments/heat.dart';
import '../heat_scenes.dart';
import 'classmates.dart';
import 'science_lesson.dart';

final _changesScene = heatScene(const [
  HeatStage(20, 20),
  HeatStage(-20, 20),
  HeatStage(20, -20),
  HeatStage(20, 110),
  HeatStage(110, 20),
  HeatStage(20, 20),
]);

const _energyAdded = SortBin('Energy added');
const _energyRemoved = SortBin('Energy removed');

/// Changes of state and conservation of mass. Targets "boiling bubbles are
/// air" and "evaporated water is gone".
final changesLesson = ScienceLesson(
  id: LessonId('changes'),
  title: 'Changes',
  warmUp: WarmUp(
    recalls: [LessonId('matter'), LessonId('heat')],
    questions: const [
      ChoiceQuestion(
        prompt: 'When you heat a gas, its particles...',
        choices: [
          Wrong('Get bigger', 'Particles stay the same size when heated.'),
          Right('Move faster'),
          Wrong('Disappear', 'Matter does not disappear when heated.'),
        ],
        hint: 'Remember the jar over the flame.',
        explanation: 'Heat speeds particles up. Their size stays the same.',
      ),
      ChoiceQuestion(
        prompt: 'Which of these is NOT matter?',
        choices: [
          Wrong('Steam', 'Steam is water as a gas, so it is matter.'),
          Right('Heat'),
          Wrong('Ice', 'Ice is water as a solid, so it is matter.'),
        ],
        hint: 'Which one has no mass?',
        explanation: 'Heat is energy. Steam and ice are both water.',
      ),
    ],
  ),
  predict: const PredictActivity(
    question: 'Water boils in a pot. What are the bubbles made of?',
    choices: [
      Wrong(
        'Air',
        'A common guess! Tiny air bubbles come first, but not the big ones.',
      ),
      Wrong('Heat', 'Heat is energy, not matter, so it cannot fill a bubble.'),
      Right('Water that turned into a gas'),
    ],
    tryIt: 'Turn the stove up until the water boils.',
    experiment: stoveExperiment,
    outcome: 'The bubbles are water itself, as a gas called water vapor. Its particles got enough energy to fly apart.',
  ),
  explain: [
    ExplainerActivity(
      title: 'Changing state',
      steps: const [
        ExplainerStep(
          'When thermal energy is added or removed, matter can change state.',
        ),
        ExplainerStep('Melting: solid to liquid.'),
        ExplainerStep('Freezing: liquid to solid.'),
        ExplainerStep('Boiling or evaporating: liquid to gas.'),
        ExplainerStep('Condensing: gas to liquid.'),
        ExplainerStep(
          'It is still the same substance. Only the arrangement and motion of '
          'its particles changed.',
        ),
      ],
      scene: _changesScene,
    ),
  ],
  practise: const [
    SortActivity(
      prompt: 'Is thermal energy added or removed?',
      hint:
          'Changes toward faster particles (solid to liquid to gas) need '
          'energy added. Going the other way removes it.',
      bins: [_energyAdded, _energyRemoved],
      items: [
        SortItem(
          'Melting',
          bin: _energyAdded,
          why: 'Ice needs warmth to melt.',
        ),
        SortItem(
          'Freezing',
          bin: _energyRemoved,
          why: 'Water must cool down to freeze.',
        ),
        SortItem(
          'Boiling',
          bin: _energyAdded,
          why: 'A stove adds energy to boil water.',
        ),
        SortItem(
          'Condensing',
          bin: _energyRemoved,
          why: 'Vapor cools on a cold surface and turns to drops.',
        ),
        SortItem(
          'Evaporating',
          bin: _energyAdded,
          why: 'Sunshine adds energy to dry up a puddle.',
        ),
      ],
    ),
  ],
  check: [
    ChoiceQuestion(
      ordered: true,
      prompt:
          'A 20 g ice cube melts completely. What is the mass of the water?',
      choices: [
        Wrong('Less than 20 g', 'No particles escape, so no mass is lost.'),
        Right('20 g'),
        Wrong('More than 20 g', 'Nothing is added, so the mass cannot grow.'),
      ],
      hint: 'Are any particles added or lost when ice melts?',
      reason: Reason(
        choices: [
          Right('The same particles are still there'),
          Wrong(
            'Water is heavier than ice',
            'Ice and water are the same particles, so the same mass.',
          ),
          Wrong(
            'Melting adds heat, and heat has mass',
            'Heat is energy. It has no mass.',
          ),
        ],
      ),
      explanation:
          'Matter is not created or destroyed when it changes state. The '
          'same particles are still there, so the mass stays 20 g.',
    ),
    ChoiceQuestion(
      prompt:
          'Drops of water form on a cold glass on a hot day. Where do they '
          'come from?',
      choices: [
        Right('Water vapor in the air'),
        Wrong(
          'Water leaking through the glass',
          'Glass does not let water through. It forms on the outside.',
        ),
        Wrong(
          'The cold makes new water',
          'Cold cannot make new matter. The water was already there.',
        ),
      ],
      hint: 'Air has water in it as a gas. What does cold do to a gas?',
      reason: Reason(
        choices: [
          Right('The vapor cools down and condenses into liquid'),
          Wrong(
            'The cold glass sucks water in',
            'Glass cannot pull water in. The drops come from the air.',
          ),
          Wrong(
            'Ice inside melts through the glass',
            'The drops form even without ice, just from cold.',
          ),
        ],
      ),
      explanation:
          'Water vapor in the air touches the cold glass, loses energy, '
          'and condenses into liquid drops.',
    ),
    ChoiceQuestion(
      prompt: 'Which change needs thermal energy to be added?',
      choices: [
        Wrong(
          'Condensing',
          'Condensing removes energy: gas slows into liquid.',
        ),
        Wrong('Freezing', 'Freezing removes energy: liquid slows into solid.'),
        Right('Melting'),
      ],
      hint: 'Which change makes particles move faster?',
      explanation:
          'Particles must speed up to break out of a solid\'s fixed '
          'positions, so melting needs energy added.',
    ),
  ],
  debate: const WhoIsRightActivity(
    situation: 'Kai and Lily notice a puddle is gone on a sunny afternoon.',
    claims: [
      Claim(
        kai,
        Wrong(
          'The sun destroyed the water. It is gone forever.',
          'Matter is never destroyed when it changes state. The particles '
              'just moved into the air.',
        ),
      ),
      Claim(
        lily,
        Right(
          'The water evaporated. Its particles are in the air now, as a gas.',
        ),
      ),
    ],
    explanation:
        'Sunshine gave the water particles energy to escape as water vapor. '
        'They are still there, spread out in the air.',
  ),
);
