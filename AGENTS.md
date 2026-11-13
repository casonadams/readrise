# Readrise agent guide

Read `README.md` for the architecture. This file holds the rules for building
and changing lessons. They come from learning-science research and from
mistakes already made and fixed in this repo; follow them unless the user asks
otherwise.

## Lesson structure

- One lesson per file, implementing `LessonPlugin` (usually as a
  `BasicLesson`), e.g. `packages/science_matter/lib/src/lessons/heat_lesson.dart`.
  The course file only lists lessons, so adding, removing or reordering a lesson
  is a one-line change there.
- Lessons in one course share content (scenes, experiments, classmates) inside
  the course package. Do not split a lesson into its own package.
- Course and lesson ids are stored in learners' saved progress. Never rename
  or remove one; add a new lesson instead. `ids.lock` lists every shipped id
  and a test fails if one disappears; add new ids to it.
- Every question has an `ItemId`, unique within its course
  (`<lesson>-<what it asks>`, `<lesson>-warm-...` for warm-ups). Answers are
  stored under it, so the same rules apply, with `items.lock`. Rewording a
  question keeps its id; a question that asks something new gets a new id.
- A warm-up may only recall lessons that come before it. Each `WarmUp` lists
  the lessons it `recalls`, and the app refuses to start if one is not
  earlier in the course. Its own questions are for learners new to the
  course; once a learner has answered enough of the recalled lessons' check
  questions, the warm-up asks the ones they find hardest instead.
- Keep course content files small and cohesive: a lesson file holds content,
  not widget code. Scenes and experiments live in their own files.

## Reuse and boundaries

- Before writing a widget, read the kit's catalog
  (`packages/activity_kit/CATALOG.md`).
- Reuse in this order: use a component as is; compose components; implement
  an interface a kit offers (`Control`, `Experiment`); extract an interface
  from an existing class and add your implementation; only then add a new
  component, in a kit if any subject could use it. Never copy a component
  into a course.
- Vary behaviour with a new class, looks by composing widgets, and use
  parameters only for data (counts, colours, labels). Never add a flag that
  switches behaviour.
- Packages import only lower layers: `readrise_plugin_api`, then
  `activity_kit`, then subject kits, then courses. The app imports courses
  only in `lib/plugins.dart`. Never import another package's `src/`.
- Physics (`Ticker`) and drawing (`CustomPainter`) live in kits. A course may
  keep a one-off stateful widget only with an entry, and a reason, in the
  allowlist in `test/architecture_test.dart`.
- Randomness comes from a seeded `Random` passed in, never `Random()`.
- `test/architecture_test.dart` and the duplication check (`.jscpd.json`)
  enforce these rules.

## The lesson arc

Every lesson after the first follows this order. Each step has a reason.

