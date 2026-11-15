// Renders the app's real screens with sample data into docs/screenshots/.
// Run: flutter test --update-goldens tool/screens/screens_test.dart
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tally/app/providers.dart';
import 'package:tally/app/theme.dart';
import 'package:tally/core/cycle_math.dart';
import 'package:tally/data/db.dart';
import 'package:tally/data/recurring.dart';
import 'package:tally/data/repo.dart';
import 'package:tally/data/settings.dart';
import 'package:tally/features/auth/auth.dart';
import 'package:tally/features/auth/lock_screen.dart';
import 'package:tally/features/entry/add_entry_screen.dart';
import 'package:tally/features/history/history_screen.dart';
import 'package:tally/features/home/home_screen.dart';
import 'package:tally/features/report/big_picture_screen.dart';
import 'package:tally/features/report/report_screen.dart';
import 'package:tally/features/settings/recurring_screen.dart';
import 'package:tally/features/settings/settings_screen.dart';
import 'package:tally/features/sms/bank_sms_screen.dart';

const out = '../../docs/screenshots';

Future<void> _loadFonts() async {
  final it = FontLoader('InterTight');
  for (final w in [400, 500, 600, 800, 900]) {
    it.addFont(rootBundle.load('assets/fonts/InterTight-$w.ttf'));
  }
  await it.load();
  final sdk = Platform.environment['FLUTTER_ROOT'] ?? '/home/user/tools/flutter';
  final icons = FontLoader('MaterialIcons')
    ..addFont(Future.value(ByteData.sublistView(File('$sdk/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf').readAsBytesSync())));
  await icons.load();
}

