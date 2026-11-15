import 'dart:convert';

import 'package:drift/drift.dart' show Value;

import '../core/cycle_math.dart';
import 'db.dart';
import 'repo.dart';
import 'settings.dart';

/// Something that comes in or goes out every month: salary, rent, an EMI.
class RecurringRule {
  RecurringRule({
    required this.id,
    required this.income,
    required this.title,
    required this.amount,
    required this.day,
    this.kind,
    this.remind = true,
    this.lastCycle,
  });
  final String id;
  final bool income;
  final String title;
  final int amount; // paise
  final int day; // 1-28, or 0 for the last day of the month
  final String? kind; // income kind
  final bool remind; // reminder the day before (spending only)
  final int? lastCycle; // start (ms) of the cycle it was last added in

  Map<String, Object?> toJson() =>
      {'id': id, 'income': income, 'title': title, 'amount': amount, 'day': day, 'kind': kind, 'remind': remind, 'lastCycle': lastCycle};

  factory RecurringRule.fromJson(Map<String, dynamic> j) => RecurringRule(
        id: j['id'] as String,
        income: j['income'] as bool? ?? false,
        title: j['title'] as String? ?? '',
        amount: (j['amount'] as num?)?.toInt() ?? 0,
        day: (j['day'] as num?)?.toInt() ?? 1,
        kind: j['kind'] as String?,
        remind: j['remind'] as bool? ?? true,
        lastCycle: (j['lastCycle'] as num?)?.toInt(),
      );

  RecurringRule copyWith({int? lastCycle}) => RecurringRule(
      id: id, income: income, title: title, amount: amount, day: day, kind: kind, remind: remind, lastCycle: lastCycle ?? this.lastCycle);
}

List<RecurringRule> loadRules(Settings s) {
  try {
    return (jsonDecode(s.recurringJson) as List<dynamic>).map((e) => RecurringRule.fromJson(e as Map<String, dynamic>)).toList();
  } catch (_) {
    return [];
  }
}

Future<void> saveRules(Settings s, List<RecurringRule> rules) => s.setRecurringJson(jsonEncode(rules.map((r) => r.toJson()).toList()));

bool _isDay(DateTime d, int day) {
  if (day == 0) return d.add(const Duration(days: 1)).day == 1;
  return d.day == day;
}

/// The day [rule] falls on inside the cycle [start]..[end].
DateTime dueIn(RecurringRule rule, DateTime start, DateTime end) {
  for (var d = dateOnly(start); !d.isAfter(end); d = DateTime(d.year, d.month, d.day + 1)) {
    if (_isDay(d, rule.day)) return d;
  }
  return dateOnly(start);
}

/// The pay cycle that contains today.
Future<(DateTime, DateTime)> currentCycle(Repo repo, Settings settings) async {
  final today = dateOnly(DateTime.now());
  for (final c in await repo.allCycles()) {
    if (!today.isBefore(dateOnly(c.startDate)) && !today.isAfter(dateOnly(c.endDate))) {
      return (dateOnly(c.startDate), dateOnly(c.endDate));
    }
  }
  final s = cycleStartOnOrBefore(today, settings.cycleDay);
  return (s, cycleEndFor(s, settings.cycleDay));
}

/// The next date [rule] will be added, from today on.
Future<DateTime> nextDue(RecurringRule rule, Repo repo, Settings settings) async {
  final (start, end) = await currentCycle(repo, settings);
  final due = dueIn(rule, start, end);
  final today = dateOnly(DateTime.now());
  if (!due.isBefore(today) && rule.lastCycle != start.millisecondsSinceEpoch) return due;
  final nextStart = end.add(const Duration(days: 1));
  return dueIn(rule, nextStart, cycleEndFor(nextStart, settings.cycleDay));
}

/// A new rule starts with its next date. If this cycle's date has already
/// passed, it waits for the next cycle so nothing you logged by hand is doubled.
Future<RecurringRule> startRule(RecurringRule r, Repo repo, Settings settings) async {
  final (start, end) = await currentCycle(repo, settings);
  final due = dueIn(r, start, end);
  return due.isBefore(dateOnly(DateTime.now())) ? r.copyWith(lastCycle: start.millisecondsSinceEpoch) : r;
}

/// Adds every recurring entry that is due in this cycle and not added yet.
/// Returns how many were added.
Future<int> applyRecurring(Repo repo, Settings settings) async {
  final rules = loadRules(settings);
  if (rules.isEmpty) return 0;
  final (start, end) = await currentCycle(repo, settings);
  final today = dateOnly(DateTime.now());
  final key = start.millisecondsSinceEpoch;
  var added = 0;
  final out = <RecurringRule>[];
  for (final r in rules) {
    final due = dueIn(r, start, end);
    if (r.lastCycle != key && !due.isAfter(today) && r.amount > 0) {
      await repo.addEntry(EntriesCompanion.insert(
        kind: r.income ? EntryKind.income : EntryKind.spending,
        amount: r.amount,
        incomeKind: Value(r.income ? (r.kind ?? IncomeKind.salary) : null),
        title: Value(r.title.isEmpty ? null : r.title),
        category: const Value('recurring'),
        date: due,
      ));
      out.add(r.copyWith(lastCycle: key));
      added++;
    } else {
      out.add(r);
    }
  }
  if (added > 0) await saveRules(settings, out);
  return added;
}
