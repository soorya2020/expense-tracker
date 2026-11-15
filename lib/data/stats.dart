import '../core/cycle_math.dart';
import 'db.dart';
import 'repo.dart';

/// Totals for one stretch of dates (normally one pay cycle). All in paise.
class Stats {
  Stats(this.entries);
  final List<Entry> entries;

  int _sum(bool Function(Entry) f) => entries.where(f).fold(0, (a, e) => a + e.amount);

  int get salary => _sum((e) => isIncome(e) && e.incomeKind == IncomeKind.salary);
  int get extra => _sum((e) => isIncome(e) && e.incomeKind == IncomeKind.extra);
  int get help => _sum((e) => isIncome(e) && e.incomeKind == IncomeKind.help);
  int get borrowed => _sum((e) => isIncome(e) && e.incomeKind == IncomeKind.borrowed);
  int get income => _sum(isIncome);
  int get spent => _sum((e) => !isIncome(e));
  int get unexpected => _sum((e) => !isIncome(e) && e.unexpected);
  int get regular => spent - unexpected;
  int get net => income - spent;
  int get overSalary => spent - salary;
  bool get hasSalary => entries.any((e) => isIncome(e) && e.incomeKind == IncomeKind.salary);

  /// Money that came from outside your pay.
  int get outside => extra + help + borrowed;

  Entry? get biggestSpend {
    final s = entries.where((e) => !isIncome(e)).toList()..sort((a, b) => b.amount.compareTo(a.amount));
    return s.isEmpty ? null : s.first;
  }

  /// Who gave the most extra / help money, by name.
  ({String name, int amount})? topSource(String kind) {
    final m = <String, int>{};
    for (final e in entries.where((e) => isIncome(e) && e.incomeKind == kind)) {
      final k = (e.title?.trim().isNotEmpty ?? false) ? e.title!.trim() : IncomeKind.label(kind);
      m[k] = (m[k] ?? 0) + e.amount;
    }
    if (m.isEmpty) return null;
    final best = m.entries.reduce((a, b) => a.value >= b.value ? a : b);
    return (name: best.key, amount: best.value);
  }
}

List<Entry> entriesBetween(List<Entry> all, DateTime start, DateTime end) {
  final s = dateOnly(start), e = dateOnly(end);
  return all.where((x) {
    final d = effectiveDate(x);
    return !d.isBefore(s) && !d.isAfter(e);
  }).toList();
}

/// Starting balance plus everything logged since setup.
int balance(List<Entry> all, int startingBalance, DateTime startingDate) {
  final from = dateOnly(startingDate);
  var b = startingBalance;
  for (final e in all) {
    if (effectiveDate(e).isBefore(from)) continue; // already in the starting balance
    b += isIncome(e) ? e.amount : -e.amount;
  }
  return b;
}
