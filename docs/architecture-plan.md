# Architecture plan

Goal: adding lessons, courses and subjects should mean writing content, not
code. Shared behaviour lives once, in kits, behind small interfaces; the
compiler, startup validation and CI reject content and code that break the
rules. The test of the design is whether the next lesson is cheaper to write
than the last one.

Baseline (lines in `lib/`, before this plan): app 2089, plugin_api 104,
activity_kit 2227, phonics_alphabet 2065, science_matter 3062.

## Decisions

- **All Dart.** Lessons are typed, `const` Dart objects, not JSON/XML.
  Components are always code; a data format pays off only for non-programmer
  authors, content shipped without an app release, or translation at scale.
  Content classes stay pure Dart so a decoder (an adapter) can be added later.
- **Extend, don't flag.** Behaviour varies by a new class behind an existing
  interface; looks and arrangement vary by composing widgets; parameters are
  for data only (counts, colours, labels, weights).
- **Interfaces at real seams.** A strategy starts as a concrete class passed
  in through a constructor; its interface is extracted when a second
  implementation exists or is scheduled. Strategies are chosen where things
  are wired up (`plugins.dart`, a course file), never by a flag inside.
- **Pure core, adapters at the edges.** Engine rules are pure Dart over plain
  values (ids, outlines, outcomes), not over widget-building plugins.
  Flutter, storage and speech reach the core only through adapters.
- **Reducers inside, single owners at the edges.** Logic is pure
  `(State, Event) -> (State, Effects)`. Each independent async resource
  (progress writer, speaker, later sync) has one owner that handles requests
  in order. No isolates: they do not run in parallel on the web.
- **State, not history.** Progress stores current state (stars, streak, XP,
  per-question stats), not an event log: web storage is capped at about
  5 MB and old events go stale when content changes.
- **Shuffled attempts.** Content is an immutable template; each attempt is a
  seeded, shuffled copy. Options always shuffle unless declared ordered;
  question lists shuffle unless declared ordered.

## Patterns and where they apply

| Pattern | Where |
| --- | --- |
| Strategy | `Control` (input), `Behaviour` (particle physics), `ScoringPolicy`, `UnlockPolicy`, `ReviewScheduler` |
| Adapter | `Speaker` (web/native, exists), `ProgressRepository` over SharedPreferences, `CourseOutline` built from plugins, `ParticleCanvas` (pure world to Flutter), later Rive scenes and a content decoder |
| Facade | `LearningEngine`: the one API screens call |
| Composite | `validate()` over course, lesson, activity, question |
| Builder | `ScienceLesson` builds the activity list in arc order (composition, not an inherited template method) |
| Prototype | `shuffled(Random)` makes an attempt from a content template |
| Role interfaces | optional capabilities (`Randomizable`, `Validated`, `HasItems`) are separate small interfaces, not members every activity must implement |

## Package layout and boundaries

```text
packages/
  readrise_plugin_api/  contract: Course > Lesson > Activity, ActivityHost, ids
  activity_kit/         content/ (pure Dart), activities (presenters),
                        experiment/ templates, generic widgets, testing helpers
  science_kit/          particle world, particle canvas, thermometer,
                        Subject.science, standard colours
  science_matter/       content only: lessons/, experiments/, scenes/ configs
  phonics_alphabet/     reading course
lib/                    engine (pure) + screens (thin adapters)
```

| Package | May import | Never imports |
| --- | --- | --- |
| `readrise_plugin_api` | Flutter | anything else |
| `activity_kit` | plugin_api | subject kits, courses |
| `<subject>_kit` | activity_kit, plugin_api | courses |
| course | its subject kit, activity_kit, plugin_api | other courses, the app |
| app | plugin_api; courses only in `plugins.dart` | kit internals |

Physics (`Ticker`, simulations) and drawing (`CustomPainter`) live in kits.
A course may keep a one-off stateful widget only if it is on the
architecture test's allowlist, so every exception is visible in review.

## Steps

### 1. Experiment template (pilot) - done

