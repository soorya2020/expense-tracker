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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('en_IN');
  final settings = await Settings.load();
  final auth = Auth();
  final db = AppDb();
  if (settings.setupDone) await Repo(db, settings).rollCycles();
  runApp(ProviderScope(
    overrides: [
      settingsProvider.overrideWith((_) => settings),
      authProvider.overrideWith((_) => auth),
      dbProvider.overrideWithValue(db),
    ],
    child: TallyApp(router: buildRouter(settings, auth)),
  ));
}

class TallyApp extends ConsumerStatefulWidget {
  const TallyApp({super.key, required this.router});
  final GoRouter router;
  @override
  ConsumerState<TallyApp> createState() => _TallyAppState();
}

class _TallyAppState extends ConsumerState<TallyApp> {
  late final AppLifecycleListener _life;

  @override
  void initState() {
    super.initState();
    _life = AppLifecycleListener(
      onHide: () => ref.read(authProvider).onBackground(),
      onShow: () {
        ref.read(authProvider).onForeground();
        if (ref.read(settingsProvider).setupDone) ref.read(repoProvider).rollCycles();
      },
    );
  }

  @override
  void dispose() {
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
