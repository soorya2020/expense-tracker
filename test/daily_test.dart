import 'package:flutter_test/flutter_test.dart';
import 'package:tally/data/daily.dart';
import 'package:tally/data/db.dart';

Entry _e(int id, String kind, int rupees, DateTime d, {DateTime? to, String? title, String? incomeKind, String? category, String? tag}) => Entry(
      id: id,
      kind: kind,
      amount: rupees * 100,
      incomeKind: incomeKind,
      title: title,
      date: d,
      endDate: to,
      category: category,
      tag: tag,
      unexpected: false,
      yearly: false,
      createdAt: d,
    );

void main() {
  final s = DateTime(2026, 11, 3), e = DateTime(2026, 12, 2);
  test('spreads lumps over their days and keeps rent out of the average', () {
    final d = DailySpend.of([
      _e(1, EntryKind.income, 30000, s, incomeKind: IncomeKind.salary),
      _e(2, EntryKind.spending, 9000, s, title: 'Rent'),
      _e(3, EntryKind.spending, 1000, DateTime(2026, 11, 4), to: DateTime(2026, 11, 8)),
    ], s, e, DateTime(2026, 11, 12));
    expect(d.length, 30);
    expect(d.dayNumber, 10);
    expect(d.daily[1], 20000);
    expect(d.fixed[0], 900000);
    expect(d.average, 10000); // ₹1,000 over 10 days
    expect(d.left, 2000000);
    expect(d.perDayLeft, 2000000 ~/ 20);
    expect(d.pace, Pace.onTrack);
  });

  test('past salary and no salary', () {
    final over = DailySpend.of([
      _e(1, EntryKind.income, 1000, s, incomeKind: IncomeKind.salary),
      _e(2, EntryKind.spending, 2000, s),
    ], s, e, DateTime(2026, 11, 5));
    expect(over.pace, Pace.pastSalary);
    expect(DailySpend.of(const [], s, e, DateTime(2026, 11, 5)).pace, Pace.noSalary);
      });

  test('extra income and a remembered salary do not count as this cycle\'s salary', () {
    final d = DailySpend.of([
      _e(1, EntryKind.income, 5000, s, incomeKind: IncomeKind.extra),
      _e(2, EntryKind.spending, 2485, DateTime(2026, 11, 10)),
    ], s, e, DateTime(2026, 11, 16));
    expect(d.salary, 0);
    expect(d.salaryUsed, 0);
    expect(d.pace, Pace.noSalary);
    expect(d.perDayLeft, 0);
  });

  test('splits each day by category and keeps what made it up', () {
    final d = DailySpend.of([
      _e(1, EntryKind.spending, 210, DateTime(2026, 11, 4), title: 'Swiggy'),
      _e(2, EntryKind.spending, 85, DateTime(2026, 11, 4), title: 'Pay 98450', tag: 'travel'),
      _e(3, EntryKind.spending, 60, DateTime(2026, 11, 4), title: 'Shop 12'),
      _e(4, EntryKind.spending, 500, DateTime(2026, 11, 5), to: DateTime(2026, 11, 9), title: 'Market', tag: 'groceries'),
      _e(5, EntryKind.spending, 9000, DateTime(2026, 11, 5), title: 'Rent'),
    ], s, e, DateTime(2026, 11, 12), rules: const {'shop 12': 'food'});
    expect(d.byCat[1], {'food': 27000.0, 'travel': 8500.0});
    expect(d.items[1].map((x) => x.entry.title), ['Swiggy', 'Pay 98450', 'Shop 12']);
    expect(d.byCat[2], {'groceries': 10000.0});
    expect(d.items[2].firstWhere((x) => x.fixed).entry.title, 'Rent');
    expect(d.items[3].single.spread, isTrue);
    expect(d.catOrder, ['groceries', 'food', 'travel']);
  });

  test('untagged spending stacks last', () {
    final d = DailySpend.of([
      _e(1, EntryKind.spending, 900, DateTime(2026, 11, 4), title: 'Cash'),
      _e(2, EntryKind.spending, 100, DateTime(2026, 11, 4), title: 'Swiggy'),
    ], s, e, DateTime(2026, 11, 12));
    expect(d.catOrder, ['food', null]);
  });
}
