import 'package:activity_kit/activity_kit.dart';
import 'package:readrise_plugin_api/readrise_plugin_api.dart';
import 'package:flutter/widgets.dart';

import '../matter_state.dart';
import '../particle_view.dart';
import '../states_scenes.dart';
import '../experiments/zoom.dart';
import 'classmates.dart';

WidgetBuilder _particles(MatterState state, double energy) =>
    (_) => ParticleView(state: state, energy: energy);

/// Solid, liquid, gas as particle arrangements. Targets "air fills the gaps
/// between particles" and "particles are hard or cold like the whole".
final statesLesson = BasicLesson(
  id: LessonId('states'),
  title: 'States',
  activities: <ActivityPlugin>[
    const ChoiceQuizActivity(
      kind: ActivityKind.warmUp,
      questions: [
        ChoiceQuestion(
          prompt: 'Which of these is matter?',
          options: ['Sound', 'Air', 'Light'],
          answer: 1,
          hint: 'Which one tipped the scale?',
          feedback: {
            0: 'Sound is energy moving through matter.',
            2: 'Light is energy. It has no mass.',
          },
          explanation: 'Air has mass and takes up space, so it is matter.',
        ),
        ChoiceQuestion(
          prompt: 'What is all matter made of?',
          options: ['Tiny particles called atoms', 'Energy', 'Water'],
          answer: 0,
          hint: 'Think of the H and O balls.',
          feedback: {
            1: 'Energy is not matter, so matter cannot be made of it.',
            2: 'Water is one kind of matter, made of atoms like everything.',
          },
          explanation: 'All matter is made of tiny particles called atoms.',
        ),
      ],
    ),
    const PredictActivity(
      question:
          'Imagine zooming into a jar of air until you see its particles. What '
          'is between the particles?',
      options: ['More air', 'Nothing at all, just empty space', 'Water'],
      answer: 1,
      tryIt: 'Drag the slider all the way to zoom in.',
      experiment: zoomExperiment,
      outcome: 'The particles are the air. Between them is nothing at all, just empty space.',
      reactions: {
        0: 'Most people guess this, even grown-ups!',
        2: 'Any water in air is particles too, not what fills the gaps.',
      },
    ),
    const ExplainerActivity(
      title: 'Solid, liquid, gas',
      steps: [
        ExplainerStep(
          'The matter around you is usually a solid, a liquid, or a gas.',
        ),
        ExplainerStep(
          'In a solid, particles are packed tight and vibrate in place. A '
          'solid keeps its own shape and volume.',
        ),
        ExplainerStep(
          'In a liquid, particles touch but slide past each other. It keeps '
          'its volume but takes the shape of its container.',
        ),
        ExplainerStep(
          'In a gas, particles fly far apart with empty space between them. '
          'A gas spreads out to fill its whole container.',
        ),
        ExplainerStep(
          'The particles are the same kind in all three. Only how they are '
          'arranged and how they move changes.',
        ),
      ],
      scene: statesScene,
    ),
    const SortActivity(
      prompt: 'Which state is it at room temperature?',
      hint:
          'Does it keep its own shape (solid), pour (liquid), or spread out '
          'to fill a space (gas)?',
      bins: ['Solid', 'Liquid', 'Gas'],
      items: [
        SortItem('Ice cube', bin: 0, why: 'Ice keeps its own shape.'),
        SortItem(
          'Orange juice',
          bin: 1,
          why: 'Juice takes the shape of its glass.',
        ),
        SortItem(
          'Helium',
          bin: 2,
          why: 'Helium spreads out to fill a balloon.',
        ),
        SortItem(
          'Wooden block',
          bin: 0,
          why: 'A block keeps its shape on its own.',
        ),
        SortItem(
          'Milk',
          bin: 1,
          why: 'Milk pours and takes the shape of its jug.',
        ),
        SortItem(
          'Oxygen',
          bin: 2,
          why: 'Oxygen is a gas in the air around you.',
        ),
        SortItem(
          'Gold ring',
          bin: 0,
          why: 'Gold is a solid metal at room temperature.',
        ),
      ],
    ),
    ChoiceQuizActivity(
      questions: [
        ChoiceQuestion(
          prompt: 'Which state of matter is this?',
          options: const ['Solid', 'Liquid', 'Gas'],
          answer: 2,
          visual: _particles(MatterState.gas, 0.7),
          hint: 'Are the particles packed, touching, or far apart?',
          feedback: const {
            0: 'Solid particles sit packed in rows. These fly around.',
            1: 'Liquid particles touch each other. These are far apart.',
          },
          reason: const Reason(
            options: [
              'The particles are far apart and fly around',
              'The particles are hot',
              'The particles are tiny',
            ],
            answer: 0,
            feedback: {
              1:
                  'Gases can be cold, like the air in winter. Look at how the '
                  'particles are spread out.',
              2: 'Particles are tiny in every state.',
            },
          ),
          explanation:
              'The particles are far apart and moving fast in every direction. '
              'That is a gas.',
        ),
        ChoiceQuestion(
          prompt: 'Which state of matter is this?',
          options: const ['Solid', 'Liquid', 'Gas'],
          answer: 0,
          visual: _particles(MatterState.solid, 0.3),
          hint: 'Do the particles move around, or stay in their spots?',
          feedback: const {
            1: 'Liquid particles slide past each other. These stay in rows.',
            2: 'Gas particles fly apart. These are packed together.',
          },
          reason: const Reason(
            options: [
              'The particles are packed and vibrate in place',
              'The particles do not move at all',
              'The particles are hard',
            ],
            answer: 0,
            feedback: {
              1:
                  'Look closely: solid particles still wiggle. They vibrate in '
                  'place.',
              2:
                  'One particle is not hard or soft. A solid is hard because '
                  'its particles are held tightly together.',
            },
          ),
          explanation:
              'The particles are packed in fixed positions and only vibrate. '
              'That is a solid.',
        ),
        const ChoiceQuestion(
          prompt: 'Why can you pour juice but not a wooden block?',
          options: [
            'Juice particles slide past each other',
            'Juice particles are smaller',
            'Wood particles are glued with air',
          ],
          answer: 0,
          hint: 'Think about how liquid particles move.',
          feedback: {
            1: 'Size is not the reason. It is how the particles move.',
            2: 'There is no air between particles, only empty space.',
          },
          explanation:
              'In a liquid, particles slide past each other, so it flows. In a '
              'solid, they are held in place.',
        ),
      ],
    ),
    const WhoIsRightActivity(
      situation: 'Ava and Sam are talking about an ice cube.',
      claims: [
        Claim(ava, 'Ice is hard because each ice particle is cold and hard.'),
        Claim(
          sam,
          'Ice particles are the same as water particles. They are just '
          'packed tight and held in place.',
        ),
      ],
      answer: 1,
      feedback: {
        0:
            'A single particle is not hard or cold. Ice is hard because of how '
            'its particles are arranged.',
      },
      explanation:
          'Ice, water, and steam are made of the same particles. Ice is hard '
          'because its particles are packed and held in place.',
    ),
  ],
);
