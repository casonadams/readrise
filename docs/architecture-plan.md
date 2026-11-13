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
with the first such folder (`content/` in step 4).

### 4. Content model

- Move content classes (`ChoiceQuestion`, `Reason`, `Claim`, `SortItem`, the
  prediction fields) out of widget files into pure-Dart `activity_kit`
  `content/`; activities become presenters of content.
- `Right(text)` / `Wrong(text, because:)` choices for questions, predictions
  (`reaction:`), reasons and claims; no index-keyed answers or feedback maps.
- `Choices.ordered([...])` and ordered question lists for sequences that
  carry meaning.
- `ScienceLesson(warmUp:, predict:, explain:, practise: [...], check:,
  debate:)` builds the arc; list slots wherever a lesson may need more than
  one activity, a single slot only where the rules demand one (the
  prediction). Phonics keeps its own lesson type.
- Questions carry `ItemId`s (a new extension type, added to `ids.lock`);
  warm-ups reference earlier lessons' check questions.
- `validate()` down the tree (exactly one `Right`, warm-ups only from earlier
  lessons, no positional option text such as "both of the above"), called by
  `PluginRegistry` at startup.
- Port the four science lessons.

Accept: a wrong choice without feedback does not compile; content classes
import no Flutter; the arc test shrinks to "only the first lesson may skip
the warm-up".

### 5. Proof lesson

Write one new science lesson on the new structure. Record lines of content,
lines of new code, and anything that needed a new kit component. Use the
result to decide how much of steps 6-9 is worth doing, and in what order.

### 6. Scene template and randomization

- `Scene` interface (`steps`, `build`); `KeyframeScene<F>` (frames per step,
  tweening, reduced motion). Port the five explainer scenes.
- `Randomizable.shuffled(Random)` on content: options, question order,
  prediction options, "Who's right?" claims, sort items. Never shuffled:
  activity order, explainer steps, sequential lab goals, anything declared
  ordered.
- The engine seeds each attempt and re-rolls once if the arrangement equals
  the previous attempt's.
- Phonics and the particle sim take the engine-provided `Random`.

Accept: a contract test over every randomizable content type and many seeds
shows items, correct answers and attached feedback preserved and orders
varying; scene step counts match explainer steps.

### 7. Engine core

- `CourseOutline` (ids, lesson ids, `requires`) built from plugins by the
  registry; engine rules use outlines, not widget-building plugins.
- `Progress` keeps state only; unlock rules move to `LinearUnlock` (the
  first `UnlockPolicy`).
- `LessonSession` reducer: `Running(index)`, `Finished(outcome)`,
  `Recorded`; effects as data (`SaveSnapshot`, `RecordOutcome`).
- Resume snapshot (activity index, seed) under its own storage key, so
  leaving and reopening a lesson resumes at the same activity and order.
- Activities report outcomes (`Answered(item, firstTry, hintUsed,
  confidence)`) through `ActivityHost.record`; `ScoringPolicy` turns them into
  XP using per-activity weights, replacing `scoreXp` in activities and the
  two phonics formulas.
- `ProgressRepository` (SharedPreferences adapter, in-memory fake) behind a
  single writer that serializes saves; `LearningEngine` facade for screens.

Accept: reducer, scoring and unlocking are tested with plain Dart values; no
activity computes XP; the stored progress format is unchanged.

### 8. Per-question stats (`progress.v2`)

- Add per-question stats (`seen`, `correct`, `lastSeen`, Leitner box) keyed
  by `ItemId`; migrate `v1` stars once.
- `LeitnerScheduler` (the first `ReviewScheduler`) picks warm-up questions
  from finished lessons, weighted by misses and time since last seen;
  hand-picked warm-ups remain the fallback.

Accept: a `v1` save loads into `v2` with stars intact; warm-ups favour
questions the learner missed.

### 9. Particle world (`science_kit`)

- Create `science_kit`; move `MatterState`, colours and `Subject.science`.
- Split `ParticleSim`: pure-Dart `World`, `Behaviour` (`Lattice`, `Pooling`,
  `FreeFlight`), `Box`, `Contacts`, `Spawn`; Flutter `ParticleCanvas`,
  `ShinyBall`, `SimFrame`. `Container` and `ParticleStyle` become interfaces
  when their second implementation arrives.
- `ParticleCanvas` pauses under reduced motion.
- Move the balance-scale and jar drawings out of `experiments/` into
  `science_kit`.
- Contract test: every behaviour in every container keeps particles inside,
  keeps the count, has no NaN, and moves faster with more energy.

Accept: existing scene and simulation tests pass; `particles/` imports no
Flutter.

### Later

- Glossary `Term` objects with a first-use check.
- Generated lessons for tabular content (letters, math facts, vocabulary).
- Further `UnlockPolicy` and `ReviewScheduler` implementations.
