import '../core/cycle_math.dart';
import 'db.dart';
import 'repo.dart';

/// Rent, bills, repayments and one-off hits. They are kept out of the daily average.
bool isFixedSpend(Entry e) =>
    e.category == 'recurring' ||
    e.category == 'repayment' ||
    e.unexpected ||
    (e.title?.toLowerCase().contains('rent') ?? false);

enum Pace { onTrack, bitFast, tooFast, pastSalary, noSalary }

/// Spending per day of a pay cycle, for the chart on Home. All amounts in paise.
class DailySpend {
  DailySpend._(this.length, this.dayNumber, this.daily, this.fixed, this.fixedLabel, this.salary, this.spent);

  factory DailySpend.of(List<Entry> entries, DateTime start, DateTime end, DateTime today) {
    final s = dateOnly(start), e = dateOnly(end);
    final length = daysBetweenInclusive(s, e);
    final dayNumber = daysBetweenInclusive(s, dateOnly(today)).clamp(1, length);
    final daily = List<double>.filled(length, 0), fixed = List<double>.filled(length, 0);
    final label = List<String?>.filled(length, null);
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
      for (var d = 0; d < days; d++) {
        final i = daysBetweenInclusive(s, a.add(Duration(days: d))) - 1;
        if (i < 0 || i >= length) continue;
        if (isFixed) {
          fixed[i] += per;
          label[i] ??= x.title;
        } else {
          daily[i] += per;
        }
      }
    }
    return DailySpend._(length, dayNumber, daily, fixed, label, salary, spent);
  }

  final int length, dayNumber;
  final List<double> daily, fixed;
  final List<String?> fixedLabel;

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