| Step | Activity | Why |
| --- | --- | --- |
| 1. Warm-up | `WarmUp` (a `WarmUpQuiz`), 2 questions on earlier lessons, chosen from what the learner missed once they have answered enough | Retrieval, spacing and interleaving improve long-term learning ([Agarwal et al.](https://link.springer.com/article/10.1007/s10648-012-9210-2)) |
| 2. Predict | `PredictActivity` with a hands-on `Experiment` | Predict-Observe-Explain makes learners commit to an idea, then confront it ([POE review](https://www.mdpi.com/2673-8392/6/11/242)) |
| 3. Explain | `ExplainerActivity`: short narrated steps over an animated scene | Names what they just saw; one idea per step |
| 4. Practise | `SortActivity`, a lab, or similar | Applies the idea to many cases |
| 5. Check | `ChoiceQuizActivity` with `Reason`s on key questions | Two-tier questions catch right answers given for wrong reasons ([two-tier review](https://files.eric.ed.gov/fulltext/EJ1285412.pdf)) |
| 6. Who's right? | `WhoIsRightActivity` | Classmates voice the misconception; the learner argues against it |

The first lesson of a course skips the warm-up. Exactly one prediction per
lesson, placed before the first explainer. A science lesson is a
`ScienceLesson` with one named slot per step, so it cannot be built out of
order; `checkWarmUps` (run at startup) checks the warm-up rules.

## Designing around misconceptions

- Start from what learners wrongly believe, not from the textbook order. Find
  the known misconceptions for the topic first (for matter, see
  [Novick & Nussbaum 1981](https://onlinelibrary.wiley.com/doi/10.1002/sce.3730650209)
  and [RSC *Beyond Appearances*](https://edu.rsc.org/changes-of-state/students-ideas-about-changes-of-state-beyond-appearances/4017768.article)).
- Make the misconception a predict option and a wrong claim in "Who's right?".
  The prediction should surprise most learners.
- Predictions are never marked as mistakes. Ask "How sure are you?" only on
  predictions: confident errors are corrected best by feedback
  ([Butterfield & Metcalfe 2006](https://www.columbia.edu/cu/psychology/metcalfe/PDFs/Butterfield_Metcalfe_2006.pdf)).
- Every wrong choice gets its own feedback saying why it is wrong, not just
  "try again" ([Shute 2008](https://journals.sagepub.com/doi/abs/10.3102/0034654307313795)).
  Write choices as `Right(text)` and `Wrong(text, feedback)`: quiz options,
  reasons, predictions (the feedback is the reaction) and claims
  (`Claim(kid, Wrong(...))`). A wrong choice without feedback does not
  compile.
- Hints nudge without giving the answer away. Quiz hints appear on request
  and on their own after two misses; using one makes the question worth half.
- Every attempt shuffles questions, choices, claims and sort items, so a
  retake looks different. Never write a choice that points at the others
  ("all of the above"); the app refuses to start. When the order of choices
  means something (numbers, a scale, yes then no, solid-liquid-gas), mark
  the question `ordered: true`.

## Writing for young readers

- Grades 5-8 read these lessons; earlier grades may too. Use short sentences
  and everyday words. Define a science word the first time it appears.
- One idea per explainer step, one or two sentences each.
- Prediction outcomes: at most two short sentences. Reactions: one sentence.
  Feedback and hints: one sentence. Never stack paragraphs in a result panel;
  the evidence on screen does the explaining.
- Use concrete, everyday situations (balloons, puddles, a cold glass) before
  abstract statements.
- Classmates in "Who's right?" come from `lessons/classmates.dart`; keep the
  cast diverse and vary who is right.

## Scenes and experiments

- Explainer scenes are `ExplainerScene(context, step)` and must be pure
  functions of `step`, animating between steps with implicit animations
  (`TweenAnimationBuilder`, `AnimatedOpacity`, `Pop`).
- An `Experiment` gets `active` and `onObserved`. Its controls do nothing
  until `active`. It calls `onObserved` exactly once, after the result is
  visible. One control per experiment: build it as a `ControlledExperiment`
  with a `SliderControl`, a `TapControl` or a new `Control`.
- Keep the evidence on screen after the reveal. The result panel may cover
  controls (choices, sliders), never the experiment: a prediction keeps its
  choices below the experiment for this, and the course test checks every
  prediction's result panel on a phone-sized screen.
- Physical behaviour must look right. `ParticleSim` takes the real box shape
  (`fit` with the view's height over width; a flat box grows wider) and is
  drawn at one scale on both axes: never stretch a simulation to fit a box.
  Liquids pool and level out, gases fill the whole box and bounce off each
  other, solids rest on the floor.
- Use the standard colours already in use: oxygen red, hydrogen white,
  negative charge red, positive charge blue, heat red, cold blue.

## UI and UX

- Every practice activity starts with `ActivityHeader` naming its
  `ActivityKind`, so the learner knows whether they are guessing, learning,
  practising or proving it.
- Reuse `OptionTile`, `AnswerPanel` and `FeedbackBanner`; do not create
  look-alikes.
- Feedback and Continue never push the page around: wrap the page in
  `FeedbackLayout` and pass the banner or panel as its `feedback`, so it
  slides up over the bottom. Nothing on the page may change size when it
  appears; keep the space of anything that hides (`Visibility` with
  `maintainSize`).
- Verify on a phone-sized screen (390x844) in the real web build, not only in
  widget tests: build with `flutter build web --release`, serve `build/web`,
  enable semantics, and walk every step you changed. Widget-test fonts render
  text as blocks, so they cannot show text layout problems; a test that
  measures text must load the app's font (`loadRoboto` in `readrise_testing`).
- Accessibility: every tappable answer has a semantics label that includes
  its state ("..., wrong", "..., correct"), and hidden duplicates (like step
  dots next to "1 of 3") are excluded from semantics.

## Narration

- Science activities are silent for now: no narration and no read-aloud
  buttons. Text-to-speech is being redesigned; do not add speech to
  `activity_kit` activities until that design exists.
- When speech returns, avoid two bugs already hit here: read `host.speaker`
  in `initState`, never lazily (a first read in `dispose` throws once the
  widget is deactivated); and start speaking after the first frame, because
  the card being replaced stops speech in its `dispose`, which runs after
  the new card builds.

## Tests

- Each course has a content test for rules types cannot express (hints,
  distinct choices, every sort bin used). Content the app can check itself
  implements `Validated`; the registry runs it at startup.
- Shared test helpers live in `packages/readrise_testing` (a dev dependency;
  shipped code may not import it): `pumpActivity`, `pumpScene` and
  `opacityOf` (fails if the text is missing), `loadRoboto`, and
  `experimentContract`, which every new experiment must pass.
- Where the words do not matter, build content with the seeded
  `ContentFaker` instead of hand-typing placeholders; type real strings only
  when the test checks them.
- Looping animations never settle: use fixed `pump(duration)` calls, not
  `pumpAndSettle`, for anything showing a particle view.
- Run `flutter analyze` and `flutter test` at the root and in each changed
  package, and `npx -y jscpd@5.4.3` at the root, before finishing.
