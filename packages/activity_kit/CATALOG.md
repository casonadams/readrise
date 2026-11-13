# activity_kit catalog

Everything a course can use from `package:activity_kit/activity_kit.dart`.
Read this before writing a widget. Reuse order: use as is, compose, implement
an interface listed here, extract an interface from a class here, and only
then add something new (to this kit if any subject could use it).

## Lessons

| Name | Use |
| --- | --- |
| `BasicLesson` | A lesson as `id`, `title` and a list of activities. |

## Content

| Name | Use |
| --- | --- |
| `Right` / `Wrong` | Answer choices (`Choice`). `Wrong(text, feedback)` carries what the learner is told after picking it. Used by questions, reasons, predictions and claims. |
| `ChoiceQuestion` | A prompt, its `choices`, an explanation, an optional hint, `Reason` and picture. |
| `Reason` | The second tier of a question: why the right answer is right, as `choices`. |
| `Claim` | What a classmate (`Kid`) says, as a `Right` or `Wrong` choice. |
| `SortBin` / `SortItem` | Bins and the items that belong in them; an item names its bin. |

Activities with content implement `Validated`; the app checks them at startup
(exactly one `Right`, items only in listed bins, no "all of the above" in
choices that shuffle). Quiz, prediction, "Who's right?" and sort also
implement `Randomizable`: the engine shuffles a copy for every attempt.
`ChoiceQuestion(ordered: true)` keeps choices whose order means something.

## Activities

| Name | Use |
| --- | --- |
| `ChoiceQuizActivity` | `ChoiceQuestion`s with a hint after misses and an optional `Reason`. `kind: ActivityKind.warmUp` or `.check`. |
| `WarmUpQuiz` | A warm-up: its own `questions`, or, once the learner has answered enough of the `pool`, the engine's pick of the pool questions they find hardest (`Review`). |
| `PredictActivity` | Predict from `choices`, say how sure (`Confidence`), run an `Experiment`, see the outcome. |
| `ExplainerActivity` | Captioned steps (`ExplainerStep`) over an `ExplainerScene(context, step)`. |
| `SortActivity` | Drag or tap `SortItem`s into `SortBin`s, with a hint and a "why" per item. |
| `WhoIsRightActivity` | Classmates make `Claim`s; the learner picks who is right. |
| `InfoCardActivity` | A short explanation with an optional picture, then Continue. |

## Experiments

| Name | Use |
| --- | --- |
| `Experiment` | Interface for the hands-on part of a prediction: disabled until `active`, calls `onObserved` once. Implement it directly only when one control cannot drive the experiment. |
| `ControlledExperiment<T>` | An experiment from one `Control<T>`, an `observed(value)` rule, a stateless `view(value)` and an optional `settle` delay. The default way to build an experiment. |
| `Control<T>` | Interface for an experiment's one input. Implement it for a new kind of input. |
| `SliderControl` | A 0..1 slider between two icons. |
| `TapControl` | A button pressed up to `presses` times, then steps aside. |

## Widgets

| Name | Use |
| --- | --- |
| `FeedbackLayout` | Wraps an activity page; its `feedback` (a banner or panel) slides up over the bottom without resizing the page. `page` gets the height covered, for the end of a scrolling page. |
| `OptionTile` | A lettered answer choice in an `OptionState` (open, picked, wrong, correct, dimmed). Use for every tappable answer. |
| `FeedbackBanner` | A one-line coloured note of `FeedbackKind` correct, wrong or hint; show it through `FeedbackLayout`. |
| `AnswerPanel` | What a settled answer means, then Continue; show it through `FeedbackLayout`. |
| `FactPill` | A short fact with an optional icon and colour, shown as evidence. |
| `Pop` | Scales and fades a child in (after an optional delay) when `visible`. |
| `Shake` | Wiggles a child when `trigger` increases; respects reduced motion. |
| `ExperimentSlider` | The slider `SliderControl` draws; use the control instead in experiments. |

## Values

| Name | Use |
| --- | --- |
| `ActivityKind` | The badge naming the moment: `warmUp`, `predict`, `sort`, `check`, `whoIsRight`. |
| `Kid` | A classmate (name, skin and hair colour) for `WhoIsRightActivity`. |
| `hintAfterMisses` | Wrong picks before a quiz hint appears on its own. |
| `predictionTitle` | The result headline for a prediction. |
