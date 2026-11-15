import 'package:drift/drift.dart';

import '../core/cycle_math.dart';
import 'db.dart';
import 'settings.dart';

/// The date an entry counts on. Spending that covers a range counts on its
/// last day.
DateTime effectiveDate(Entry e) => dateOnly(e.endDate ?? e.date);

bool isIncome(Entry e) => e.kind == EntryKind.income;

/// Reads and writes entries and pay cycles.
class Repo {
  Repo(this.db, this.settings);
  final AppDb db;
  final Settings settings;

  // ---------- Bank SMS ----------

  Stream<List<BankMessage>> watchBankSms() =>
      (db.select(db.bankSms)..orderBy([(m) => OrderingTerm.desc(m.receivedAt)])).watch();

  Future<void> insertBankSms(List<BankSmsCompanion> rows) =>
      db.batch((b) => b.insertAll(db.bankSms, rows, mode: InsertMode.insertOrIgnore));

  Future<void> setSmsStatus(List<int> ids, String status, {int? entryId}) =>
      (db.update(db.bankSms)..where((m) => m.id.isIn(ids)))
          .write(BankSmsCompanion(status: Value(status), entryId: Value(entryId)));

  Future<void> setSmsTag(int id, String? tag) =>
      (db.update(db.bankSms)..where((m) => m.id.equals(id))).write(BankSmsCompanion(tag: Value(tag)));

  // ---------- Entries ----------

  Future<void> setEntryTag(int id, String? tag) =>
      (db.update(db.entries)..where((e) => e.id.equals(id))).write(EntriesCompanion(tag: Value(tag)));

  Stream<List<Entry>> watchEntries() {
    final q = db.select(db.entries)
      ..orderBy([
        (e) => OrderingTerm.desc(coalesce([e.endDate, e.date])),
        (e) => OrderingTerm.desc(e.createdAt),
      ]);
    return q.watch();
  }

  Future<List<Entry>> allEntries() => db.select(db.entries).get();

  Future<int> addEntry(EntriesCompanion e) => db.into(db.entries).insert(e);

  Future<void> updateEntry(Entry e) => db.update(db.entries).replace(e);

  Future<void> deleteEntry(int id) => (db.delete(db.entries)..where((e) => e.id.equals(id))).go();

  Future<void> restoreEntry(Entry e) => db.into(db.entries).insert(e, mode: InsertMode.insertOrReplace);

  /// Marks borrowed money as paid back and logs the repayment as spending.
  Future<void> markRepaid(Entry borrowed) async {
    await db.transaction(() async {
      await updateEntry(borrowed.copyWith(repaidAt: Value(DateTime.now())));
      await addEntry(EntriesCompanion.insert(
        kind: EntryKind.spending,
        amount: borrowed.amount,
        title: Value('Repaid ${borrowed.title ?? 'loan'}'),
        category: const Value('repayment'),
        date: dateOnly(DateTime.now()),
      ));
    });
  }

  Future<Entry?> entry(int id) =>
      (db.select(db.entries)..where((e) => e.id.equals(id))).getSingleOrNull();

  /// The most recent spending entry's last day, used for "Since last entry".
  Future<DateTime?> lastSpendingEnd() async {
    final q = db.select(db.entries)
      ..where((e) => e.kind.equals(EntryKind.spending))
      ..orderBy([(e) => OrderingTerm.desc(coalesce([e.endDate, e.date]))])
      ..limit(1);
    final r = await q.getSingleOrNull();
    return r == null ? null : effectiveDate(r);
  }

  // ---------- Cycles ----------

  Stream<List<Cycle>> watchCycles() =>
      (db.select(db.cycles)..orderBy([(c) => OrderingTerm.desc(c.startDate)])).watch();

  Future<List<Cycle>> allCycles() =>
      (db.select(db.cycles)..orderBy([(c) => OrderingTerm.desc(c.startDate)])).get();

  Future<void> updateCycle(Cycle c) => db.update(db.cycles).replace(c);

  /// Makes sure a cycle exists for today. Closes any that ended and opens the
  /// next ones. Returns the cycles that were closed, oldest first.
  Future<List<Cycle>> rollCycles({DateTime? now}) async {
    final today = dateOnly(now ?? DateTime.now());
    final day = settings.cycleDay;
    final closed = <Cycle>[];
    await db.transaction(() async {
      final list = await allCycles();
      if (list.isEmpty) {
        final start = cycleStartOnOrBefore(today, day);
        await db.into(db.cycles).insert(
              CyclesCompanion.insert(startDate: start, endDate: cycleEndFor(start, day)),
            );
        return;
      }
      var current = list.first;
      while (today.isAfter(current.endDate)) {
        if (current.closedAt == null) {
          current = current.copyWith(closedAt: Value(DateTime.now()));
          await db.update(db.cycles).replace(current);
          closed.add(current);
        }
        final start = current.endDate.add(const Duration(days: 1));
        final id = await db.into(db.cycles).insert(
              CyclesCompanion.insert(startDate: start, endDate: cycleEndFor(start, day)),
            );
        current = (await (db.select(db.cycles)..where((c) => c.id.equals(id))).getSingle());
      }
    });
    return closed;
  }

  /// Applies a new start day from the next cycle: the current cycle now ends
  /// the day before the new day next comes round.
  Future<void> changeCycleDay(int newDay) async {
    await settings.setCycleDay(newDay);
    final list = await allCycles();
    if (list.isEmpty) return;
    final cur = list.first;
    final today = dateOnly(DateTime.now());
    var nextStart = nextCycleStartAfter(today, newDay);
    if (!nextStart.isAfter(cur.startDate)) nextStart = nextCycleStartAfter(cur.startDate, newDay);
    await db.update(db.cycles).replace(cur.copyWith(endDate: nextStart.subtract(const Duration(days: 1))));
  }

  /// Salary came early or late, so a cycle starts on [start] instead.
  /// [early]: salary for the next cycle landed before the current one ended,
  /// so the current cycle is cut short and the next one starts now.
  /// Otherwise salary came late, so the current cycle starts later and the
  /// previous one is stretched to meet it.
  Future<void> shiftCycle(DateTime start, {required bool early}) async {
    start = dateOnly(start);
    final list = await allCycles();
    if (list.isEmpty) return;
    final cur = list.first;
    final day = settings.cycleDay;
    await db.transaction(() async {
      if (early) {
        final normalNextStart = cur.endDate.add(const Duration(days: 1));
        await db.update(db.cycles).replace(cur.copyWith(endDate: start.subtract(const Duration(days: 1))));
        await db.into(db.cycles).insert(
              CyclesCompanion.insert(startDate: start, endDate: cycleEndFor(normalNextStart, day)),
            );
      } else {
        if (list.length > 1) {
          await db.update(db.cycles).replace(list[1].copyWith(endDate: start.subtract(const Duration(days: 1))));
        }
        await db.update(db.cycles).replace(cur.copyWith(startDate: start));
      }
    });
  }
}
