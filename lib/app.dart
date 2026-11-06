import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'domain/curriculum.dart';
import 'state/providers.dart';
import 'ui/home_screen.dart';
import 'ui/lesson_screen.dart';

final _router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
    GoRoute(
      path: '/lesson/:id',
      builder: (_, state) => _LessonRoute(id: state.pathParameters['id']!),
    ),
  ],
);

/// Picks the screen for a lesson's type.
class _LessonRoute extends ConsumerWidget {
  const _LessonRoute({required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      switch (ref.watch(curriculumProvider).lessonById(id)) {
        final LetterLesson lesson => LetterLessonScreen(lesson: lesson),
      };
}

class ReadriseApp extends StatelessWidget {
  const ReadriseApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'Readrise',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorSchemeSeed: const Color(0xFF58CC02),
      useMaterial3: true,
    ),
    routerConfig: _router,
  );
}
