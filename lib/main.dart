import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/providers.dart';
import 'app/router.dart';
import 'app/theme.dart';
import 'data/db.dart';
import 'data/repo.dart';
import 'data/settings.dart';
import 'features/auth/auth.dart';
import 'features/entry/add_entry_screen.dart';
import 'features/report/notifications.dart';
import 'features/sms/sms_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('en_IN');
  final settings = await Settings.load();
  final auth = Auth();
  final db = AppDb();
  final repo = Repo(db, settings);
  if (settings.setupDone) await repo.rollCycles();
  try {
    await AppNotifications.instance.init();
    if (settings.setupDone) await scheduleNotifications(repo, settings);
  } catch (_) {}
  if (settings.setupDone) unawaited(scanSms(repo, settings).catchError((_) => 0));
  final launch = await AppNotifications.instance.launchPayload().catchError((_) => null);
  runApp(ProviderScope(
    overrides: [
      settingsProvider.overrideWith((_) => settings),
      authProvider.overrideWith((_) => auth),
      dbProvider.overrideWithValue(db),
    ],
    child: TallyApp(router: buildRouter(settings, auth), pendingPayload: launch),
  ));
}

class TallyApp extends ConsumerStatefulWidget {
  const TallyApp({super.key, required this.router, this.pendingPayload});
  final GoRouter router;
  final String? pendingPayload;
  @override
  ConsumerState<TallyApp> createState() => _TallyAppState();
}

class _TallyAppState extends ConsumerState<TallyApp> {
  late final AppLifecycleListener _life;
  String? _pending;

  void _open(String payload) {
    if (ref.read(authProvider).locked) {
      _pending = payload;
      return;
    }
    _pending = null;
    if (payload.startsWith('report:')) {
      widget.router.push('/report/${payload.substring(7)}');
    } else if (payload == 'salary') {
      final s = ref.read(settingsProvider);
      widget.router.push('/add', extra: AddArgs(income: true, kind: 'salary', amount: s.usualSalary > 0 ? s.usualSalary : null));
    }
  }

  void _onAuth() {
    final p = _pending;
    if (p != null && !ref.read(authProvider).locked) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _open(p));
    }
  }

  @override
  void initState() {
    super.initState();
    _pending = widget.pendingPayload;
    AppNotifications.instance.onOpen = _open;
    ref.read(authProvider).addListener(_onAuth);
    _life = AppLifecycleListener(
      onHide: () => ref.read(authProvider).onBackground(),
      onShow: () {
        ref.read(authProvider).onForeground();
        final s = ref.read(settingsProvider);
        if (s.setupDone) {
          final repo = ref.read(repoProvider);
          repo.rollCycles().then((_) => scheduleNotifications(repo, s));
          scanSms(repo, s).catchError((_) => 0);
        }
      },
    );
  }

  @override
  void dispose() {
    ref.read(authProvider).removeListener(_onAuth);
    _life.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(settingsProvider.select((s) => s.themeMode));
    return MaterialApp.router(
      title: 'Tally',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: mode,
      routerConfig: widget.router,
      builder: (context, child) {
        final dark = Theme.of(context).brightness == Brightness.dark;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: (dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
              .copyWith(statusBarColor: Colors.transparent, systemNavigationBarColor: dark ? Palette.dark.bg : Palette.light.bg),
          child: child!,
        );
      },
    );
  }
}

/// Schedules the next report and salary-day notifications.
Future<void> scheduleNotifications(Repo repo, Settings s) async {
  final cycles = await repo.allCycles();
  if (cycles.isEmpty) return;
  final c = cycles.first;
  await AppNotifications.instance.scheduleFor(
    currentStart: c.startDate,
    currentEnd: c.endDate,
    nextStart: c.endDate.add(const Duration(days: 1)),
    report: s.reportNotify,
    salaryReminder: s.salaryReminder,
    usualSalary: s.usualSalary,
  );
}
