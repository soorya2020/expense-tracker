import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/settings.dart';
import '../features/auth/auth.dart';
import '../features/auth/lock_screen.dart';
import '../features/auth/setup_screen.dart';
import '../features/cycle/cycle_settings_screen.dart';
import '../features/entry/add_entry_screen.dart';
import '../features/history/history_screen.dart';
import '../features/home/home_screen.dart';
import '../features/settings/settings_screen.dart';

GoRouter buildRouter(Settings settings, Auth auth) {
  CustomTransitionPage<void> slideUp(Widget child, GoRouterState s) => CustomTransitionPage(
        key: s.pageKey,
        child: child,
        transitionsBuilder: (_, a, _, c) => SlideTransition(
          position: Tween(begin: const Offset(0, 1), end: Offset.zero)
              .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
          child: c,
        ),
      );

  return GoRouter(
    initialLocation: '/',
    refreshListenable: Listenable.merge([settings, auth]),
    redirect: (_, state) {
      final loc = state.matchedLocation;
      if (!settings.setupDone) return loc == '/setup' ? null : '/setup';
      if (auth.locked) return loc == '/lock' ? null : '/lock';
      if (loc == '/lock' || loc == '/setup') return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
      GoRoute(path: '/setup', builder: (_, _) => const SetupScreen()),
      GoRoute(path: '/lock', builder: (_, _) => const LockScreen()),
      GoRoute(
        path: '/add',
        pageBuilder: (_, s) => slideUp(AddEntryScreen(args: s.extra as AddArgs? ?? const AddArgs()), s),
      ),
      GoRoute(path: '/history', builder: (_, _) => const HistoryScreen()),
      GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
      GoRoute(path: '/settings/cycle', builder: (_, _) => const CycleSettingsScreen()),
    ],
  );
}
