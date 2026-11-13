import 'package:activity_kit/activity_kit.dart';
import 'package:readrise_plugin_api/readrise_plugin_api.dart';

import '../evaporation_scene.dart';
import '../experiments/evaporation.dart';
import 'changes_lesson.dart';
import 'classmates.dart';
import 'heat_lesson.dart';
import 'science_lesson.dart';

const _faster = SortBin('Dries faster');
const _slower = SortBin('Dries slower');

/// Evaporation below the boiling point. Targets "water only turns into a gas
/// when it boils or the sun heats it" (Bar & Galili 1994,
/// https://doi.org/10.1080/0950069940160205).
final evaporationLesson = ScienceLesson(
  id: LessonId('evaporation'),
  title: 'Evaporation',
  warmUp: WarmUp(
    recalls: [heatLesson, changesLesson],
    questions: const [
      ChoiceQuestion(
        id: ItemId('evaporation-warm-bubbles'),
        prompt: 'What are the big bubbles in boiling water made of?',
        choices: [
          Right('Water vapor'),
          Wrong('Air', 'The big bubbles are water itself, as a gas.'),
          Wrong('Heat', 'Heat is energy. It cannot fill a bubble.'),
        ],
        hint: 'Remember the pot on the stove.',
        explanation: 'The bubbles are water vapor: water as a gas.',
      ),
      ChoiceQuestion(
        id: ItemId('evaporation-warm-heating'),
        prompt: 'What does heating do to particles?',
        choices: [
          Wrong('Makes them bigger', 'Particles stay the same size.'),
          Right('Makes them move faster'),
          Wrong('Makes them disappear', 'Heat never makes matter disappear.'),
        ],
        hint: 'Remember the jar over the flame.',
        explanation: 'Heat speeds particles up. Their size stays the same.',
      ),
    ],
  ),
  predict: const PredictActivity(
    question:
        'A glass of water sits in a cool room for a week. It never boils. '
        'What happens to the water?',
    choices: [
      Wrong(
        'Nothing. Water must boil to turn into a gas.',
        'A very common idea, even for grown-ups!',
      ),
      Wrong('It soaks into the glass', 'Glass cannot soak up water.'),
      Right('Some of it goes into the air'),
    ],
    tryIt: 'Drag the slider to let a week go by.',
    experiment: evaporationExperiment,
    outcome:
        'Some particles left the surface as water vapor, without boiling. '
        'Every particle is still there.',
  ),
  explain: [
    ExplainerActivity(
      title: 'Evaporation',
      steps: const [
        ExplainerStep(
          'Water particles move at many different speeds, even in a cool '
          'room.',
        ),
        ExplainerStep(
          'Now and then, a fast particle at the surface breaks free into the '
          'air.',
        ),
        ExplainerStep(
          'This is evaporation: a liquid slowly turning into a gas, without '
          'boiling.',
        ),
        ExplainerStep('Warmth, wind and a wide surface make it faster.'),
      ],
      scene: evaporationScene,
    ),
  ],
  practise: const [
    SortActivity(
      prompt: 'Which dries faster?',
      hint: 'Warmth, wind and a wide surface help fast particles escape.',
      bins: [_faster, _slower],
      items: [
        SortItem(
          'A puddle in the sun',
          bin: _faster,
          why: 'Sunshine warms it, so more particles are fast enough.',
        ),
        SortItem(
          'A puddle in the shade',
          bin: _slower,
          why: 'It still dries, but cooler particles escape less often.',
        ),
        SortItem(
          'Wet hair under a hair dryer',
          bin: _faster,
          why: 'Warm, moving air helps particles escape and carries them off.',
        ),
        SortItem(
          'A towel folded in a pile',
          bin: _slower,
          why: 'Folded, few water particles are at the surface.',
        ),
        SortItem(
          'A towel spread on a line',
          bin: _faster,
          why: 'Spread out, many particles are at the surface.',
        ),
        SortItem(
          'A glass of water with a lid',
          bin: _slower,
          why: 'The lid keeps the vapor in, so little water leaves.',
        ),
      ],
    ),
  ],
  check: const [
    ChoiceQuestion(
      id: ItemId('evaporation-boil'),
      prompt: 'Does water have to boil to evaporate?',
      choices: [
        Wrong(
          'Yes, it must reach 100\u00B0C',
          'Puddles dry on days far colder than 100\u00B0C.',
        ),
        Right('No, it evaporates at any temperature'),
        Wrong(
          'Only when the sun shines on it',
          'Puddles dry in the shade and at night too, just more slowly.',
        ),
      ],
      hint: 'Think about the glass in the cool room.',
      reason: Reason(
        choices: [
          Wrong(
            'Cold water particles are lighter',
            'Cold and warm water particles have the same mass.',
          ),
          Wrong(
            'The air pulls the water up',
            'Air does not pull. Fast particles break free on their own.',
          ),
          Right('Some particles are always fast enough to escape'),
        ],
      ),
      explanation:
          'At any temperature, some particles move fast enough to break '
          'free. Boiling is just very fast evaporation.',
    ),
    ChoiceQuestion(
      id: ItemId('evaporation-which-leave'),
      prompt: 'Which particles leave the water first?',
      choices: [
        Right('Fast ones at the surface'),
        Wrong(
          'Slow ones at the bottom',
          'Slow particles cannot break free, and the rest hold in the '
              'bottom ones.',
        ),
        Wrong(
          'All of them at once',
          'Only the fastest at the top escape, so water dries a little at a '
              'time.',
        ),
      ],
      hint: 'Which particles touch the air and have the most energy?',
      explanation:
          'Only particles at the surface that move fast enough break free '
          'into the air.',
    ),
    ChoiceQuestion(
      id: ItemId('evaporation-towel'),
      prompt: 'Which wet towel dries fastest?',
      choices: [
        Wrong('Folded in a pile', 'Folded, few particles are at the surface.'),
        Wrong(
          'Spread out in a cold room',
          'It dries, but cold particles are slower, so fewer escape.',
        ),
        Right('Spread out in a warm wind'),
      ],
      hint: 'Warmth, wind and a wide surface all help.',
      explanation:
          'Warmth makes more particles fast, spreading puts more at the '
          'surface, and wind carries the vapor away.',
    ),
  ],
  debate: const WhoIsRightActivity(
    situation: 'Zoe and Noah hang wet laundry outside on a cold, cloudy day.',
    claims: [
      Claim(zoe, Right('It will dry, just more slowly than on a sunny day.')),
      Claim(
        noah,
        Wrong(
          'It cannot dry. Water needs the sun to evaporate.',
          'Water evaporates at any temperature. The sun only makes it faster.',
        ),
      ),
    ],
    explanation:
        'Even on a cold day, some water particles are fast enough to escape. '
        'Fewer escape than on a warm day, so it takes longer.',
  ),
);
