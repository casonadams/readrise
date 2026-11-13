import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readrise_plugin_api/readrise_plugin_api.dart';

/// An [ActivityHost] that keeps every answer and result its activity
/// reports.
class RecordingHost implements ActivityHost {
  final List<Answer> answers = [];
  final List<ActivityResult> results = [];

  @override
  Speaker get speaker => throw UnimplementedError('activities are silent');

  @override
  void record(Answer answer) => answers.add(answer);

  @override
  void complete(ActivityResult result) => results.add(result);
}

/// Shows [activity] full screen and returns the host it reports to.
Future<RecordingHost> pumpActivity(
  WidgetTester tester,
  ActivityPlugin activity,
) async {
  final host = RecordingHost();
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(builder: (context) => activity.build(context, host)),
      ),
    ),
  );
  await tester.pump();
  return host;
}
