# Readrise

Gamified, scaffolded English reading app for pre-K to 1st grade (Flutter).
Live web build: https://casonadams.github.io/readrise/

## Architecture

The app is a small engine that runs plugins. It knows nothing about letters,
words or grammar.

| Piece | Role |
| --- | --- |
| `packages/readrise_plugin_api` | Interfaces: `CoursePlugin` > `LessonPlugin` > `ActivityPlugin`, plus `ActivityHost` and `Speaker` |
| `packages/activity_kit` | Reusable activities: explainer, predict-then-experiment, choice quiz (hints, two-tier reasons, warm-up/check), drag-to-sort, "Who's right?", info card; `BasicLesson` |
| `packages/phonics_alphabet` | Course plugins for the whole alphabet (7 courses, ages 3-6): meet a letter, trace it, pop balloons, feed the monster, then a review per set |
| `packages/science_matter` | Course plugin: states of matter with hands-on particle experiments, grades 5-8 (NGSS MS-PS1); one file per lesson in `lib/src/lessons/` |
| `packages/readrise_testing` | Test helpers shared by packages (dev dependency only): activity and scene hosts, experiment contract tests, seeded fake content |
| `lib/engine` | Plugin registry, progress, unlock rules, scoring (XP, stars, streaks), subject summaries and "continue" target; lesson sessions (shuffled attempts that resume where the learner left off) |
| `lib/ui`, `lib/state`, `lib/data` | Home (subjects + Continue), subject path, lesson runner and celebration screens; Riverpod providers; local storage and text-to-speech |
| `lib/plugins.dart` | The list of installed courses |

Each course declares a `Subject` (title, emoji, colour). The home screen groups
courses by subject, and each subject gets its own colour through its path,
lessons and activities.

A course plugin owns its content and logic. It returns lessons; each lesson
returns activities (intro, quiz, game, ...); each activity builds a widget and
calls `host.complete(ActivityResult)` when done. The engine runs activities in
order, turns mistakes into stars, and unlocks lessons and courses.

To add a course: create `packages/<name>` implementing `CoursePlugin`, add it
to the workspace in the root `pubspec.yaml`, list it in `lib/plugins.dart`,
and add its `course/lesson` ids to `ids.lock`.
Tests mirror the `lib/` layout in the app and in each package.
To list a subject on the home screen before it is ready, add its id to
`comingSoonSubjects` in `lib/plugins.dart`: it shows as "Coming soon" and
cannot be opened, and Continue skips it.

Lesson design and authoring rules for agents and contributors are in
`AGENTS.md`.

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

## Third-party assets

Letter shapes use the Andika font (SIL Open Font License 1.1), bundled
unmodified in `packages/phonics_alphabet/assets/fonts/` with its licence
(`Andika-OFL.txt`).
