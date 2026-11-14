// Web preview of Tally: the real app's screens, run in a browser with sample
// data. Build with `flutter build web -t lib/main_preview.dart`. The Android
// app does not use this file.
//
// What a browser can't do is faked or switched off here: the database lives
// in memory (a reload starts over), bank SMS are sample messages, there is no
// fingerprint unlock and no notifications. The lock PIN is 1234.
import 'package:drift/drift.dart' show Value;
import 'package:drift/wasm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqlite3/wasm.dart';

import 'app/providers.dart';
import 'app/router.dart';
import 'data/db.dart';
import 'data/repo.dart';
import 'data/settings.dart';
import 'features/auth/auth.dart';
import 'main.dart' show TallyApp;

const _rupee = 100; // amounts are stored in paise

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('en_IN');

  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();
  final settings = Settings(prefs);
  final today = DateTime.now();
  final day = DateTime(today.year, today.month, today.day);
  await settings.completeSetup(startingBalance: 18500 * _rupee, cycleDay: 1);
  await prefs.setInt('startingDate', DateTime(day.year, day.month - 2, 1).millisecondsSinceEpoch);
  await settings.setUsualSalary(52000 * _rupee);
  await settings.setSmsEnabled(true);
  await settings.setReportNotify(false);

  final sqlite = await WasmSqlite3.loadFromUrl(Uri.parse('sqlite3.wasm'));
  sqlite.registerVirtualFileSystem(InMemoryFileSystem(), makeDefault: true);
  final db = AppDb(WasmDatabase.inMemory(sqlite));
  final repo = Repo(db, settings);
  await _seed(repo, day);
  await repo.rollCycles();

  final auth = Auth();
  try {
    await auth.setSecret('1234');
  } catch (_) {}
  auth.unlock();

  runApp(ProviderScope(
    overrides: [
      settingsProvider.overrideWith((_) => settings),
      authProvider.overrideWith((_) => auth),
      dbProvider.overrideWithValue(db),
    ],
    child: TallyApp(router: buildRouter(settings, auth)),
  ));
}

DateTime _on(DateTime month, int d) => DateTime(month.year, month.month, d);

Future<void> _seed(Repo repo, DateTime today) async {
  Future<void> income(DateTime date, int rupees, String kind, [String? title]) => repo.addEntry(
        EntriesCompanion.insert(
          kind: EntryKind.income,
          amount: rupees * _rupee,
          incomeKind: Value(kind),
          title: Value(title),
          date: date,
        ),
      );
  Future<void> spend(DateTime from, DateTime to, int rupees, {String? title, String? reason}) => repo.addEntry(
        EntriesCompanion.insert(
          kind: EntryKind.spending,
          amount: rupees * _rupee,
          title: Value(title),
          date: from,
          endDate: Value(to),
          unexpected: Value(reason != null),
          reason: Value(reason),
        ),
      );

  // Two finished months and the current one, so history and reports have something to show.
  for (var back = 2; back >= 0; back--) {
    final m = DateTime(today.year, today.month - back, 1);
    final last = back == 0 ? today : DateTime(m.year, m.month + 1, 0);
    await income(_on(m, 1), 52000, IncomeKind.salary);
    if (last.day >= 10) await spend(_on(m, 1), _on(m, 10), 14200 - back * 900, title: 'Rent and groceries');
    if (last.day >= 20) await spend(_on(m, 11), _on(m, 20), 9800 + back * 600, title: 'Daily spending');
    if (back > 0) await spend(_on(m, 21), last, 11300, title: 'Daily spending');
    if (back == 2) await spend(_on(m, 14), _on(m, 14), 6400, title: 'Bike service', reason: 'vehicle');
    if (back == 1) {
      await income(_on(m, 18), 7500, IncomeKind.extra, 'Freelance design');
      await spend(_on(m, 23), _on(m, 23), 3200, title: 'Doctor visit', reason: 'medical');
    }
  }
  if (today.day >= 5) await income(_on(today, 5), 4000, IncomeKind.help, 'From family');

  // Sample bank messages standing in for the phone's SMS inbox.
  final sms = [
    ('HDFCBK', 'debit', 1249, 'Swiggy', 'Rs.1249.00 debited from a/c **4821 on {d} to VPA swiggy@icici (UPI Ref 4318). Not you? Call 18002586161'),
    ('SBIINB', 'credit', 2500, 'Rahul K', 'Your A/c XX7710 credited by Rs.2,500.00 on {d} from Rahul K (UPI Ref 4319).'),
    ('HDFCBK', 'debit', 480, 'Uber India', 'Rs.480.00 debited from a/c **4821 on {d} to VPA uber@axis (UPI Ref 4320).'),
    ('ICICIB', 'debit', 2199, 'Amazon', 'INR 2,199.00 spent on ICICI Card XX9032 on {d} at Amazon. Avl Lmt: INR 61,200'),
  ];
  final rows = <BankSmsCompanion>[];
  for (var i = 0; i < sms.length; i++) {
    final (sender, dir, amount, who, text) = sms[i];
    final at = today.subtract(Duration(days: i, hours: 3 + i));
    final d = '${at.day.toString().padLeft(2, '0')}-${at.month.toString().padLeft(2, '0')}-${at.year % 100}';
    rows.add(BankSmsCompanion.insert(
      refNo: 'PREVIEW${4318 + i}',
      direction: dir,
      amount: amount * _rupee,
      account: Value(sender == 'SBIINB' ? 'XX7710' : sender == 'ICICIB' ? 'XX9032' : '4821'),
      counterparty: Value(who),
      sender: sender,
      receivedAt: at,
      rawText: text.replaceAll('{d}', d),
    ));
  }
  await repo.insertBankSms(rows);
}
