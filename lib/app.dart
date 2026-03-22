import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'features/game/home_screen.dart';
import 'features/game/game_screen.dart';

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/game',
      builder: (context, state) => const GameScreen(),
    ),
  ],
);

class InGridApp extends StatelessWidget {
  const InGridApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'InGrid',
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0D9488),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF1A1A2E),
        useMaterial3: true,
      ),
    );
  }
}
