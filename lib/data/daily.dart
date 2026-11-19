import '../core/cycle_math.dart';
import 'categories.dart';
import 'db.dart';
import 'repo.dart';

/// Rent, bills, repayments and one-off hits. They are kept out of the daily average.
bool isFixedSpend(Entry e) =>
    e.category == 'recurring' ||
    e.category == 'repayment' ||
    e.unexpected ||
    (e.title?.toLowerCase().contains('rent') ?? false);

enum Pace { onTrack, bitFast, tooFast, pastSalary, noSalary }

/// One entry's share of a day. A lump spread over 5 days gives a fifth to each.
class DayItem {
  const DayItem(this.entry, this.cat, this.amount, this.fixed);
  final Entry entry;

  /// Category id, or null when untagged.
  final String? cat;

  /// Paise counted on this day.
  final double amount;

  /// Rent, bills and one-offs, which stay out of the daily average.
  final bool fixed;

  /// True when the entry is spread over more than one day.
  bool get spread => entry.endDate != null && dateOnly(entry.endDate!) != dateOnly(entry.date);
}

/// Spending per day of a pay cycle, for the chart on Home. All amounts in paise.
class DailySpend {
  DailySpend._(this.length, this.dayNumber, this.daily, this.fixed, this.fixedLabel, this.byCat, this.items, this.salary, this.spent);

  /// [rules] are the "Always tag" choices, used to guess categories the way
  /// "Where it went" does.
  factory DailySpend.of(List<Entry> entries, DateTime start, DateTime end, DateTime today, {Map<String, String> rules = const {}}) {
    final s = dateOnly(start), e = dateOnly(end);
    final length = daysBetweenInclusive(s, e);
    final dayNumber = daysBetweenInclusive(s, dateOnly(today)).clamp(1, length);
    final daily = List<double>.filled(length, 0), fixed = List<double>.filled(length, 0);
    final label = List<String?>.filled(length, null);
    final byCat = List.generate(length, (_) => <String?, double>{});
    final items = List.generate(length, (_) => <DayItem>[]);
    var salary = 0, spent = 0;
    for (final x in entries) {
      if (isIncome(x)) {
        if (x.incomeKind == IncomeKind.salary) salary += x.amount;
        continue;
      }
      spent += x.amount;
      final a = dateOnly(x.date), b = dateOnly(x.endDate ?? x.date);
      final days = daysBetweenInclusive(a, b).clamp(1, 1000);
      final per = x.amount / days;
      final isFixed = isFixedSpend(x);
      final cat = entryCat(x, rules);
      for (var d = 0; d < days; d++) {
        final i = daysBetweenInclusive(s, a.add(Duration(days: d))) - 1;
        if (i < 0 || i >= length) continue;
        items[i].add(DayItem(x, cat, per, isFixed));
        if (isFixed) {
          fixed[i] += per;
          label[i] ??= x.title;
        } else {
          daily[i] += per;
          byCat[i][cat] = (byCat[i][cat] ?? 0) + per;
        }
      }
    }
    for (final l in items) {
      l.sort((a, b) => b.amount.compareTo(a.amount));
    }
    return DailySpend._(length, dayNumber, daily, fixed, label, byCat, items, salary, spent);
  }

  final int length, dayNumber;
  final List<double> daily, fixed;
  final List<String?> fixedLabel;

  /// Day-to-day spending of each day by category id (null = untagged).
  final List<Map<String?, double>> byCat;

  /// What made up each day, biggest first, rent and bills included.
  final List<List<DayItem>> items;

  /// Categories in this cycle's day-to-day spending, biggest first, untagged last.
  /// Bars stack in this order so each colour sits in the same place every day.
  List<String?> get catOrder {
    final t = <String?, double>{};
    for (final m in byCat) {
      for (final e in m.entries) {
        t[e.key] = (t[e.key] ?? 0) + e.value;
      }
    }
    final ids = t.keys.where((k) => k != null && t[k]! > 0).toList()..sort((a, b) => t[b]!.compareTo(t[a]!));
    return [...ids, if ((t[null] ?? 0) > 0) null];
  }

  /// Salary logged in this cycle. Zero until it is logged: the usual salary is
  /// only a guess, and using it here made "salary used" show a percentage of a
  /// salary the person hadn't added.
  final int salary;
  final int spent;

  double get fixedTotal => fixed.fold(0.0, (a, b) => a + b);
  double get dailyTotal => daily.take(dayNumber).fold(0.0, (a, b) => a + b);

  /// Day-to-day spending per day so far.
  int get average => (dailyTotal / dayNumber).round();

  int get left => salary - spent;
  int get daysLeft => (length - dayNumber).clamp(1, length);

  /// What you can spend each remaining day and stay inside your salary.
  int get perDayLeft => left <= 0 ? 0 : left ~/ daysLeft;

  double get salaryUsed => salary <= 0 ? 0 : (spent / salary).clamp(0.0, 1.0);

  Pace get pace {
    if (salary <= 0) return Pace.noSalary;
    if (left <= 0) return Pace.pastSalary;
    if (average <= perDayLeft) return Pace.onTrack;
    if (average <= perDayLeft * 1.2) return Pace.bitFast;
    return Pace.tooFast;
  }
}
