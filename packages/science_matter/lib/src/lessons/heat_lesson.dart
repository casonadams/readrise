import 'package:activity_kit/activity_kit.dart';
import 'package:readrise_plugin_api/readrise_plugin_api.dart';

import '../experiments/heat.dart';
import '../heat_lab_activity.dart';
import '../heat_scenes.dart';
import '../matter_state.dart';
import 'classmates.dart';

final _heatMotion = heatScene(const [
  HeatStage(20, 20),
  HeatStage(20, 90),
  HeatStage(90, -10),
  HeatStage(-10, 40),
]);

/// Temperature as particle speed. Targets "particles expand when heated".
final heatLesson = BasicLesson(
  id: LessonId('heat'),
  title: 'Heat',
  activities: <ActivityPlugin>[
    const ChoiceQuizActivity(
      kind: ActivityKind.warmUp,
      questions: [
        ChoiceQuestion(
          prompt: 'In which state do particles slide past each other?',
          options: ['Solid', 'Liquid', 'Gas'],
          answer: 1,
          hint: 'Which one can you pour?',
          feedback: {
            0: 'Solid particles are held in place. They only vibrate.',
            2: 'Gas particles fly far apart instead of sliding.',
          },
          explanation: 'Liquid particles touch but slide past each other.',
        ),
        ChoiceQuestion(
          prompt: 'What is between the particles of a gas?',
          options: ['Air', 'Empty space', 'Water'],
          answer: 1,
          hint: 'Remember the magnifier on the jar of air.',
          feedback: {
            0: 'The particles are the air, so there is no air between them.',
            2: 'Water would be particles too. Between them is nothing.',
          },
          explanation: 'Between gas particles there is only empty space.',
        ),
      ],
    ),
    const PredictActivity(
      question: 'You heat a sealed jar of gas. What happens to its particles?',
      options: [
        'They get bigger',
        'They move faster',
        'They get bigger and faster',
      ],
      answer: 1,
      tryIt: 'Drag the heat slider all the way up.',
      experiment: heatGasExperiment,
      outcome: 'Heat is energy. It makes particles move faster, but each one stays the same size.',
      reactions: {
        0: 'A very common idea, even for grown-ups!',
        2: 'You were right about faster!',
      },
    ),
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
    const HeatLabActivity(
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
    const ChoiceQuizActivity(
      questions: [
        ChoiceQuestion(
          prompt:
              'Steam is much hotter than ice. How do their particles compare?',
          options: [
            'Steam particles move faster',
            'Ice particles move faster',
            'They move at the same speed',
          ],
          answer: 0,
          hint: 'Higher temperature means what for particles?',
          feedback: {
            1: 'Ice is colder, so its particles move slower.',
            2: 'Temperature tells you speed, so they cannot match.',
          },
          reason: Reason(
            options: [
              'Temperature measures how fast particles move',
              'Steam particles are bigger',
              'Steam particles are lighter',
            ],
            answer: 0,
            feedback: {
              1:
                  'Particles never grow when heated. The same particles just '
                  'move faster.',
              2: 'Steam and ice are the same particles with the same mass.',
            },
          ),
          explanation:
              'Higher temperature means faster particles, so the steam '
              'particles move faster.',
        ),
        ChoiceQuestion(
          prompt: 'A balloon left in the hot sun gets bigger. Why?',
          options: [
            'The air particles move faster and push harder',
            'Each air particle gets bigger',
            'The sun adds more air',
          ],
          answer: 0,
          hint: 'What did heating do to the gas particles in the jar?',
          feedback: {
            1: 'Particles stay the same size when heated.',
            2: 'Sunlight is energy. It cannot add air particles.',
          },
          explanation:
              'Heat speeds up the air particles. They hit the balloon walls '
              'harder and more often, pushing it outward.',
        ),
        ChoiceQuestion(
          prompt: 'At what temperature does water freeze?',
          options: ['-10\u00B0C', '0\u00B0C', '32\u00B0C', '100\u00B0C'],
          answer: 1,
          hint: 'Look for the 0\u00B0 mark on the thermometer.',
          feedback: {
            0: 'Water is already ice at -10\u00B0C. It froze before that.',
            2: '32 is the freezing point in Fahrenheit, not Celsius.',
            3: '100\u00B0C is where water boils.',
          },
          explanation:
              'Water freezes at 0\u00B0C. (32 is the freezing point in '
              'Fahrenheit, a different scale.)',
        ),
      ],
    ),
    const WhoIsRightActivity(
      situation: 'Noah and Zoe watch a balloon grow bigger in the sun.',
      claims: [
        Claim(noah, 'The air particles got bigger in the heat.'),
        Claim(zoe, 'The air particles move faster and push the walls harder.'),
      ],
      answer: 1,
      feedback: {
        0: 'Particles never grow. Heating only makes them move faster.',
      },
      explanation:
          'Heat makes the same particles move faster. They push on the '
          'balloon harder, so it stretches bigger.',
    ),
  ],
);
