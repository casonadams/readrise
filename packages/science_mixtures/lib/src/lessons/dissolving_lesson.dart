import 'package:activity_kit/activity_kit.dart';
import 'package:readrise_plugin_api/readrise_plugin_api.dart';
import 'package:science_kit/science_kit.dart';

import '../experiments/stir.dart';
import '../scenes.dart';

const _dissolves = SortBin('Dissolves');
const _doesNot = SortBin('Does not dissolve');

/// Dissolving at particle size. Targets "sugar disappears" and "sugar
/// melts in water" (Longden, Black & Solomon 1991,
/// https://doi.org/10.1080/0950069910130106; Ebenezer & Erickson 1996) and,
/// in the debate, "dissolved sugar sinks to the bottom" (Prieto, Blanco &
/// Rodriguez 1989).
final dissolvingLesson = ScienceLesson(
  id: LessonId('dissolving'),
  title: 'Dissolving',
  predict: const PredictActivity(
    question:
        'You stir a sugar cube into a glass of water until you cannot see '
        'it. Where is the sugar now?',
    choices: [
      Wrong('It is gone', 'Many people think so, even grown-ups!'),
      Wrong(
        'It melted into the water',
        'A common idea, but nothing here got hot.',
      ),
      Right('Spread out between the water particles'),
    ],
    tryIt: 'Drag the slider to stir.',
    experiment: dissolvingExperiment,
    outcome:
        'The sugar particles spread out between the water particles. You '
        'cannot see them, but all of them are still there.',
  ),
  explain: [
    ExplainerActivity(
      title: 'Dissolving',
      steps: const [
        ExplainerStep(
          'A sugar cube is made of tiny sugar particles packed together.',
        ),
        ExplainerStep(
          'Water particles bump into the cube and knock sugar particles '
          'loose.',
        ),
        ExplainerStep(
          'The loose sugar particles spread out between the water particles. '
          'This is called dissolving.',
        ),
        ExplainerStep(
          'Water with something dissolved in it is called a solution.',
        ),
      ],
      scene: dissolvingScene,
    ),
  ],
  practise: const [
    SortActivity(
      prompt: 'Does it dissolve in water?',
      hint: 'If it spreads out until you cannot see any bits, it dissolved.',
      bins: [_dissolves, _doesNot],
      items: [
        SortItem(
          'Sugar',
          bin: _dissolves,
          why: 'Its particles spread out between the water particles.',
        ),
        SortItem(
          'Sand',
          bin: _doesNot,
          why: 'Sand sinks and stays sand at the bottom.',
        ),
        SortItem(
          'Salt',
          bin: _dissolves,
          why: 'You cannot see it, but the water tastes salty.',
        ),
        SortItem(
          'Cooking oil',
          bin: _doesNot,
          why: 'Oil floats on top in its own layer.',
        ),
        SortItem(
          'Drink powder',
          bin: _dissolves,
          why: 'It flavours all of the water evenly.',
        ),
        SortItem(
          'Pepper',
          bin: _doesNot,
          why: 'You can still see the pepper bits in the water.',
        ),
      ],
    ),
  ],
  check: const [
    ChoiceQuestion(
      id: ItemId('dissolving-where'),
      prompt: 'You cannot see dissolved sugar. Where is it?',
      choices: [
        Wrong('Gone', 'The water tastes sweet, so the sugar is still there.'),
        Right('Spread out between the water particles'),
        Wrong('Melted', 'Melting needs heat, and the water was not heated.'),
      ],
      hint: 'How could the water taste sweet?',
      reason: Reason(
        choices: [
          Wrong(
            'Sugar particles break into nothing',
            'Particles never break into nothing; they only move apart.',
          ),
          Right('Every sugar particle is still in the water'),
          Wrong(
            'The water hides the sugar at the bottom',
            'Dissolved sugar spreads through all of the water.',
          ),
        ],
      ),
      explanation:
          'The sugar particles spread out between the water particles. The '
          'sweet taste shows they are still there.',
    ),
    ChoiceQuestion(
      id: ItemId('dissolving-solution'),
      prompt: 'What is water with sugar dissolved in it called?',
      choices: [
        Right('A solution'),
        Wrong('A solid', 'Sugar water is a liquid you can pour.'),
        Wrong('Pure water', 'Pure water has only water particles in it.'),
      ],
      hint: 'It is a mixture where you cannot see the parts.',
      explanation:
          'A solution is a mixture where one substance has dissolved in '
          'another.',
    ),
    ChoiceQuestion(
      id: ItemId('dissolving-see'),
      prompt: 'Why can you not see dissolved sugar?',
      choices: [
        Wrong('It turned into water', 'Sugar particles always stay sugar.'),
        Right('Its particles are far too small to see'),
        Wrong(
          'It floated up into the air',
          'Dissolved sugar stays in the water.',
        ),
      ],
      hint: 'Think about how small particles are.',
      explanation:
          'Each sugar particle is far too small to see. Only the cube, with '
          'millions packed together, was big enough.',
    ),
  ],
  debate: const WhoIsRightActivity(
    situation: 'Ava and Kai sip sweet tea. They cannot see any sugar in it.',
    claims: [
      Claim(
        kai,
        Wrong(
          'The sugar sank to the bottom where we cannot see it.',
          'Dissolved sugar spreads through all of the tea, so every sip is '
              'sweet.',
        ),
      ),
      Claim(
        ava,
        Right('The sugar spread out between the water particles in the tea.'),
      ),
    ],
    explanation:
        'Dissolved sugar spreads evenly through the whole drink. That is why '
        'the first sip and the last sip taste just as sweet.',
  ),
);
