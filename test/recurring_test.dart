import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tally/core/cycle_math.dart';
import 'package:tally/data/backup.dart';
import 'package:tally/data/db.dart';
import 'package:tally/data/recurring.dart';
import 'package:tally/data/repo.dart';
import 'package:tally/data/settings.dart';

RecurringRule rule(int day, {bool income = false}) =>
    RecurringRule(id: '$day', income: income, title: 'Rent', amount: 900000, day: day);

void main() {
  test('due date inside a cycle that spans two months', () {
    final s = DateTime(2026, 11, 3), e = DateTime(2026, 12, 2);
    expect(dueIn(rule(10), s, e), DateTime(2026, 11, 10));
    expect(dueIn(rule(1), s, e), DateTime(2026, 12, 1));
    expect(dueIn(rule(lastDay), s, e), DateTime(2026, 11, 30));
  });

  test('recurring entries are added once per cycle, and backups round-trip', () async {
    SharedPreferences.setMockInitialValues({'setupDone': true, 'cycleDay': 1, 'startingDate': 0});
    final settings = await Settings.load();
    final db = AppDb(NativeDatabase.memory());
    final repo = Repo(db, settings);
    await repo.rollCycles();
    final today = dateOnly(DateTime.now());
    await saveRules(settings, [rule(1), rule(28)]);
    final added = await applyRecurring(repo, settings);
    expect(added, today.day >= 28 ? 2 : 1);
    expect(await applyRecurring(repo, settings), 0); // not twice
    final n = (await repo.allEntries()).length;

    final json = jsonEncode(await buildBackup(db, settings));
    await db.delete(db.entries).go();
    await restoreBackup(db, settings, readBackup(utf8.encode(json)));
    expect((await repo.allEntries()).length, n);
    expect(loadRules(settings).length, 2);
    await db.close();
  });
}