void main() {
  late AppDb db;
  late Settings settings;
  late Repo repo;
  late List<Entry> entries;
  late List<Cycle> cycles;
  late List<BankMessage> sms;
  late DateTime start; // this cycle

  setUpAll(_loadFonts);

  setUp(() async {
    final now = DateTime.now();
    start = cycleStartOnOrBefore(dateOnly(now), 3);
    SharedPreferences.setMockInitialValues({
      'setupDone': true,
      'startingBalance': 960000,
      'startingDate': DateTime(2026, 4, 1).millisecondsSinceEpoch,
      'cycleDay': 3,
      'usualSalary': 3000000,
      'smsEnabled': true,
      'smsLastScan': now.millisecondsSinceEpoch,
      'lastBackup': now.subtract(const Duration(days: 2)).millisecondsSinceEpoch,
    });
    settings = await Settings.load();
    db = AppDb(NativeDatabase.memory());
    repo = Repo(db, settings);

    Future<int> inc(int r, String k, String? t, DateTime d) => repo.addEntry(
        EntriesCompanion.insert(kind: EntryKind.income, amount: r * 100, incomeKind: Value(k), title: Value(t), date: d));
    Future<int> spend(int r, String? t, DateTime d, {DateTime? to, bool unexpected = false, String? reason, bool yearly = false}) =>
        repo.addEntry(EntriesCompanion.insert(
            kind: EntryKind.spending,
            amount: r * 100,
            title: Value(t),
            date: d,
            endDate: Value(to),
            unexpected: Value(unexpected),
            reason: Value(reason),
            yearly: Value(yearly)));

    // Six finished cycles, then this one.
    final spent = [29500, 31800, 31000, 30100, 33200, 31200];
    final help = [0, 2000, 0, 10000, 0, 0];
    for (var k = 6; k >= 1; k--) {
      final s = DateTime(start.year, start.month - k, 3);
      final e = DateTime(start.year, start.month - k + 1, 2);
      await db.into(db.cycles).insert(CyclesCompanion.insert(startDate: s, endDate: e, closedAt: Value(e)));
      final i = 6 - k;
      await inc(30000, IncomeKind.salary, 'Salary', s);
      await spend(9000, 'Rent', s);
      if (help[i] > 0) {
        await inc(help[i], IncomeKind.help, 'Dad', s.add(const Duration(days: 9)));
        await spend(help[i], i == 3 ? 'Bike insurance' : 'Clinic', s.add(const Duration(days: 8)),
            unexpected: true, reason: i == 3 ? 'insurance' : 'medical', yearly: i == 3);
      }
      if (k == 1) {
        await inc(2500, IncomeKind.extra, 'Dad', s.add(const Duration(days: 9)));
        await inc(1500, IncomeKind.extra, 'Amazon refund', s.add(const Duration(days: 15)));
      }
      await spend(spent[i] - 9000, null, s.add(const Duration(days: 1)), to: e);
    }
    await db.into(db.cycles).insert(CyclesCompanion.insert(startDate: start, endDate: DateTime(start.year, start.month + 1, 2)));
    await inc(30000, IncomeKind.salary, 'Salary', start);
    await spend(9000, 'Rent', start);
    await spend(3900, null, start.add(const Duration(days: 1)), to: start.add(const Duration(days: 6)));
    await inc(1000, IncomeKind.extra, 'Rahul', start.add(const Duration(days: 7)));
    await spend(2700, null, start.add(const Duration(days: 7)), to: start.add(const Duration(days: 11)));
    await inc(5000, IncomeKind.borrowed, 'Arjun', start.add(const Duration(days: 9)));

    final t = dateOnly(now);
    await repo.insertBankSms([
      for (final (i, (dir, amt, who, ago)) in [
        ('credit', 100000, 'Rahul S', 0),
        ('credit', 240000, 'Amazon', 1),
        ('debit', 38900, 'Swiggy', 0),
        ('debit', 120000, 'Indian Oil', 1),
        ('debit', 64900, 'Zepto', 2),
        ('debit', 19900, 'Netflix', 3),
        ('credit', 3000000, 'Acme Pvt Ltd', 12),
      ].indexed)
        BankSmsCompanion.insert(
          refNo: 'R$i',
          direction: dir,
          amount: amt,
          account: const Value('••1234'),
          counterparty: Value(who),
          sender: 'AX-HDFCBK',
          receivedAt: t.subtract(Duration(days: ago)).add(Duration(hours: 9 + i)),
          status: Value(i == 6 ? 'added' : 'new'),
          rawText: 'Rs.${amt ~/ 100} ${dir}ed',
        ),
    ]);
    await saveRules(settings, [
      RecurringRule(id: '1', income: true, kind: IncomeKind.salary, title: 'Salary', amount: 3000000, day: 3, lastCycle: start.millisecondsSinceEpoch),
      RecurringRule(id: '2', income: false, title: 'Rent', amount: 900000, day: 3, lastCycle: start.millisecondsSinceEpoch),
      RecurringRule(id: '3', income: false, title: 'Bike EMI', amount: 320000, day: 10),
      RecurringRule(id: '4', income: false, title: 'Netflix', amount: 19900, day: 21, remind: false),
    ]);
    entries = await repo.allEntries();
    entries.sort((a, b) => effectiveDate(b).compareTo(effectiveDate(a)));
    cycles = await repo.allCycles();
    sms = (await db.select(db.bankSms).get())..sort((a, b) => b.receivedAt.compareTo(a.receivedAt));

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      ..setMockMethodCallHandler(const MethodChannel('flutter.baseflow.com/permissions/methods'), (c) async => 1)
      ..setMockMethodCallHandler(const MethodChannel('tally/sms'), (c) async => <Object>[]);
  });

  tearDown(() => db.close());

  Future<void> shot(WidgetTester t, Widget screen, String name, {Brightness b = Brightness.light}) async {
    t.view.physicalSize = const Size(1080, 2340);
    t.view.devicePixelRatio = 2.75;
    addTearDown(t.view.reset);
    final auth = Auth()..unlock();
    final router = GoRouter(routes: [GoRoute(path: '/', builder: (_, _) => screen)]);
    await t.pumpWidget(ProviderScope(
      overrides: [
        settingsProvider.overrideWith((_) => settings),
        authProvider.overrideWith((_) => auth),
        dbProvider.overrideWithValue(db),
        entriesProvider.overrideWith((_) => Stream.value(entries)),
        cyclesProvider.overrideWith((_) => Stream.value(cycles)),
        bankSmsProvider.overrideWith((_) => Stream.value(sms)),
      ],
      child: MaterialApp.router(theme: buildTheme(b), debugShowCheckedModeBanner: false, routerConfig: router),
    ));
    for (var k = 0; k < 6; k++) {
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 60)));
      await t.pump(const Duration(milliseconds: 100));
    }
    await t.pump(const Duration(seconds: 2)); // let entrance animations finish
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('$out/$name.png'));
    await t.pumpWidget(const SizedBox());
  }

  testWidgets('lock', (t) => shot(t, const LockScreen(), 'lock'));
  testWidgets('home', (t) => shot(t, const HomeScreen(), 'home'));
  testWidgets('home dark', (t) => shot(t, const HomeScreen(), 'home-dark', b: Brightness.dark));
  testWidgets('add income', (t) => shot(t, const AddEntryScreen(args: AddArgs(income: true, amount: 3000000, kind: IncomeKind.salary)), 'add-income'));
  testWidgets('add spending', (t) => shot(t, const AddEntryScreen(args: AddArgs(income: false, amount: 640000)), 'add-spending'));
  testWidgets('history', (t) => shot(t, const HistoryScreen(), 'history'));
  testWidgets('report', (t) => shot(t, ReportScreen(startMillis: cycles[1].startDate.millisecondsSinceEpoch), 'report'));
  testWidgets('big picture', (t) => shot(t, const BigPictureScreen(), 'big-picture'));
  testWidgets('bank sms', (t) => shot(t, const BankSmsScreen(), 'bank-sms'));
  testWidgets('settings', (t) => shot(t, const SettingsScreen(), 'settings'));
  testWidgets('recurring', (t) => shot(t, const RecurringScreen(), 'recurring'));
}
