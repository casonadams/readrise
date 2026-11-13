# science_kit catalog

What science courses can use from `package:science_kit/science_kit.dart`.
Read this and `packages/activity_kit/CATALOG.md` before writing a widget;
physics and drawing belong here, not in a course.

## Particles

| Name | Use |
| --- | --- |
| `ParticleView` | Animated particles for a `MatterState` at an `energy` (0..1). Fills its box at one scale; optional `count` (fewer particles, liquid or gas) and `seed`. With reduced motion it draws one settled frame. |
| `ParticleSim` | The pure-Dart model behind `ParticleView`: `fit` to the box shape, `step`, `resize`. Use it directly only in tests or a new view. |
| `MatterState` | Solid, liquid or gas. `waterStateAt(celsius)` and `energyAt(celsius)` map a water temperature to state and particle energy. |

## Drawings

| Name | Use |
| --- | --- |
| `Thermometer` | A thermometer filled to a temperature, marked at 0 and 100 degrees; `temperatureColor` gives the matching cold-to-hot colour. |
| `WaterMolecule` | One oxygen and two hydrogen atoms: `join` (0 loose, 1 bonded) and `charged`. Animate `join` from the course's scene. |
| `BalloonBalance` | A balance with an empty balloon and one holding `air`, tipped by `tilt`. |

## Values

| Name | Use |
| --- | --- |
| `ScienceColors` | The standard colours: oxygen red, hydrogen white, negative red, positive blue, heat red, cold blue. |
| `scienceSubject` | The Science subject (title, emoji, colour) for science courses. |
