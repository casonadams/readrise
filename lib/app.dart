import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'domain/curriculum.dart';
import 'ui/home_screen.dart';
import 'ui/lesson_screen.dart';

final _router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
    GoRoute(
      path: '/lesson/:id',
      builder: (_, state) =>
          LessonScreen(skill: curriculum.byId(state.pathParameters['id']!)),
    ),
  ],
);

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
