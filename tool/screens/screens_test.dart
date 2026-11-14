// Renders the main screens with sample data into PNGs (test/goldens/) so the
// layout can be checked without a phone. Run: flutter test --update-goldens test/screens_test.dart
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tally/app/providers.dart';
import 'package:tally/app/theme.dart';
import 'package:tally/data/db.dart';
import 'package:tally/data/repo.dart';
import 'package:tally/data/settings.dart';
import 'package:tally/features/auth/auth.dart';
import 'package:tally/features/entry/add_entry_screen.dart';
import 'package:tally/features/history/history_screen.dart';
import 'package:tally/features/home/home_screen.dart';
import 'package:tally/features/report/report_screen.dart';

Future<void> _loadFonts() async {
  final loader = FontLoader('InterTight');
  for (final w in [400, 500, 600, 800, 900]) {
    loader.addFont(rootBundle.load('assets/fonts/InterTight-$w.ttf'));
  }
  await loader.load();
}

void main() {
  late AppDb db;
  late Settings settings;
  late Repo repo;

  setUpAll(_loadFonts);

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'setupDone': true,
      'startingBalance': 1240000,
      'startingDate': DateTime(2026, 10, 1).millisecondsSinceEpoch,
      'cycleDay': 3,
    });
    settings = await Settings.load();
    db = AppDb(NativeDatabase.memory());
    repo = Repo(db, settings);
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day).subtract(const Duration(days: 11));
    Future<void> inc(int r, String k, String? t, int d) => repo.addEntry(EntriesCompanion.insert(
        kind: EntryKind.income, amount: r * 100, incomeKind: Value(k), title: Value(t), date: start.add(Duration(days: d))));
    Future<void> out(int r, String? t, int d, {int? to}) => repo.addEntry(EntriesCompanion.insert(
        kind: EntryKind.spending, amount: r * 100, title: Value(t), date: start.add(Duration(days: d)),
        endDate: Value(to == null ? null : start.add(Duration(days: to)))));
    // Previous cycle
    await inc(30000, 'salary', null, -30);
    await inc(2500, 'extra', 'Dad', -20);
    await out(31200, null, -25, to: -2);
    // This cycle
    await inc(30000, 'salary', null, 0);
    await out(9000, 'Rent', 0);
    await inc(5000, 'extra', 'Mom', 3);
    await out(14300, null, 0, to: 6);
    await inc(1500, 'extra', 'Brother', 7);
    await out(9600, null, 7, to: 11);
    await db.into(db.cycles).insert(CyclesCompanion.insert(
        startDate: start.subtract(const Duration(days: 31)), endDate: start.subtract(const Duration(days: 1)), closedAt: Value(DateTime.now())));
    await db.into(db.cycles).insert(CyclesCompanion.insert(startDate: start, endDate: start.add(const Duration(days: 29))));
  });

  tearDown(() => db.close());

  Future<void> shot(WidgetTester t, Widget screen, String name, {Brightness b = Brightness.light}) async {
    t.view.physicalSize = const Size(1080, 2340);
    t.view.devicePixelRatio = 2.75;
    final auth = Auth()..unlock();
    await t.pumpWidget(ProviderScope(
      overrides: [
        settingsProvider.overrideWith((_) => settings),
        authProvider.overrideWith((_) => auth),
        dbProvider.overrideWithValue(db),
      ],
      child: MaterialApp(theme: buildTheme(b), debugShowCheckedModeBanner: false, home: screen),
    ));
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
    await t.pump(const Duration(milliseconds: 300));
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/$name.png'));
    await t.pumpWidget(const SizedBox());
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
  }

  testWidgets('home', (t) => shot(t, const HomeScreen(), 'home'));
  testWidgets('home dark', (t) => shot(t, const HomeScreen(), 'home_dark', b: Brightness.dark));
  testWidgets('add income', (t) => shot(t, const AddEntryScreen(args: AddArgs(income: true)), 'add_income'));
  testWidgets('add spending', (t) => shot(t, const AddEntryScreen(args: AddArgs(income: false)), 'add_spending'));
  testWidgets('history', (t) => shot(t, const HistoryScreen(), 'history'));
  testWidgets('report', (t) async {
    final c = await repo.allCycles();
    await shot(t, ReportScreen(startMillis: c.last.startDate.millisecondsSinceEpoch), 'report');
  });
}
