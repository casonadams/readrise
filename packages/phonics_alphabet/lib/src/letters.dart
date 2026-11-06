import 'letter.dart';

/// The 26 letters in Letters and Sounds phase 2 order, in sets of three or
/// four. Early letters combine into many simple words (sat, tap, pin).
const letterSets = <List<Letter>>[
  [
    Letter(
      char: 's',
      word: 'sun',
      emoji: '\u2600\uFE0F',
      more: [
        PictureWord('sock', '\u{1F9E6}'),
        PictureWord('snake', '\u{1F40D}'),
      ],
    ),
    Letter(
      char: 'a',
      word: 'apple',
      emoji: '\u{1F34E}',
      more: [
        PictureWord('ant', '\u{1F41C}'),
        PictureWord('alligator', '\u{1F40A}'),
      ],
    ),
    Letter(
      char: 't',
      word: 'tiger',
      emoji: '\u{1F42F}',
      more: [PictureWord('turtle', '\u{1F422}'), PictureWord('tent', '\u26FA')],
    ),
    Letter(
      char: 'p',
      word: 'pig',
      emoji: '\u{1F437}',
      more: [
        PictureWord('pizza', '\u{1F355}'),
        PictureWord('penguin', '\u{1F427}'),
      ],
    ),
  ],
  [
    Letter(
      char: 'i',
      word: 'insect',
      emoji: '\u{1F41B}',
      more: [PictureWord('iguana', '\u{1F98E}')],
    ),
    Letter(
      char: 'n',
      word: 'nose',
      emoji: '\u{1F443}',
      more: [
        PictureWord('nut', '\u{1F95C}'),
        PictureWord('necklace', '\u{1F4FF}'),
      ],
    ),
    Letter(
      char: 'm',
      word: 'moon',
      emoji: '\u{1F319}',
      more: [
        PictureWord('monkey', '\u{1F412}'),
        PictureWord('mouse', '\u{1F42D}'),
      ],
    ),
    Letter(
      char: 'd',
      word: 'dog',
      emoji: '\u{1F436}',
      more: [
        PictureWord('duck', '\u{1F986}'),
        PictureWord('drum', '\u{1F941}'),
      ],
    ),
  ],
  [
    Letter(
      char: 'g',
      word: 'goat',
      emoji: '\u{1F410}',
      more: [
        PictureWord('grapes', '\u{1F347}'),
        PictureWord('guitar', '\u{1F3B8}'),
      ],
    ),
    Letter(
      char: 'o',
      word: 'octopus',
      emoji: '\u{1F419}',
      more: [PictureWord('orange', '\u{1F34A}')],
    ),
    Letter(
      char: 'c',
      word: 'cat',
      emoji: '\u{1F431}',
      more: [PictureWord('cow', '\u{1F42E}'), PictureWord('cake', '\u{1F370}')],
    ),
    Letter(
      char: 'k',
      word: 'key',
      emoji: '\u{1F511}',
      more: [
        PictureWord('kangaroo', '\u{1F998}'),
        PictureWord('king', '\u{1F934}'),
      ],
    ),
  ],
  [
    Letter(
      char: 'e',
      word: 'egg',
      emoji: '\u{1F95A}',
      more: [
        PictureWord('elephant', '\u{1F418}'),
        PictureWord('envelope', '\u2709\uFE0F'),
      ],
    ),
    Letter(char: 'u', word: 'umbrella', emoji: '\u2602\uFE0F'),
    Letter(
      char: 'r',
      word: 'rabbit',
      emoji: '\u{1F430}',
      more: [
        PictureWord('rainbow', '\u{1F308}'),
        PictureWord('robot', '\u{1F916}'),
      ],
    ),
  ],
  [
    Letter(
      char: 'h',
      word: 'hat',
      emoji: '\u{1F3A9}',
      more: [
        PictureWord('horse', '\u{1F434}'),
        PictureWord('house', '\u{1F3E0}'),
      ],
    ),
    Letter(
      char: 'b',
      word: 'bee',
      emoji: '\u{1F41D}',
      more: [PictureWord('ball', '\u26BD'), PictureWord('banana', '\u{1F34C}')],
    ),
    Letter(
      char: 'f',
      word: 'fish',
      emoji: '\u{1F41F}',
      more: [
        PictureWord('frog', '\u{1F438}'),
        PictureWord('flower', '\u{1F338}'),
      ],
    ),
    Letter(
      char: 'l',
      word: 'lion',
      emoji: '\u{1F981}',
      more: [
        PictureWord('leaf', '\u{1F343}'),
        PictureWord('lemon', '\u{1F34B}'),
      ],
    ),
  ],
  [
    Letter(
      char: 'j',
      word: 'jet',
      emoji: '\u2708\uFE0F',
      more: [PictureWord('jeans', '\u{1F456}')],
    ),
    Letter(
      char: 'v',
      word: 'van',
      emoji: '\u{1F690}',
      more: [
        PictureWord('violin', '\u{1F3BB}'),
        PictureWord('volcano', '\u{1F30B}'),
      ],
    ),
    Letter(
      char: 'w',
      word: 'watch',
      emoji: '\u231A',
      more: [
        PictureWord('whale', '\u{1F433}'),
        PictureWord('web', '\u{1F578}\uFE0F'),
      ],
    ),
    Letter(char: 'x', word: 'fox', emoji: '\u{1F98A}'),
  ],
  [
    Letter(
      char: 'y',
      word: 'yarn',
      emoji: '\u{1F9F6}',
      more: [PictureWord('yo-yo', '\u{1FA80}')],
    ),
    Letter(
      char: 'z',
      word: 'zebra',
      emoji: '\u{1F993}',
      more: [PictureWord('zombie', '\u{1F9DF}')],
    ),
    Letter(
      char: 'q',
      word: 'queen',
      emoji: '\u{1F478}',
      more: [PictureWord('question', '\u2753')],
    ),
  ],
];

final allLetters = [for (final set in letterSets) ...set];
