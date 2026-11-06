# Readrise

Gamified, scaffolded English reading app for pre-K to 1st grade (Flutter).
Live web build: https://casonadams.github.io/readrise/

## Structure

- `lib/domain` - curriculum, lesson engine, progress rules (pure Dart)
- `lib/data` - local persistence, text-to-speech
- `lib/state` - Riverpod providers
- `lib/ui` - screens

## Develop

    flutter pub get
    flutter test
    flutter run -d chrome

Pushes to `main` run analyze, test, and deploy the web build to GitHub Pages.

Letter sounds currently use platform text-to-speech; recorded phoneme audio
is the planned replacement.
