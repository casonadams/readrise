import 'package:activity_kit/activity_kit.dart';
import 'package:readrise_plugin_api/readrise_plugin_api.dart';
import 'package:science_kit/science_kit.dart';

import '../experiments/heat.dart';
import '../heat_lab_activity.dart';
import '../heat_scenes.dart';
import 'classmates.dart';
import 'states_lesson.dart';
import 'science_lesson.dart';

final _heatMotion = heatScene(const [
  HeatStage(20, 20),
  HeatStage(20, 90),
  HeatStage(90, -10),
  HeatStage(-10, 40),
]);

/// Temperature as particle speed. Targets "particles expand when heated".
final heatLesson = ScienceLesson(
  id: LessonId('heat'),
  title: 'Heat',
  warmUp: WarmUp(
    recalls: [statesLesson],
    questions: const [
      ChoiceQuestion(
        id: ItemId('heat-warm-slide'),
        ordered: true,
        prompt: 'In which state do particles slide past each other?',
        choices: [
          Wrong(
            'Solid',
            'Solid particles are held in place. They only vibrate.',
          ),
          Right('Liquid'),
          Wrong('Gas', 'Gas particles fly far apart instead of sliding.'),
        ],
        hint: 'Which one can you pour?',
        explanation: 'Liquid particles touch but slide past each other.',
      ),
      ChoiceQuestion(
        id: ItemId('heat-warm-between'),
        prompt: 'What is between the particles of a gas?',
        choices: [
          Wrong(
            'Air',
            'The particles are the air, so there is no air between them.',
          ),
          Right('Empty space'),
          Wrong(
            'Water',
            'Water would be particles too. Between them is nothing.',
          ),
        ],
        hint: 'Remember the magnifier on the jar of air.',
        explanation: 'Between gas particles there is only empty space.',
      ),
    ],
  ),
  predict: const PredictActivity(
    question: 'You heat a sealed jar of gas. What happens to its particles?',
    choices: [
      Wrong('They get bigger', 'A very common idea, even for grown-ups!'),
      Right('They move faster'),
      Wrong('They get bigger and faster', 'You were right about faster!'),
    ],
    tryIt: 'Drag the heat slider all the way up.',
    experiment: heatGasExperiment,
    outcome: 'Heat is energy. It makes particles move faster, but each one stays the same size.',
  ),
  explain: [
    ExplainerActivity(
      title: 'Heat and motion',
      steps: const [
        ExplainerStep(
          'Temperature tells you how fast the particles in something are '
          'moving, on average.',
        ),
        ExplainerStep('Add thermal energy and the particles move faster.'),
        ExplainerStep('Take it away and they slow down.'),
        ExplainerStep('Next, use the slider to melt, boil, and freeze water.'),
      ],
      scene: _heatMotion,
    ),
  ],
  practise: const [
    HeatLabActivity(
      goals: [
        HeatGoal(
          prompt: 'Heat the ice until it melts into a liquid.',
          target: MatterState.liquid,
        ),
        HeatGoal(
          prompt: 'Keep heating until the water boils into a gas.',
          target: MatterState.gas,
        ),
        HeatGoal(
          prompt: 'Now cool it all the way down until it freezes.',
          target: MatterState.solid,
        ),
      ],
    ),
  ],
  check: const [
    ChoiceQuestion(
      id: ItemId('heat-steam-ice'),
      prompt: 'Steam is much hotter than ice. How do their particles compare?',
      choices: [
        Right('Steam particles move faster'),
        Wrong(
          'Ice particles move faster',
          'Ice is colder, so its particles move slower.',
        ),
        Wrong(
          'They move at the same speed',
          'Temperature tells you speed, so they cannot match.',
        ),
      ],
      hint: 'Higher temperature means what for particles?',
      reason: Reason(
        choices: [
          Right('Temperature measures how fast particles move'),
          Wrong(
            'Steam particles are bigger',
            'Particles never grow when heated. The same particles just '
                'move faster.',
          ),
          Wrong(
            'Steam particles are lighter',
            'Steam and ice are the same particles with the same mass.',
          ),
        ],
      ),
      explanation:
          'Higher temperature means faster particles, so the steam '
          'particles move faster.',
    ),
    ChoiceQuestion(
      id: ItemId('heat-balloon-sun'),
      prompt: 'A balloon left in the hot sun gets bigger. Why?',
      choices: [
        Right('The air particles move faster and push harder'),
        Wrong(
          'Each air particle gets bigger',
          'Particles stay the same size when heated.',
        ),
        Wrong(
          'The sun adds more air',
          'Sunlight is energy. It cannot add air particles.',
        ),
      ],
      hint: 'What did heating do to the gas particles in the jar?',
      explanation:
          'Heat speeds up the air particles. They hit the balloon walls '
          'harder and more often, pushing it outward.',
    ),
    ChoiceQuestion(
      id: ItemId('heat-freezing-point'),
      ordered: true,
      prompt: 'At what temperature does water freeze?',
      choices: [
        Wrong(
          '-10\u00B0C',
          'Water is already ice at -10\u00B0C. It froze before that.',
        ),
        Right('0\u00B0C'),
        Wrong(
          '32\u00B0C',
          '32 is the freezing point in Fahrenheit, not Celsius.',
        ),
        Wrong('100\u00B0C', '100\u00B0C is where water boils.'),
      ],
      hint: 'Look for the 0\u00B0 mark on the thermometer.',
      explanation:
          'Water freezes at 0\u00B0C. (32 is the freezing point in '
          'Fahrenheit, a different scale.)',
    ),
  ],
  debate: const WhoIsRightActivity(
    situation: 'Noah and Zoe watch a balloon grow bigger in the sun.',
    claims: [
      Claim(
        noah,
        Wrong(
          'The air particles got bigger in the heat.',
          'Particles never grow. Heating only makes them move faster.',
        ),
      ),
      Claim(
        zoe,
        Right('The air particles move faster and push the walls harder.'),
      ),
    ],
    explanation:
        'Heat makes the same particles move faster. They push on the '
        'balloon harder, so it stretches bigger.',
  ),
);
