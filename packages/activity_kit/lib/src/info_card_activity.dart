import 'package:flutter/material.dart';
import 'package:readrise_plugin_api/readrise_plugin_api.dart';

/// A short explanation, optionally with a picture or model, then Continue.
class InfoCardActivity implements ActivityPlugin {
  const InfoCardActivity({
    required this.title,
    required this.body,
    this.visual,
  });

  final String title;
  final String body;
  final WidgetBuilder? visual;

  @override
  Widget build(BuildContext context, ActivityHost host) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: text.headlineMedium),
                  const SizedBox(height: 16),
                  if (visual != null) ...[
                    SizedBox(height: 200, child: visual!(context)),
                    const SizedBox(height: 16),
                  ],
                  Text(body, style: text.bodyLarge),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => host.complete(const ActivityResult()),
              child: const Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }
}
