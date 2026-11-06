import 'package:flutter/material.dart';
import 'package:readrise_plugin_api/readrise_plugin_api.dart';

import 'letter.dart';
import 'letter_text.dart';

/// "Meet the letter": shows the letter and key word and speaks the letter and word.
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
    final letter = widget.letter;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(32),
              onTap: _speak,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LetterText(
                      letter.display,
                      style: TextStyle(
                        fontSize: 140,
                        fontWeight: FontWeight.bold,
                        color: scheme.primary,
                      ),
                    ),
                    Text(letter.emoji, style: const TextStyle(fontSize: 96)),
                    const SizedBox(height: 8),
                    Icon(
                      Icons.volume_up_rounded,
                      size: 48,
                      color: scheme.primary,
                    ),
                  ],
                ),
              ),
            ),
          ),
          FilledButton(
            onPressed: () => widget.host.complete(const ActivityResult()),
            child: const Text('Start'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
