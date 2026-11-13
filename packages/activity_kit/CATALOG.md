# activity_kit catalog

Everything a course can use from `package:activity_kit/activity_kit.dart`.
Read this before writing a widget. Reuse order: use as is, compose, implement
an interface listed here, extract an interface from a class here, and only
then add something new (to this kit if any subject could use it).

## Lessons

| Name | Use |
| --- | --- |
| `BasicLesson` | A lesson as `id`, `title` and a list of activities. |

## Activities

| Name | Use |
| --- | --- |
| `ChoiceQuizActivity` | Multiple-choice questions (`ChoiceQuestion`) with per-option feedback, a hint, and an optional second-tier `Reason`. `kind: ActivityKind.warmUp` or `.check`. |
| `PredictActivity` | Predict, say how sure (`Confidence`), run an `Experiment`, see the outcome. |
| `ExplainerActivity` | Captioned steps (`ExplainerStep`) over an `ExplainerScene(context, step)`. |
| `SortActivity` | Drag or tap `SortItem`s into bins, with a hint and a "why" per item. |
| `WhoIsRightActivity` | Classmates (`Kid`) make `Claim`s; the learner picks who is right. |
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
| `OptionTile` | A lettered answer choice in an `OptionState` (open, picked, wrong, correct, dimmed). Use for every tappable answer. |
| `FeedbackBanner` | A one-line coloured note of `FeedbackKind` correct, wrong or hint. |
| `AnswerPanel` | The panel that slides up once an answer is settled: title, explanation, Continue. |
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
