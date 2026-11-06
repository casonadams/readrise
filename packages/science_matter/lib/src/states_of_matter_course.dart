import 'package:activity_kit/activity_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:readrise_plugin_api/readrise_plugin_api.dart';

import 'heat_lab_activity.dart';
import 'matter_state.dart';
import 'particle_view.dart';

/// Matter, particles, states, heat and changes of state (NGSS MS-PS1-1, -4, -5).
class StatesOfMatterCourse implements CoursePlugin {
  StatesOfMatterCourse();

  @override
  String get id => 'states-of-matter';

  @override
  String get title => 'States of Matter';

  @override
  Grade get grade => Grade.grade6;

  @override
  Subject get subject => Subject.science;

  @override
  List<String> get requires => const [];

  @override
  final List<LessonPlugin> lessons = [
    BasicLesson(id: 'matter', title: 'Matter', activities: _matter),
    BasicLesson(id: 'states', title: 'States', activities: _states),
    BasicLesson(id: 'heat', title: 'Heat', activities: _heat),
    BasicLesson(id: 'changes', title: 'Changes', activities: _changes),
  ];
}

WidgetBuilder _particles(MatterState state, double energy) =>
    (_) => ParticleView(state: state, energy: energy);

const _matter = <ActivityPlugin>[
  InfoCardActivity(
    title: 'Everything is matter',
    body:
        'Matter is anything that has mass and takes up space. Rocks, water, '
        'and even the air you breathe are matter.\n\n'
        'Light, heat, and sound are forms of energy. They are not matter.',
  ),
  InfoCardActivity(
    title: 'Tiny particles',
    body:
        'All matter is made of tiny particles called atoms. Atoms join '
        'together in groups called molecules.\n\n'
        'One water molecule has 3 atoms: 2 hydrogen atoms and 1 oxygen atom. '
        'That is why water is written H2O.',
  ),
  SortActivity(
    prompt: 'Is it matter?',
    bins: ['Matter', 'Not matter'],
    items: [
      SortItem('Rock', bin: 0),
      SortItem('Light', bin: 1),
      SortItem('Water', bin: 0),
      SortItem('Sound', bin: 1),
      SortItem('Air', bin: 0),
      SortItem('Heat', bin: 1),
      SortItem('Wood', bin: 0),
    ],
  ),
  ChoiceQuizActivity(
    questions: [
      ChoiceQuestion(
        prompt:
            'A balloon gets bigger when you blow into it. What does that '
            'show?',
        options: [
          'Air is not matter',
          'Air takes up space',
          'Balloons make air',
          'Air has no mass',
        ],
        answer: 1,
        explanation:
            'The air inside takes up space. Anything that takes up space and '
            'has mass is matter.',
      ),
      ChoiceQuestion(
        prompt: 'What are atoms?',
        options: [
          'The tiny particles all matter is made of',
          'A kind of energy',
          'Only found in solids',
        ],
        answer: 0,
        explanation:
            'Every kind of matter, solid, liquid, or gas, is made of atoms.',
      ),
      ChoiceQuestion(
        prompt: 'How many atoms are in one water molecule (H2O)?',
        options: ['1', '2', '3', '4'],
        answer: 2,
        explanation: 'Two hydrogen atoms plus one oxygen atom makes 3 atoms.',
      ),
    ],
  ),
];

