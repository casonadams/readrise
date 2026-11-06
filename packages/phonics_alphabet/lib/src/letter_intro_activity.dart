import 'package:flutter/material.dart';
import 'package:readrise_plugin_api/readrise_plugin_api.dart';

import 'letter.dart';
import 'letter_text.dart';

/// "Meet the letter": shows the letter, a picture and its word with the
/// letter picked out in colour, and says the letter, then the word.
class LetterIntroActivity implements ActivityPlugin {
  const LetterIntroActivity(this.letter);

  final Letter letter;

  @override
  Widget build(BuildContext context, ActivityHost host) =>
      _IntroView(letter: letter, host: host);
}

class _IntroView extends StatefulWidget {
  const _IntroView({required this.letter, required this.host});

  final Letter letter;
  final ActivityHost host;

  @override
  State<_IntroView> createState() => _IntroViewState();
}

class _IntroViewState extends State<_IntroView> {
  static const _pause = Duration(milliseconds: 400);
  int _speakId = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _speak());
  }

  /// Says the letter, pauses, then says the word. A newer call cancels the
  /// rest of an older one.
  Future<void> _speak() async {
    final id = ++_speakId;
    await widget.host.speaker.speak(widget.letter.char);
    await Future<void>.delayed(_pause);
    if (!mounted || id != _speakId) return;
    await widget.host.speaker.speak(widget.letter.word);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final letter = widget.letter;
    final at = letter.highlightIndex;
    final base = letterTextStyle(40, color: scheme.onSurface);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Expanded(
            child: Semantics(
              container: true,
              button: true,
              label: 'Letter ${letter.char}, ${letter.word}. Tap to hear it.',
              excludeSemantics: true,
              onTap: _speak,
              child: InkWell(
                borderRadius: BorderRadius.circular(32),
                onTap: _speak,
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        LetterText(
                          letter.display,
                          style: letterTextStyle(150, color: scheme.primary),
                        ),
                        Text(
                          letter.emoji,
                          style: const TextStyle(fontSize: 96),
                        ),
                        const SizedBox(height: 8),
                        Text.rich(
                          TextSpan(
                            style: base,
                            children: [
                              TextSpan(text: letter.word.substring(0, at)),
                              TextSpan(
                                text: letter.word.substring(at, at + 1),
                                style: base.copyWith(
                                  color: scheme.primary,
                                  decoration: TextDecoration.underline,
                                  decorationThickness: 3,
                                ),
                              ),
                              TextSpan(text: letter.word.substring(at + 1)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.volume_up_rounded,
                              color: scheme.primary,
                            ),
                            const SizedBox(width: 6),
                            Text('Tap to hear', style: text.labelLarge),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => widget.host.complete(const ActivityResult()),
              child: const Text('Next'),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
