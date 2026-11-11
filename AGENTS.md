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
- Lessons in one course share code (scenes, simulations, classmates) inside the
  course package. Do not split a lesson into its own package.
- Lesson ids are stored in learners' saved progress. Never rename an id; add a
  new lesson instead.
- A warm-up may only recall lessons that come before it. When reordering
  lessons, re-check every warm-up.
- Keep course content files small and cohesive: a lesson file holds content,
  not widget code. Scenes and experiments live in their own files.

## The lesson arc

Every lesson after the first follows this order. Each step has a reason.

| Step | Activity | Why |
| --- | --- | --- |
| 1. Warm-up | `ChoiceQuizActivity(kind: ActivityKind.warmUp)`, 2 questions on earlier lessons | Retrieval, spacing and interleaving improve long-term learning ([Agarwal et al.](https://link.springer.com/article/10.1007/s10648-012-9210-2)) |
| 2. Predict | `PredictActivity` with a hands-on `Experiment` | Predict-Observe-Explain makes learners commit to an idea, then confront it ([POE review](https://www.mdpi.com/2673-8392/6/11/242)) |
| 3. Explain | `ExplainerActivity`: short narrated steps over an animated scene | Names what they just saw; one idea per step |
| 4. Practise | `SortActivity`, a lab, or similar | Applies the idea to many cases |
| 5. Check | `ChoiceQuizActivity` with `Reason`s on key questions | Two-tier questions catch right answers given for wrong reasons ([two-tier review](https://files.eric.ed.gov/fulltext/EJ1285412.pdf)) |
| 6. Who's right? | `WhoIsRightActivity` | Classmates voice the misconception; the learner argues against it |

The first lesson of a course skips the warm-up. Exactly one prediction per
lesson, placed before the first explainer. The course test in
`packages/science_matter/test/src/states_of_matter_course_test.dart` enforces
this arc; copy it for new courses.

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
  This applies to quiz options, reasons, wrong predictions (`reactions`) and
  wrong claims.
- Hints nudge without giving the answer away. Quiz hints appear on request
  and on their own after two misses; using one makes the question worth half.

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
  visible. One control per experiment (a button or an `ExperimentSlider`).
- Keep the evidence on screen after the reveal; the result panel must not
  hide it.
- Physical behaviour must look right. `ParticleSim` simulates the real box
  shape (`height` is the box's height over its width) and is drawn at one
  scale on both axes: never stretch a simulation to fit a box. Liquids pool
  and level out, gases fill the box and bounce off each other, solids rest on
  the floor.
- Use the standard colours already in use: oxygen red, hydrogen white,
  negative charge red, positive charge blue, heat red, cold blue.

## UI and UX

- Every practice activity starts with `ActivityHeader` naming its
  `ActivityKind`, so the learner knows whether they are guessing, learning,
  practising or proving it.
- Reuse `OptionTile`, `AnswerPanel` and `FeedbackBanner`; do not create
  look-alikes.
- Verify on a phone-sized screen (390x844) in the real web build, not only in
  widget tests: build with `flutter build web --release`, serve `build/web`,
  enable semantics, and walk every step you changed. Widget-test fonts render
  text as blocks, so they cannot show text layout problems.
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

- Each course has a content test that checks the arc and that every wrong
  choice, reason, prediction and claim has feedback. Extend it rather than
  relying on review.
- Scene tests use `pumpScene` and `opacityOf` from `test/support/`;
  `opacityOf` fails if the text is missing.
- Looping animations never settle: use fixed `pump(duration)` calls, not
  `pumpAndSettle`, for anything showing a particle view.
- Run `flutter analyze` and `flutter test` at the root and in each changed
  package before finishing.
