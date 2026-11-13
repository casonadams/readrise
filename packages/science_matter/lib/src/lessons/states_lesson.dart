import 'package:activity_kit/activity_kit.dart';
import 'package:readrise_plugin_api/readrise_plugin_api.dart';
import 'package:flutter/widgets.dart';

import '../matter_state.dart';
import '../particle_view.dart';
import '../states_scenes.dart';
import '../experiments/zoom.dart';
import 'classmates.dart';
import 'science_lesson.dart';

WidgetBuilder _particles(MatterState state, double energy) =>
    (_) => ParticleView(state: state, energy: energy);

const _solid = SortBin('Solid');
const _liquid = SortBin('Liquid');
const _gas = SortBin('Gas');

/// Solid, liquid, gas as particle arrangements. Targets "air fills the gaps
/// between particles" and "particles are hard or cold like the whole".
final statesLesson = ScienceLesson(
  id: LessonId('states'),
  title: 'States',
  warmUp: WarmUp(
    recalls: [LessonId('matter')],
    questions: [
      ChoiceQuestion(
        id: ItemId('states-warm-matter'),
        prompt: 'Which of these is matter?',
        choices: [
          Wrong('Sound', 'Sound is energy moving through matter.'),
          Right('Air'),
          Wrong('Light', 'Light is energy. It has no mass.'),
        ],
        hint: 'Which one tipped the scale?',
        explanation: 'Air has mass and takes up space, so it is matter.',
      ),
      ChoiceQuestion(
        id: ItemId('states-warm-made-of'),
        prompt: 'What is all matter made of?',
        choices: [
          Right('Tiny particles called atoms'),
          Wrong(
            'Energy',
            'Energy is not matter, so matter cannot be made of it.',
          ),
          Wrong(
            'Water',
            'Water is one kind of matter, made of atoms like everything.',
          ),
        ],
        hint: 'Think of the H and O balls.',
        explanation: 'All matter is made of tiny particles called atoms.',
      ),
    ],
  ),
  predict: const PredictActivity(
    question:
        'Imagine zooming into a jar of air until you see its particles. What '
        'is between the particles?',
    choices: [
      Wrong('More air', 'Most people guess this, even grown-ups!'),
      Right('Nothing at all, just empty space'),
      Wrong(
        'Water',
        'Any water in air is particles too, not what fills the gaps.',
      ),
    ],
    tryIt: 'Drag the slider all the way to zoom in.',
    experiment: zoomExperiment,
    outcome: 'The particles are the air. Between them is nothing at all, just empty space.',
  ),
  explain: const [
    ExplainerActivity(
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
  ],
  practise: const [
    SortActivity(
      prompt: 'Which state is it at room temperature?',
      hint:
          'Does it keep its own shape (solid), pour (liquid), or spread out '
          'to fill a space (gas)?',
      bins: [_solid, _liquid, _gas],
      items: [
        SortItem('Ice cube', bin: _solid, why: 'Ice keeps its own shape.'),
        SortItem(
          'Orange juice',
          bin: _liquid,
          why: 'Juice takes the shape of its glass.',
        ),
        SortItem(
          'Helium',
          bin: _gas,
          why: 'Helium spreads out to fill a balloon.',
        ),
        SortItem(
          'Wooden block',
          bin: _solid,
          why: 'A block keeps its shape on its own.',
        ),
        SortItem(
          'Milk',
          bin: _liquid,
          why: 'Milk pours and takes the shape of its jug.',
        ),
        SortItem(
          'Oxygen',
          bin: _gas,
          why: 'Oxygen is a gas in the air around you.',
        ),
        SortItem(
          'Gold ring',
          bin: _solid,
          why: 'Gold is a solid metal at room temperature.',
        ),
      ],
    ),
  ],
  check: [
    ChoiceQuestion(
      id: ItemId('states-picture-gas'),
      ordered: true,
      prompt: 'Which state of matter is this?',
      choices: [
        Wrong('Solid', 'Solid particles sit packed in rows. These fly around.'),
        Wrong(
          'Liquid',
          'Liquid particles touch each other. These are far apart.',
        ),
        Right('Gas'),
      ],
      visual: _particles(MatterState.gas, 0.7),
      hint: 'Are the particles packed, touching, or far apart?',
      reason: const Reason(
        choices: [
          Right('The particles are far apart and fly around'),
          Wrong(
            'The particles are hot',
            'Gases can be cold, like the air in winter. Look at how the '
                'particles are spread out.',
          ),
          Wrong('The particles are tiny', 'Particles are tiny in every state.'),
        ],
      ),
      explanation:
          'The particles are far apart and moving fast in every direction. '
          'That is a gas.',
    ),
    ChoiceQuestion(
      id: ItemId('states-picture-solid'),
      ordered: true,
      prompt: 'Which state of matter is this?',
      choices: [
        Right('Solid'),
        Wrong(
          'Liquid',
          'Liquid particles slide past each other. These stay in rows.',
        ),
        Wrong('Gas', 'Gas particles fly apart. These are packed together.'),
      ],
      visual: _particles(MatterState.solid, 0.3),
      hint: 'Do the particles move around, or stay in their spots?',
      reason: const Reason(
        choices: [
          Right('The particles are packed and vibrate in place'),
          Wrong(
            'The particles do not move at all',
            'Look closely: solid particles still wiggle. They vibrate in '
                'place.',
          ),
          Wrong(
            'The particles are hard',
            'One particle is not hard or soft. A solid is hard because '
                'its particles are held tightly together.',
          ),
        ],
      ),
      explanation:
          'The particles are packed in fixed positions and only vibrate. '
          'That is a solid.',
    ),
    ChoiceQuestion(
      id: ItemId('states-pour'),
      prompt: 'Why can you pour juice but not a wooden block?',
      choices: [
        Right('Juice particles slide past each other'),
        Wrong(
          'Juice particles are smaller',
          'Size is not the reason. It is how the particles move.',
        ),
        Wrong(
          'Wood particles are glued with air',
          'There is no air between particles, only empty space.',
        ),
      ],
      hint: 'Think about how liquid particles move.',
      explanation:
          'In a liquid, particles slide past each other, so it flows. In a '
          'solid, they are held in place.',
    ),
  ],
  debate: const WhoIsRightActivity(
    situation: 'Ava and Sam are talking about an ice cube.',
    claims: [
      Claim(
        ava,
        Wrong(
          'Ice is hard because each ice particle is cold and hard.',
          'A single particle is not hard or cold. Ice is hard because of how '
              'its particles are arranged.',
        ),
      ),
      Claim(
        sam,
        Right(
          'Ice particles are the same as water particles. They are just '
          'packed tight and held in place.',
        ),
      ),
    ],
    explanation:
        'Ice, water, and steam are made of the same particles. Ice is hard '
        'because its particles are packed and held in place.',
  ),
);
