import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tally/app/providers.dart';
import 'package:tally/data/db.dart';
import 'package:tally/features/report/pdf_report.dart';

var _id = 0;
Entry inc(int rs, String kind, DateTime d, {String? src}) => Entry(
    id: ++_id, kind: EntryKind.income, amount: rs * 100, incomeKind: kind, source: src, title: src, date: d,
    unexpected: false, yearly: false, createdAt: d);
Entry out(int rs, DateTime d, {DateTime? end, String? title, bool unexpected = false, String? reason, bool yearly = false}) => Entry(
    id: ++_id, kind: EntryKind.spending, amount: rs * 100, title: title, date: d, endDate: end,
    unexpected: unexpected, reason: reason, yearly: yearly, createdAt: d);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('render pdf', () async {
    await initializeDateFormatting('en_IN');
    final views = <CycleView>[];
    final all = <Entry>[];
    final months = [(5, 29500, 0), (6, 31800, 2000), (7, 31000, 0), (8, 40100, 10000), (9, 33200, 0)];
    for (final m in months) {
      final s = DateTime(2026, m.$1, 3), e = DateTime(2026, m.$1 + 1, 2);
      final es = [inc(30000, IncomeKind.salary, s, src: 'Salary'), if (m.$3 > 0) inc(m.$3, IncomeKind.help, s.add(const Duration(days: 10)), src: 'Dad'), out(m.$2, s, end: e)];
      if (m.$1 == 8) { es.removeLast(); es.addAll([out(30100, s, end: e), out(10000, DateTime(2026, 8, 14), title: 'Bike insurance', unexpected: true, reason: 'insurance', yearly: true)]); }
      all.addAll(es);
      views.insert(0, CycleView(null, s, e, es));
    }
    final s = DateTime(2026, 10, 3), e = DateTime(2026, 11, 2);
    final cur = [
      inc(30000, IncomeKind.salary, s, src: 'Salary'),
      inc(2500, IncomeKind.extra, DateTime(2026, 10, 12), src: 'Dad'),
      inc(1500, IncomeKind.extra, DateTime(2026, 10, 18), src: 'Amazon refund'),
      out(9000, s, title: 'Rent'),
      out(6200, s, end: DateTime(2026, 10, 9)),
      out(7100, DateTime(2026, 10, 10), end: DateTime(2026, 10, 19)),
      out(8900, DateTime(2026, 10, 20), end: e),
    ];
    all.addAll(cur);
    final v = CycleView(null, s, e, cur);
    final bytes = await buildReportPdf(v, views, all, 9600 * 100 - 3500 * 100, DateTime(2026, 5, 1));
    File(Platform.environment['OUT']!).writeAsBytesSync(bytes);
  });
}
