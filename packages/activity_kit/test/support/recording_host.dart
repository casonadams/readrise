import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readrise_plugin_api/readrise_plugin_api.dart';

class RecordingHost implements ActivityHost {
  final List<ActivityResult> results = [];

  @override
  Speaker get speaker => throw UnimplementedError('not used by activity_kit');

  @override
  void complete(ActivityResult result) => results.add(result);
}

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
  return host;
}
