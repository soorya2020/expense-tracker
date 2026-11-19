import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/settings.dart';
import '../features/auth/auth.dart';
import '../features/auth/lock_screen.dart';
import '../features/auth/setup_screen.dart';
import '../features/cycle/cycle_settings_screen.dart';
import '../features/entry/add_entry_screen.dart';
import '../features/history/history_screen.dart';
import '../features/report/report_screen.dart';
import '../features/report/big_picture_screen.dart';
import '../features/home/home_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/settings/budgets_screen.dart';
import '../features/settings/recurring_screen.dart';
import '../features/sms/bank_sms_screen.dart';

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

  // Unlocking, and opening a report: the new screen fades in and settles from slightly larger.
  CustomTransitionPage<void> fadeScale(Widget child, GoRouterState s, {double from = 1.04}) => CustomTransitionPage(
        key: s.pageKey,
        child: child,
        transitionDuration: const Duration(milliseconds: 380),
        reverseTransitionDuration: const Duration(milliseconds: 260),
        transitionsBuilder: (_, a, _, c) {
          final t = CurvedAnimation(parent: a, curve: Curves.easeOutCubic);
          return FadeTransition(
            opacity: t,
            child: ScaleTransition(scale: Tween(begin: from, end: 1.0).animate(t), child: c),
          );
        },
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
      GoRoute(path: '/', pageBuilder: (_, s) => fadeScale(const HomeScreen(), s, from: .97)),
      GoRoute(path: '/setup', builder: (_, _) => const SetupScreen()),
      GoRoute(path: '/lock', pageBuilder: (_, s) => fadeScale(const LockScreen(), s)),
      GoRoute(
        path: '/add',
        pageBuilder: (_, s) => slideUp(AddEntryScreen(args: s.extra as AddArgs? ?? const AddArgs()), s),
      ),
      GoRoute(path: '/history', builder: (_, _) => const HistoryScreen()),
      GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
      GoRoute(path: '/settings/recurring', builder: (_, _) => const RecurringScreen()),
      GoRoute(path: '/settings/budgets', builder: (_, _) => const BudgetsScreen()),
      GoRoute(path: '/settings/cycle', builder: (_, _) => const CycleSettingsScreen()),
      GoRoute(path: '/sms', builder: (_, s) => BankSmsScreen(debits: s.uri.queryParameters['tab'] != 'credits')),
      GoRoute(path: '/big-picture', builder: (_, _) => const BigPictureScreen()),
      GoRoute(
        path: '/report/:start',
        pageBuilder: (_, s) => fadeScale(ReportScreen(startMillis: int.parse(s.pathParameters['start']!)), s, from: .92),
      ),
    ],
  );
}
