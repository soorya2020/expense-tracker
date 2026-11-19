import 'package:flutter_test/flutter_test.dart';
import 'package:tally/data/budgets.dart';

void main() {
  test('plans against this cycle\'s salary, or the usual one before it comes in', () {
    expect(planSalary(cycleSalary: 2600000, usualSalary: 2500000), 2600000);
    expect(planSalary(cycleSalary: 0, usualSalary: 2500000), 2500000);
    expect(planSalary(cycleSalary: 0, usualSalary: 0), 0);
  });

  test('shows what is free and when budgets pass the salary', () {
    final caps = {'food': 500000, 'groceries': 400000, 'travel': 200000, 'shopping': 300000, 'bills': 600000, 'fuel': 200000};
    final fits = SalaryPlan(2500000, caps);
    expect(fits.planned, 2200000);
    expect(fits.free, 300000);
    expect(fits.over, isFalse);
    expect(fits.share, closeTo(.88, 1e-9));

    final over = SalaryPlan(2500000, {...caps, 'health': 500000});
    expect(over.free, -200000);
    expect(over.over, isTrue);

    final none = SalaryPlan(0, caps);
    expect(none.hasSalary, isFalse);
    expect(none.over, isFalse);
  });

  test('room for a budget leaves the others as they are', () {
    final caps = {'food': 500000, 'bills': 600000};
    expect(SalaryPlan.roomFor(2500000, caps, 'food'), 1900000);
    expect(SalaryPlan.roomFor(2500000, caps, 'health'), 1400000);
  });
}
