import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'engine/registry.dart';
import 'plugins.dart';
import 'state/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        registryProvider.overrideWithValue(PluginRegistry(installedCourses())),
        closedSubjectsProvider.overrideWithValue(comingSoonSubjects),
      ],
      child: const ReadriseApp(),
    ),
  );
}
