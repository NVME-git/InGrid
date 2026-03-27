import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'features/game/home_screen.dart';
import 'features/game/game_screen.dart';
import 'features/history/history_screen.dart';
import 'features/stats/stats_screen.dart';
import 'features/import/import_screen.dart';
import 'features/help/help_screen.dart';
import 'features/help/beginner_lesson_screen.dart';
import 'features/help/intermediate_lesson_screen.dart';
import 'features/help/advanced_lesson_screen.dart';
import 'services/session_service.dart';
import 'services/theme_notifier.dart';

final _router = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    if (state.matchedLocation == '/game' && !SessionService.gameSessionActive) {
      return '/';
    }
    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/game',
      builder: (context, state) => const GameScreen(),
    ),
    GoRoute(
      path: '/history',
      builder: (context, state) => const HistoryScreen(),
    ),
    GoRoute(
      path: '/stats',
      builder: (context, state) => const StatsScreen(),
    ),
    GoRoute(
      path: '/import',
      builder: (context, state) =>
          ImportScreen(initialTab: state.extra as String?),
    ),
    GoRoute(
      path: '/help',
      builder: (ctx, state) => const HelpScreen(),
    ),
    GoRoute(
      path: '/lessons/beginner',
      builder: (ctx, state) => const BeginnerLessonScreen(),
    ),
    GoRoute(
      path: '/lessons/intermediate',
      builder: (ctx, state) => const IntermediateLessonScreen(),
    ),
    GoRoute(
      path: '/lessons/advanced',
      builder: (ctx, state) => const AdvancedLessonScreen(),
    ),
  ],
);

class InGridApp extends ConsumerWidget {
  const InGridApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    return MaterialApp.router(
      title: 'InGrid',
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      themeMode: themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0D9488),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF0F4F8),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF0F4F8),
          foregroundColor: Colors.black87,
          elevation: 0,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0D9488),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF1A1A2E),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A1A2E),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        useMaterial3: true,
      ),
    );
  }
}
