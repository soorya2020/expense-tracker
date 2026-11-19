import 'dart:convert';

import 'categories.dart';
import 'db.dart';
import 'repo.dart';
import 'settings.dart';

/// Monthly caps per category, in paise.
Map<String, int> loadBudgets(Settings s) => (jsonDecode(s.budgetsJson) as Map).map((k, v) => MapEntry(k as String, (v as num).toInt()));

Future<void> setBudget(Settings s, String catId, int? paise) async {
  final m = loadBudgets(s);
  if (paise == null || paise <= 0) {
    m.remove(catId);
  } else {
    m[catId] = paise;
  }
  await s.setBudgetsJson(jsonEncode(m));
}

/// The salary budgets are planned against: this cycle's salary once it has come in,
/// otherwise the usual salary Tally learned from earlier ones. 0 when there is none yet.
int planSalary({required int cycleSalary, required int usualSalary}) => cycleSalary > 0 ? cycleSalary : usualSalary;

/// How a set of budgets fits inside a salary. All in paise.
class SalaryPlan {
  SalaryPlan(this.salary, Map<String, int> caps) : planned = caps.values.fold(0, (a, v) => a + v);
  final int salary, planned;

  bool get hasSalary => salary > 0;

  /// Salary not yet given to a budget. Negative when the budgets add up to more than the salary.
  int get free => salary - planned;
  bool get over => hasSalary && planned > salary;
  double get share => hasSalary ? planned / salary : 0;

  /// The most [catId] can have before the budgets pass the salary, keeping every other budget as it is.
  static int roomFor(int salary, Map<String, int> caps, String catId) =>
      salary - caps.entries.where((e) => e.key != catId).fold(0, (a, e) => a + e.value);
}

/// Spending per category in [entries] (one cycle). Untagged spending is under null.
Map<String?, int> spendByCat(List<Entry> entries, Map<String, String> rules) {
  final m = <String?, int>{};
  for (final e in entries) {
    if (isIncome(e)) continue;
    final c = entryCat(e, rules);
    m[c] = (m[c] ?? 0) + e.amount;
  }
  return m;
}

enum BudgetState { fine, near, over }

class BudgetLine {
  BudgetLine(this.cat, this.spent, this.cap);
  final Cat cat;
  final int spent;
  final int? cap; // null = no budget set

  double get used => cap == null || cap == 0 ? 0 : spent / cap!;
  int get left => (cap ?? 0) - spent;
  BudgetState get state => cap == null
      ? BudgetState.fine
      : spent > cap!
          ? BudgetState.over
          : used >= .8
              ? BudgetState.near
              : BudgetState.fine;
}

/// Budgeted categories first (most used first), then categories with spending but no budget.
List<BudgetLine> budgetLines(Settings s, List<Entry> cycleEntries) {
  final rules = catRules(s), caps = loadBudgets(s), spent = spendByCat(cycleEntries, rules);
  final lines = <BudgetLine>[];
  for (final c in allCats(s)) {
    final cap = caps[c.id], sp = spent[c.id] ?? 0;
    if (cap != null || sp > 0) lines.add(BudgetLine(c, sp, cap));
  }
  lines.sort((a, b) {
    if ((a.cap == null) != (b.cap == null)) return a.cap == null ? 1 : -1;
    return a.cap == null ? b.spent.compareTo(a.spent) : b.used.compareTo(a.used);
  });
  return lines;
}

/// The budget most worth a nudge on Home: over, or past 80%, and not dismissed.
BudgetLine? nudgeLine(Settings s, List<Entry> cycleEntries, DateTime cycleStart) {
  final flags = s.budgetFlags.toSet();
  for (final l in budgetLines(s, cycleEntries)) {
    if (l.state == BudgetState.fine) continue;
    if (flags.contains(dismissFlag(cycleStart, l))) continue;
    return l;
  }
  return null;
}

String dismissFlag(DateTime start, BudgetLine l) => '${start.millisecondsSinceEpoch}:${l.cat.id}:${l.state.name}:x';
String alertFlag(DateTime start, BudgetLine l) => '${start.millisecondsSinceEpoch}:${l.cat.id}:${l.state.name}';
