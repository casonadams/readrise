# Readrise

Gamified, scaffolded English reading app for pre-K to 1st grade (Flutter).
Live web build: https://casonadams.github.io/readrise/

## Architecture

The app is a small engine that runs plugins. It knows nothing about letters,
words or grammar.

| Piece | Role |
| --- | --- |
| `packages/readrise_plugin_api` | Interfaces: `CoursePlugin` > `LessonPlugin` > `ActivityPlugin`, plus `ActivityHost` and `Speaker` |
| `packages/activity_kit` | Reusable activities: info card, choice quiz, drag-to-sort; `BasicLesson` |
| `packages/phonics_alphabet` | Course plugin: letter shapes and sounds (Alphabet 1 and 2), ages 3-6 |
| `packages/science_matter` | Course plugin: states of matter with an interactive particle model, grades 5-8 (NGSS MS-PS1) |
| `lib/engine` | Plugin registry, progress, unlock rules, scoring (XP, stars, streaks) |
| `lib/ui`, `lib/state`, `lib/data` | Screens, Riverpod providers, local storage and text-to-speech |
| `lib/plugins.dart` | The list of installed courses |

A course plugin owns its content and logic. It returns lessons; each lesson
returns activities (intro, quiz, game, ...); each activity builds a widget and
calls `host.complete(ActivityResult)` when done. The engine runs activities in
order, turns mistakes into stars, and unlocks lessons and courses.

To add a course: create `packages/<name>` implementing `CoursePlugin`, add it
to the workspace in the root `pubspec.yaml`, and list it in `lib/plugins.dart`.
Tests mirror the `lib/` layout in the app and in each package.

## Develop

Toolchain is pinned in `mise.toml` (Flutter, which bundles Dart); CI uses the same file.

    mise install
    flutter pub get
    flutter test                                   # app
    (cd packages/science_matter && flutter test)   # a plugin
    flutter run -d chrome

Pushes to `main` run analyze and tests, then deploy the web build to GitHub Pages.

Letter sounds currently use platform text-to-speech; recorded phoneme audio
is the planned replacement.