- `activity_kit`: `Experiment` interface, `Control<T>` with `SliderControl`
  and `TapControl`, `ControlledExperiment<T>` (gates the control until active,
  reports once, optional settle delay), with its own tests.
- `Pop`, `FactPill`, `ExperimentSlider` moved to `activity_kit`.
- Balloon, zoom, heat-gas and stove are configs plus stateless views in
  `science_matter/lib/src/experiments/`.

Result: course experiment code 596 -> 469 lines, stateful classes 4 -> 0;
the template is 194 lines, shared by every future experiment.

### 2. Typed ids and id lock - done

- Extension types `CourseId` and `LessonId` in `readrise_plugin_api`;
  progress uses a typed `LessonKey` record instead of joining and splitting
  `'course/lesson'` strings. The stored format is unchanged.
- The registry rejects empty ids and ids containing "/".
- `ids.lock` lists every shipped id; tests fail if one disappears or a new
  one is missing from it.

`ItemId` arrives with the content model (step 4), where questions get ids.

### 3. Guardrails - done

- `test/architecture_test.dart` parses `lib/` code with `package:analyzer`:
  import layers, no imports of another package's `src/`, no `Ticker`,
  `CustomPainter` or `StatefulWidget` in courses, no unseeded `Random()`.
  Existing violations sit in an allowlist with a reason or the plan step that
  removes them; a second test fails when an entry is fixed but not deleted.
- jscpd duplication check in CI (`.jscpd.json`, threshold 0.5%; baseline
  0.23%), with Node 26 pinned in `mise.toml`.
- `packages/activity_kit/CATALOG.md`; `OptionTile`, `FeedbackBanner` and
  `AnswerPanel` are now exported so courses can reuse them.
- AGENTS.md: "Reuse and boundaries" section.

Not done: the `public_member_api_docs` lint. It demands a doc comment on
every public member, which conflicts with the comment policy; the catalog
covers discoverability. The "no Flutter in pure-Dart folders" check is added
with the first such folder (`particles/` in step 9).

### 4. Content model - done

- `Right(text)` / `Wrong(text, feedback)` choices for questions, reasons,
  predictions and claims (`Claim(kid, choice)`); sort items name a `SortBin`.
  No index-keyed answers or feedback maps remain.
- `ChoiceQuestion` and `Reason` live in `activity_kit/lib/src/content/`.
- `ScienceLesson(warmUp:, predict:, explain: [...], practise: [...], check:,
  debate:)` builds the arc. `WarmUp(recalls: [...], questions: [...])`
  names the lessons a warm-up draws on.
- `Validated` role interface in `readrise_plugin_api`; the registry calls it
  on courses, lessons and activities at startup. Activities check exactly one
  `Right` and that sort items sit in listed bins; the course runs
  `checkWarmUps` (only the first lesson skips the warm-up, recalls only point
  at earlier lessons).
- The four science lessons are ported. A JSON snapshot of every prompt,
  choice, feedback and activity before and after the port is identical (93
  choices).

Result: the course content test went from 131 to 50 lines; the feedback and
arc checks it held are now types and startup validation. Lesson files grew
from 746 to 827 lines, because each wrong choice now carries its feedback
inline.

Changed from the plan:
- Warm-ups keep their own questions and declare `recalls`, instead of
  referencing earlier check questions: the authored warm-up questions differ
  from the check questions, and rewriting them is a content decision.
- `ItemId` moves to step 8, the first place that stores per-question data.
- `Choices.ordered`, ordered question lists and the positional-text check
  ("both of the above") move to step 6; they only matter once options
  shuffle.
- Content classes may hold a `WidgetBuilder` picture (`ChoiceQuestion.visual`),
  so `content/` is not Flutter-free and has no import check. A future decoder
  would map picture ids to builders.

### 5. Proof lesson - done (evaporation)

`evaporation_lesson.dart`: 205 lines of content. New code: 114 lines (one
stateless view shared by the experiment and the explainer scene, a
4-line-of-config `ControlledExperiment`, a 15-line scene), plus 43 net lines
in `ParticleSim`/`ParticleView` for a particle count that can change. No new
activity, template or test helper was needed; the experiment contract, the
content checks and the phone-size result-panel test covered it unchanged.