final _states = <ActivityPlugin>[
  const InfoCardActivity(
    title: 'Three common states',
    body:
        'The matter you meet every day is usually a solid, a liquid, or a '
        'gas. What changes is how the particles are arranged and how they '
        'move.',
  ),
  InfoCardActivity(
    title: 'Solid',
    body:
        'In a solid, particles are packed tightly. They vibrate in place but '
        'do not swap places, so a solid keeps its own shape.',
    visual: _particles(MatterState.solid, 0.3),
  ),
  InfoCardActivity(
    title: 'Liquid',
    body:
        'In a liquid, particles stay close together but slide past each '
        'other. A liquid keeps its volume but takes the shape of its '
        'container.',
    visual: _particles(MatterState.liquid, 0.5),
  ),
  InfoCardActivity(
    title: 'Gas',
    body:
        'In a gas, particles are far apart and fly around, bumping into each '
        'other and the walls. A gas spreads out to fill its whole container.',
    visual: _particles(MatterState.gas, 0.7),
  ),
  ChoiceQuizActivity(
    questions: [
      ChoiceQuestion(
        prompt: 'Which state of matter is this?',
        options: ['Solid', 'Liquid', 'Gas'],
        answer: 2,
        explanation:
            'The particles are far apart and moving fast in every direction. '
            'That is a gas.',
        visual: _particles(MatterState.gas, 0.7),
      ),
      ChoiceQuestion(
        prompt: 'Which state of matter is this?',
        options: ['Solid', 'Liquid', 'Gas'],
        answer: 0,
        explanation:
            'The particles are packed in fixed positions and only vibrate. '
            'That is a solid.',
        visual: _particles(MatterState.solid, 0.3),
      ),
      ChoiceQuestion(
        prompt: 'Which state of matter is this?',
        options: ['Solid', 'Liquid', 'Gas'],
        answer: 1,
        explanation:
            'The particles touch but slide past each other. That is a liquid.',
        visual: _particles(MatterState.liquid, 0.5),
      ),
    ],
  ),
  const SortActivity(
    prompt: 'Which state is it at room temperature?',
    bins: ['Solid', 'Liquid', 'Gas'],
    items: [
      SortItem('Ice cube', bin: 0),
      SortItem('Orange juice', bin: 1),
      SortItem('Helium', bin: 2),
      SortItem('Wooden block', bin: 0),
      SortItem('Milk', bin: 1),
      SortItem('Oxygen', bin: 2),
      SortItem('Gold ring', bin: 0),
    ],
  ),
];

const _heat = <ActivityPlugin>[
  InfoCardActivity(
    title: 'Heat and motion',
    body:
        'Temperature tells you how fast the particles in something are '
        'moving, on average.\n\n'
        'Add thermal energy and the particles move faster. Take it away and '
        'they slow down. Move the slider in the next activity to see it '
        'happen.',
  ),
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
  ChoiceQuizActivity(
    questions: [
      ChoiceQuestion(
        prompt: 'What happens to the particles when you heat a substance?',
        options: ['They move faster', 'They stop moving', 'They disappear'],
        answer: 0,
        explanation:
            'Adding thermal energy makes particles move faster on average.',
      ),
      ChoiceQuestion(
        prompt: 'At what temperature does water freeze?',
        options: ['-10\u00B0C', '0\u00B0C', '32\u00B0C', '100\u00B0C'],
        answer: 1,
        explanation:
            'Water freezes at 0\u00B0C. (32 is the freezing point in '
            'Fahrenheit, a different scale.)',
      ),
      ChoiceQuestion(
        prompt:
            'Steam is much hotter than ice. How do their particles '
            'compare?',
        options: [
          'Steam particles move faster on average',
          'Ice particles move faster on average',
          'They move at the same speed',
        ],
        answer: 0,
        explanation:
            'Higher temperature means faster particles, so the steam '
            'particles move faster.',
      ),
    ],
  ),
];

const _changes = <ActivityPlugin>[
  InfoCardActivity(
    title: 'Changing state',
    body:
        'When thermal energy is added or removed, matter can change state:\n\n'
        'Melting: solid to liquid\n'
        'Freezing: liquid to solid\n'
        'Boiling or evaporating: liquid to gas\n'
        'Condensing: gas to liquid\n\n'
        'It is still the same substance. Only the arrangement and motion of '
        'its particles changed.',
  ),
  SortActivity(
    prompt: 'Is thermal energy added or removed?',
    bins: ['Energy added', 'Energy removed'],
    items: [
      SortItem('Melting', bin: 0),
      SortItem('Freezing', bin: 1),
      SortItem('Boiling', bin: 0),
      SortItem('Condensing', bin: 1),
      SortItem('Evaporating', bin: 0),
    ],
  ),
  ChoiceQuizActivity(
    questions: [
      ChoiceQuestion(
        prompt:
            'Drops of water form on a cold glass on a hot day. What is '
            'happening?',
        options: ['Boiling', 'Melting', 'Condensing', 'Freezing'],
        answer: 2,
        explanation:
            'Water vapor in the air touches the cold glass, loses energy, '
            'and condenses into liquid drops.',
      ),
      ChoiceQuestion(
        prompt:
            'A 20 g ice cube melts completely. What is the mass of the '
            'water?',
        options: ['Less than 20 g', '20 g', 'More than 20 g'],
        answer: 1,
        explanation:
            'Matter is not created or destroyed when it changes state. The '
            'same particles are still there, so the mass stays 20 g.',
      ),
      ChoiceQuestion(
        prompt: 'Which change needs thermal energy to be added?',
        options: ['Condensing', 'Freezing', 'Melting'],
        answer: 2,
        explanation:
            'Particles must speed up to break out of a solid\'s fixed '
            'positions, so melting needs energy added.',
      ),
    ],
  ),
];
