import 'package:activity_kit/activity_kit.dart';
import 'package:readrise_plugin_api/readrise_plugin_api.dart';
import 'package:science_kit/science_kit.dart';

import '../experiments/melt_or_dissolve.dart';
import '../scenes.dart';
import 'dissolving_lesson.dart';

const _melting = SortBin('Melting');
const _dissolving = SortBin('Dissolving');

/// Melting and dissolving side by side. Targets "dissolving is melting"
/// (Ebenezer & Erickson 1996).
final meltOrDissolveLesson = ScienceLesson(
  id: LessonId('melting-or-dissolving'),
  title: 'Melt or dissolve?',
  warmUp: WarmUp(
    recalls: [dissolvingLesson],
    questions: const [
      ChoiceQuestion(
        id: ItemId('melting-warm-where'),
        prompt: 'Where does sugar go when it dissolves?',
        choices: [
          Right('Between the water particles'),
          Wrong('It disappears', 'The water tastes sweet, so it is there.'),
          Wrong('Into the air', 'Dissolved sugar stays in the water.'),
        ],
        hint: 'Remember the sweet tea.',
        explanation: 'Dissolved sugar spreads out between water particles.',
      ),
      ChoiceQuestion(
        id: ItemId('melting-warm-solution'),
        prompt: 'Salt dissolved in water makes...',
        choices: [
          Wrong(
            'A new kind of water',
            'The water stays water and the salt stays salt.',
          ),
          Right('A solution'),
          Wrong('A solid', 'Salt water is a liquid you can pour.'),
        ],
        hint: 'What is a mixture with something dissolved in it called?',
        explanation: 'Salt dissolved in water is a solution.',
      ),
    ],
  ),
  predict: const PredictActivity(
    question:
        'An ice cube melts in a warm room. A sugar cube dissolves in water. '
        'Are these the same kind of change?',
    choices: [
      Wrong('Yes, both are melting', 'A very common idea, even for grown-ups!'),
      Wrong(
        'Yes, both just disappear',
        'A common idea, but neither one is really gone.',
      ),
      Right('No, they are different changes'),
    ],
    tryIt: 'Drag the slider to let time pass.',
    experiment: meltOrDissolveExperiment,
    outcome:
        'The ice became liquid but stayed only water. The sugar spread out '
        'between water particles, so two substances mixed.',
  ),
  explain: [
    ExplainerActivity(
      title: 'Melting or dissolving',
      steps: const [
        ExplainerStep('Both start solid: an ice cube and a sugar cube.'),
        ExplainerStep(
          'Melting: heat lets the particles of one substance slide past '
          'each other.',
        ),
        ExplainerStep(
          'Dissolving: the particles of one substance spread out between '
          'the particles of a liquid.',
        ),
        ExplainerStep('Melting needs heat. Dissolving needs a liquid.'),
      ],
      scene: meltOrDissolveScene,
    ),
  ],
  practise: const [
    SortActivity(
      prompt: 'Melting or dissolving?',
      hint: 'Melting needs heat; dissolving needs a liquid to mix into.',
      bins: [_melting, _dissolving],
      items: [
        SortItem(
          'Ice cream on a hot day',
          bin: _melting,
          why: 'Heat turns the ice cream itself into a liquid.',
        ),
        SortItem(
          'Salt stirred into soup',
          bin: _dissolving,
          why: 'The salt particles spread out in the soup.',
        ),
        SortItem(
          'Butter in a hot pan',
          bin: _melting,
          why: 'Heat turns the butter liquid, and nothing mixes in.',
        ),
        SortItem(
          'Drink powder in water',
          bin: _dissolving,
          why: 'Its particles spread out between the water particles.',
        ),
        SortItem(
          'Chocolate in a warm hand',
          bin: _melting,
          why: 'The warmth of your hand turns the chocolate liquid.',
        ),
        SortItem(
          'Sugar in cold lemonade',
          bin: _dissolving,
          why: 'No heat is needed: the sugar spreads into the lemonade.',
        ),
      ],
    ),
  ],
  check: const [
    ChoiceQuestion(
      id: ItemId('melting-sugar-tea'),
      prompt: 'Sugar vanishes in hot tea. Is it melting?',
      choices: [
        Wrong('Yes, the tea is hot', 'Tea is far too cool to melt sugar.'),
        Wrong('Yes, it disappears', 'Melted things do not disappear.'),
        Right('No, it is dissolving'),
      ],
      hint: 'Did the sugar become liquid sugar, or mix into the water?',
      reason: Reason(
        choices: [
          Right('Its particles spread out between the water particles'),
          Wrong(
            'Tea is hotter than the melting point of sugar',
            'Sugar melts at about 186\u00B0C, much hotter than any tea.',
          ),
          Wrong(
            'Hot drinks melt whatever is put in them',
            'A spoon in hot tea does not melt.',
          ),
        ],
      ),
      explanation:
          'The sugar dissolves: its particles spread out between the water '
          'particles. It would melt only at about 186\u00B0C.',
    ),
    ChoiceQuestion(
      id: ItemId('melting-needs'),
      prompt: 'What does melting always need?',
      choices: [
        Wrong('Water', 'Butter melts in a pan with no water at all.'),
        Right('Heat'),
        Wrong('Stirring', 'Stirring helps things dissolve, not melt.'),
      ],
      hint: 'Think about ice cream on a hot day.',
      explanation:
          'Melting needs heat, which lets a substance\'s particles slide past '
          'each other.',
    ),
    ChoiceQuestion(
      id: ItemId('melting-ice-substances'),
      prompt: 'An ice cube melts. What is in the puddle?',
      choices: [
        Right('Only water'),
        Wrong(
          'Water and ice, two substances',
          'Ice is just water with its particles held in place.',
        ),
        Wrong('Water and air', 'Melting does not add any air.'),
      ],
      hint: 'What is ice made of?',
      explanation:
          'Ice and liquid water are the same substance. Melting only changes '
          'how the particles are arranged.',
    ),
  ],
  debate: const WhoIsRightActivity(
    situation: 'Lily and Noah watch a sugar cube vanish in cold water.',
    claims: [
      Claim(
        noah,
        Wrong(
          'It melted, just like an ice cube does.',
          'Cold water cannot melt sugar; the sugar dissolved instead.',
        ),
      ),
      Claim(
        lily,
        Right('It dissolved. Its particles spread out in the water.'),
      ),
    ],
    explanation:
        'Melting needs heat and only one substance. The sugar mixed into the '
        'water without any heat, so it dissolved.',
  ),
);
