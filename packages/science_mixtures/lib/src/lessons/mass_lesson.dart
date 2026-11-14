import 'package:activity_kit/activity_kit.dart';
import 'package:readrise_plugin_api/readrise_plugin_api.dart';
import 'package:science_kit/science_kit.dart';

import '../experiments/stir.dart';
import '../scenes.dart';
import 'dissolving_lesson.dart';
import 'melt_or_dissolve_lesson.dart';

const _same = SortBin('Stays the same');
const _changes = SortBin('Changes');

/// Mass is conserved when dissolving (NGSS 5-PS1-2). Targets "dissolved
/// sugar weighs less or nothing" (RSC, Chemical misconceptions II: Mass and
/// dissolving, https://edu.rsc.org/solutions/mass-and-dissolving-chemical-misconceptions-ii-11-14-years/1084.article).
final massLesson = ScienceLesson(
  id: LessonId('mass'),
  title: 'Mass',
  warmUp: WarmUp(
    recalls: [dissolvingLesson, meltOrDissolveLesson],
    questions: const [
      ChoiceQuestion(
        id: ItemId('mass-warm-ice-cream'),
        prompt: 'Ice cream turns runny on a hot day. What is happening?',
        choices: [
          Right('Melting'),
          Wrong('Dissolving', 'Nothing mixes into the ice cream.'),
          Wrong('Neither', 'A solid turning liquid in the heat is melting.'),
        ],
        hint: 'Did heat do it, or did something mix in?',
        explanation: 'Heat turns the ice cream liquid, so it is melting.',
      ),
      ChoiceQuestion(
        id: ItemId('mass-warm-see'),
        prompt: 'Why can you not see salt dissolved in water?',
        choices: [
          Wrong('It turned into water', 'Salt particles always stay salt.'),
          Wrong('It left the glass', 'The water tastes salty, so it is there.'),
          Right('Its particles are too small to see'),
        ],
        hint: 'Think about how small particles are.',
        explanation:
            'The salt particles are spread out and far too small to see.',
      ),
    ],
  ),
  predict: const PredictActivity(
    question:
        'A glass with 100 g of water and a 10 g sugar cube sits on a scale '
        'that reads 110 g. You stir until the sugar dissolves. What will it '
        'read?',
    choices: [
      Wrong(
        'Less, because the sugar disappeared',
        'Many people think so, even grown-ups!',
      ),
      Right('Still 110 g'),
      Wrong(
        'More, because sugar water is heavier',
        'Sugar water does feel thicker, so that makes sense to guess.',
      ),
    ],
    tryIt: 'Drag the slider to stir.',
    experiment: massExperiment,
    outcome:
        'The scale still reads 110 g. Every sugar particle is still in the '
        'glass, so the mass stays the same.',
  ),
  explain: [
    ExplainerActivity(
      title: 'Mass stays the same',
      steps: const [
        ExplainerStep(
          'The scale weighs every particle in the glass: water and sugar.',
        ),
        ExplainerStep(
          'As the sugar dissolves, its particles move but stay in the glass.',
        ),
        ExplainerStep(
          'No particle leaves or arrives, so it still weighs 110 g.',
        ),
        ExplainerStep('Mass only changes when particles are added or leave.'),
      ],
      scene: massScene,
    ),
  ],
  practise: const [
    SortActivity(
      prompt: 'Does the mass in the container change?',
      hint: 'Mass changes only when particles are added or leave.',
      bins: [_same, _changes],
      items: [
        SortItem(
          'Salt dissolves in a closed jar',
          bin: _same,
          why: 'Every salt particle stays in the jar.',
        ),
        SortItem(
          'Water boils away from an open pot',
          bin: _changes,
          why: 'Water particles leave the pot as a gas.',
        ),
        SortItem(
          'Ice melts in a sealed bag',
          bin: _same,
          why: 'The same water particles are still in the bag.',
        ),
        SortItem(
          'You stir in another spoon of sugar',
          bin: _changes,
          why: 'You added more particles.',
        ),
        SortItem(
          'Juice freezes in a closed cup',
          bin: _same,
          why: 'Freezing only rearranges the particles.',
        ),
        SortItem(
          'A wet towel dries on a line',
          bin: _changes,
          why: 'Water particles evaporate into the air.',
        ),
      ],
    ),
  ],
  check: const [
    ChoiceQuestion(
      id: ItemId('mass-salt'),
      prompt:
          'You dissolve 20 g of salt in 200 g of water. What is the mass of '
          'the salt water?',
      ordered: true,
      choices: [
        Wrong('200 g', 'Dissolved salt still has mass.'),
        Wrong('210 g', 'No salt left the water, so none of its mass is lost.'),
        Right('220 g'),
        Wrong('240 g', 'Nothing else was added, so it cannot weigh more.'),
      ],
      hint: 'Add the water and the salt together.',
      reason: Reason(
        choices: [
          Wrong(
            'Salt water is heavier than salt plus water',
            'The mass is exactly the water plus the salt.',
          ),
          Right('Every salt particle is still in the water'),
          Wrong(
            'Dissolved salt weighs half as much',
            'A particle keeps its mass when it dissolves.',
          ),
        ],
      ),
      explanation:
          '200 g + 20 g = 220 g. Dissolving moves the salt particles but '
          'keeps every one of them.',
    ),
    ChoiceQuestion(
      id: ItemId('mass-why-same'),
      prompt: 'Why does dissolving not change the mass?',
      choices: [
        Right('No particles leave or arrive'),
        Wrong('Sugar has no mass', 'The sugar cube added 10 g to the scale.'),
        Wrong(
          'Water gets lighter to make room',
          'Water particles keep their mass too.',
        ),
      ],
      hint: 'What would have to happen for the mass to change?',
      explanation:
          'Mass only changes when particles are added or leave. Dissolving '
          'just moves them around.',
    ),
    ChoiceQuestion(
      id: ItemId('mass-evaporates'),
      prompt:
          'A glass of salt water sits on a sunny windowsill for a week. What '
          'happens to its mass?',
      choices: [
        Wrong('It stays the same', 'Water particles leave as a gas.'),
        Right('It goes down as the water evaporates'),
        Wrong('It goes up', 'Nothing is added to the glass.'),
      ],
      hint: 'Remember evaporation: do any particles leave?',
      explanation:
          'Water particles evaporate into the air and leave the glass. The '
          'salt stays, but the total mass goes down.',
    ),
  ],
  debate: const WhoIsRightActivity(
    situation:
        'Sam and Zoe weigh a glass of water, add a sugar cube, and stir '
        'until it dissolves.',
    claims: [
      Claim(zoe, Right('It weighs the same as the water plus the sugar cube.')),
      Claim(
        sam,
        Wrong(
          'It weighs less now, because the sugar is gone.',
          'The sugar is still in the water, so its mass still counts.',
        ),
      ),
    ],
    explanation:
        'Dissolving keeps every sugar particle in the glass. The mass is the '
        'water plus the sugar, before and after stirring.',
  ),
);
