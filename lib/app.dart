import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'ui/home_screen.dart';
import 'ui/lesson_runner_screen.dart';
import 'ui/subject_screen.dart';
import 'ui/theme.dart';

GoRouter buildRouter() => GoRouter(
  routes: [
    GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
    GoRoute(
      path: '/subject/:id',
      builder: (_, state) =>
          SubjectScreen(subjectId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/lesson/:courseId/:lessonId',
      builder: (_, state) => LessonRunnerScreen(
        courseId: state.pathParameters['courseId']!,
        lessonId: state.pathParameters['lessonId']!,
      ),
    ),
  ],
);

class ReadriseApp extends StatefulWidget {
  const ReadriseApp({super.key});

  @override
  State<ReadriseApp> createState() => _ReadriseAppState();
}

class _ReadriseAppState extends State<ReadriseApp> {
  final GoRouter _router = buildRouter();

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'Readrise',
    debugShowCheckedModeBanner: false,
    theme: appTheme(),
    routerConfig: _router,
  );
}