For comparison, the heat lesson's experiments and scenes were 507 lines of
code when they were written. The cost now sits in content, not code.

What it says about the remaining steps:
- Step 6 (scenes): writing the scene was cheap because it reused the
  experiment's view; a `KeyframeScene` would save little here. Do the
  randomization half; keep the scene template until a scene needs it.
- Step 9 (particle world): the one code change was in `ParticleSim`, and the
  change was a parameter. The `Behaviour`/`Container` split pays off when a
  lesson needs a new kind of motion (an open box, dissolving); not yet.
- Step 7 (engine) is unaffected by lesson cost; it is about resume, scoring
  and data, and stands on its own merits.

### 6. Randomization - done; scene template deferred

- `Randomizable.shuffled(Random)` role interface in `readrise_plugin_api`.
  Quiz (question order and choices), reasons, prediction choices, "Who's
  right?" claims and sort items shuffle. Never shuffled: activity order,
  explainer steps, lab goals, sort bins, `ChoiceQuestion(ordered: true)`
  (7 science questions: numbers, yes/no, solid-liquid-gas, less-same-more).
- Startup check rejects choices that point at others by position ("all of
  the above") unless the question is ordered.
- `attemptActivities(lesson, random)` in `lib/engine/attempt.dart`; the
  lesson runner seeds a new `Random` from the clock for each attempt.
- Phonics activities carry a `seed` and their sessions take a required
  `Random`; their unseeded `Random()` calls and allowlist entries are gone.
- `randomizableContract` in `readrise_testing`: every part kept (so choices
  keep their feedback), same seed same order, different seeds differ. Proven
  to fail on a shuffle that does nothing and on one that drops an item.

Changed from the plan:
- No re-roll when an attempt matches the previous one: that needs the
  previous arrangement stored, which belongs with resume snapshots (step 7).
  Until then a repeat is possible but unlikely (a 3-question quiz with 3
  choices each has 6 x 6^3 = 1296 arrangements).
- No ordered question lists: no quiz needs one yet.
- `Scene`/`KeyframeScene` deferred (see step 5).

### 7. Engine core - resume done; the rest deferred

Done:
- `LessonSession` (`lib/engine/lesson_session.dart`): a pure value with
  `advance(result)` returning `NextActivity(session)` or
  `LessonFinished(outcome)`; tested with plain Dart values.
- `SessionStore` saves it under `session.v1` after every activity, apart
  from `progress.v1` (whose format is unchanged). Reopening the lesson
  resumes at the same activity with the same seed, so the same shuffle;
  finishing clears it (only if it is that lesson's). Leaving asks first and
  says where the learner will restart.
- Tests prove resume keeps the step and the order after the clock moves on,
  and that a finished lesson starts over; each fails with its behaviour
  removed.

Deferred, with the reason:
- Scoring by events (`ActivityHost.record`, `ScoringPolicy`): see step 8
  (answers are recorded; the policy is not needed yet).
- `LearningEngine` facade, `ProgressRepository` interface, `CourseOutline`
  and `LinearUnlock`: screens make about six calls to plain engine
  functions, storage has one implementation (tests fake SharedPreferences),
  and there is one unlock rule. Add each when a second consumer,
  implementation or rule arrives.
- A single writer for saves: progress and session use separate keys and
  each save writes the whole value, so overlapping saves cannot corrupt
  either.
- Resume restarts the current activity; progress inside an activity (two
  of three questions done) is not kept.

### 8. Per-question stats and adaptive warm-ups - done

- `ItemId` on every `ChoiceQuestion` (23 in science), unique within a
  course; `HasItems` lets the registry reject empty, "/" and duplicate ids;
  `items.lock` guards them like `ids.lock`.
- `ActivityHost.record(Answer(item, firstTry:))`; the quiz records each
  question when it is settled. The runner saves an activity's answers when
  it completes.
- `ItemStats` per course/item (seen, first tries, last seen, Leitner box
  0-4) in `Progress.items`. It is an additive field in `progress.v1`: older
  saves load with no stats, so there is no `v2` key and no migration.
- `Review` role interface and `pickForReview` (lowest box first, then
  longest unseen, ties at random; null until enough are answered).
  `WarmUpQuiz` reviews the recalled lessons' check questions; its own
  questions remain the fallback. `WarmUp.recalls` now names lesson objects.
- `attemptActivities` gives each activity its own seeded random, so a
  review's pick never reshuffles later activities (needed when a lesson
  resumes after new answers were saved).
- Tests: the Leitner table, the picker, attempts with reviews, the kit
  warm-up, and an app test where the next lesson's warm-up reviews the
  question missed in the previous one; it fails if the runner ignores stats.

Not done, with the reason:
- `ScoringPolicy`: XP already comes from one kit function (`scoreXp`), the
  phonics weights differ on purpose, and the engine only sums XP. Answers
  now flow to the engine, so a policy can be added when scoring needs to
  change across activities.
- Phonics and the non-quiz activities (predictions, sorts, debates) record
  no answers: none of them is reviewed yet.

### 9. Particle world (`science_kit`) - kit done; behaviour split deferred

Done:
- `packages/science_kit`: `ParticleSim` and `MatterState` (pure Dart, in
  `src/particles/`), `ParticleView`, and three drawings pulled out of the
  course as public widgets: `Thermometer` (with `temperatureColor`),
  `WaterMolecule` (its drift animation included) and `BalloonBalance`.
  `ScienceColors` holds the standard colours; `scienceSubject` and
  `readingSubject` (in `phonics_alphabet`) replace the subject constants
  that sat in `readrise_plugin_api`.
- `ParticleSim` takes a required `Random`; `ParticleView` a `seed`. No
  unseeded `Random()` is left in any package.
- Reduced motion: `ParticleView` draws one frame settled over 3 simulated
  seconds and skips its colour fade, instead of animating.
- Architecture test: the science allowlist went from 10 entries to 1 (the
  heat lab, a deliberate one-off); a new rule keeps `src/particles/` free
  of Flutter.
- A pixel diff of the molecule scene and the balloon experiment before and
  after the move found 0 changed pixels.

Deferred, with the reason:
- Splitting `ParticleSim` into `World`/`Behaviour`/`Container`/`Spawn` and
  the behaviour contract test: the proof lesson needed only a parameter
  (particle count). Split it when a lesson needs a new kind of motion (an
  open box, dissolving, a mixture).
- The jar in the zoom experiment is plain widget composition, not drawing
  code, so it stays in the course.

### Second science course (Mixtures and Solutions) - done

The test of whether `science_kit` and the reuse rules hold for a course
they were not built from.

- Reused as is: `ParticleView`, `ControlledExperiment` with `SliderControl`
  and `TapControl`, `FactPill`, `Pop`, every activity, `WarmUpQuiz` review.
- Moved to shared packages because a second course needed them:
  `ScienceLesson`/`WarmUp`/`checkWarmUps` and the cast (to `science_kit`),
  and the course content checks (`courseContentContract` in
  `readrise_testing`), which also restored the hint checks on warm-up
  questions.
- Extended through data, not flags: `ParticleSim.setSugar` (dissolved
  particles move with the liquid, undissolved ones are held in a crystal),
  diffusion so dissolved sugar does not sit at the bottom, and a crystal
  block drawn behind held particles. No `Behaviour` split was needed: a
  held particle is one more piece of particle state.
- Cost: 792 lines of content in 4 lessons, 417 lines of course code (four
  stateless views and their configs), 0 painters, tickers or stateful
  widgets in the course. Course 1 has 1,223 lines of non-lesson code.
  Duplication fell from 0.23% to 0.16%; none is between the two courses.
- Phone-size renders found two layout faults that tests did not: wrapped
  fact pills squeezing the glass flat, and undissolved sugar that looked
  loose. Both fixed in the shared view and the kit.

### Later

- Glossary `Term` objects with a first-use check.
- Generated lessons for tabular content (letters, math facts, vocabulary).
- Further `UnlockPolicy` and `ReviewScheduler` implementations.
