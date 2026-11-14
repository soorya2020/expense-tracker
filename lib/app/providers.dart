import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../core/cycle_math.dart';
import '../data/db.dart';
import '../data/repo.dart';
import '../data/settings.dart';
import '../data/stats.dart';
import '../features/auth/auth.dart';

/// Overridden in main() once loaded.
final settingsProvider = ChangeNotifierProvider<Settings>((_) => throw UnimplementedError());
final authProvider = ChangeNotifierProvider<Auth>((_) => throw UnimplementedError());
final dbProvider = Provider<AppDb>((_) => throw UnimplementedError());

final repoProvider = Provider<Repo>((ref) => Repo(ref.watch(dbProvider), ref.read(settingsProvider)));

final entriesProvider = StreamProvider<List<Entry>>((ref) => ref.watch(repoProvider).watchEntries());
final bankSmsProvider = StreamProvider<List<BankMessage>>((ref) => ref.watch(repoProvider).watchBankSms());
final cyclesProvider = StreamProvider<List<Cycle>>((ref) => ref.watch(repoProvider).watchCycles());

/// A pay cycle with its entries and totals.
class CycleView {
  CycleView(this.cycle, this.start, this.end, this.entries) : stats = Stats(entries);
  final Cycle? cycle; // null for cycles from before the app was set up
  final DateTime start, end;
  final List<Entry> entries;
  final Stats stats;

  bool get isCurrent {
    final t = dateOnly(DateTime.now());
    return !t.isBefore(start) && !t.isAfter(end);
  }

  int get length => daysBetweenInclusive(start, end);
  int get dayNumber => daysBetweenInclusive(start, DateTime.now()).clamp(1, length);

  /// Supported when Help came in, unless you changed it by hand.
  bool get supported => cycle?.supported ?? stats.help > 0;
}

/// Every cycle that has entries or is stored, newest first.
final cycleViewsProvider = Provider<List<CycleView>>((ref) {
  final entries = ref.watch(entriesProvider).value ?? const [];
  final cycles = ref.watch(cyclesProvider).value ?? const [];
  final day = ref.watch(settingsProvider.select((s) => s.cycleDay));
  final views = <CycleView>[
    for (final c in cycles) CycleView(c, c.startDate, c.endDate, entriesBetween(entries, c.startDate, c.endDate)),
  ];
  // Entries older than the first stored cycle get cycles worked out from today's start day.
  final firstStart = cycles.isEmpty ? null : cycles.last.startDate;
  final older = firstStart == null ? entries : entries.where((e) => effectiveDate(e).isBefore(firstStart)).toList();
  final extra = <DateTime, List<Entry>>{};
  for (final e in older) {
    final s = cycleStartOnOrBefore(effectiveDate(e), day);
    (extra[s] ??= []).add(e);
  }
  for (final s in extra.keys) {
    var end = cycleEndFor(s, day);
    if (firstStart != null && !end.isBefore(firstStart)) end = firstStart.subtract(const Duration(days: 1));
    views.add(CycleView(null, s, end, extra[s]!));
  }
  views.sort((a, b) => b.start.compareTo(a.start));
  return views;
});

final currentCycleProvider = Provider<CycleView?>((ref) {
  final v = ref.watch(cycleViewsProvider);
  for (final c in v) {
    if (c.isCurrent) return c;
  }
  return v.isEmpty ? null : v.first;
});

final balanceProvider = Provider<int>((ref) {
  final entries = ref.watch(entriesProvider).value ?? const [];
  final s = ref.watch(settingsProvider);
  return balance(entries, s.startingBalance, s.startingDate);
});
