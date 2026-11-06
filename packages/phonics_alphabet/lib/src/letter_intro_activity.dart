import 'package:flutter/material.dart';
import 'package:readrise_plugin_api/readrise_plugin_api.dart';

import 'letter.dart';

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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _speak());
  }

  void _speak() =>
      widget.host.speaker.speak('${widget.letter.char}. ${widget.letter.word}');

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
                    Text(
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
