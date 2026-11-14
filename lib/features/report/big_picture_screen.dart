import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/money.dart';
import '../../shared/widgets.dart';

/// The last 6 finished cycles: what life really costs against your salary.
class BigPictureScreen extends ConsumerWidget {
  const BigPictureScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.p;
    final all = ref.watch(cycleViewsProvider);
    final done = all.where((v) => !v.isCurrent && v.entries.isNotEmpty).take(6).toList().reversed.toList();
    if (done.length < 2) {
      return Scaffold(
        appBar: AppBar(leading: const BackButton()),
        body: Padding(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 40),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Big picture', style: T.title.copyWith(color: p.ink)),
            const SizedBox(height: 12),
            Text('This fills in after two finished cycles. It shows what your life really costs against your salary.',
                style: T.body.copyWith(color: p.muted, height: 1.5)),
          ]),
        ),
      );
    }
    final n = done.length;
    final avgSpent = done.fold(0, (a, v) => a + v.stats.spent) ~/ n;
    final salaried = done.where((v) => v.stats.salary > 0).toList();
    final avgSalary = salaried.isEmpty ? 0 : salaried.fold(0, (a, v) => a + v.stats.salary) ~/ salaried.length;
    final helped = done.where((v) => v.stats.help > 0).toList();
    final helpTotal = helped.fold(0, (a, v) => a + v.stats.help);
    final regularPct = avgSalary == 0 ? 0 : (done.fold(0, (a, v) => a + v.stats.regular) ~/ n) * 100 ~/ avgSalary;
    final overCount = done.where((v) => v.stats.hasSalary && v.stats.overSalary > 0).length;
    final gap = avgSpent - avgSalary;
    final unexpectedAvg = done.fold(0, (a, v) => a + v.stats.unexpected) ~/ n;

    // Regular spending over 90% of salary for 3 cycles in a row.
    var run = 0, bestRun = 0;
    for (final v in done) {
      run = v.stats.salary > 0 && v.stats.regular * 10 > v.stats.salary * 9 ? run + 1 : 0;
      if (run > bestRun) bestRun = run;
    }
    final nudge = n >= 3 && (helped.length >= 3 || overCount >= 3 || bestRun >= 3);

    final max = done.map((v) => v.stats.spent > v.stats.salary ? v.stats.spent : v.stats.salary).fold(1, (a, b) => a > b ? a : b);
    const h = 140.0;
    final mon = DateFormat('MMM');

    return Scaffold(
      appBar: AppBar(leading: const BackButton()),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 40),
        children: [
          Text('Last $n cycles', style: T.label.copyWith(color: p.muted)),
          Text('Big picture', style: T.title.copyWith(color: p.ink)),
          const SizedBox(height: 14),
          Text.rich(
            TextSpan(children: [
              const TextSpan(text: 'Your life costs about '),
              TextSpan(text: rupees(avgSpent), style: TextStyle(color: gap > 0 ? p.over : p.ink)),
              const TextSpan(text: ' a cycle. Your salary is '),
              TextSpan(text: rupees(avgSalary), style: TextStyle(color: p.salary)),
              const TextSpan(text: '.'),
            ]),
            style: T.sentence.copyWith(color: p.ink),
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: h + 8,
            child: LayoutBuilder(builder: (_, c) {
              final salaryY = avgSalary == 0 ? null : h * avgSalary / max;
              return Stack(children: [
                Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  for (final v in done)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                          if (v.stats.help > 0)
                            Container(
                              height: h * v.stats.help.clamp(0, v.stats.spent) / max,
                              decoration: BoxDecoration(color: p.help, borderRadius: const BorderRadius.vertical(top: Radius.circular(6))),
                            ),
                          Container(
                            height: h * (v.stats.spent - v.stats.help).clamp(0, 1 << 40) / max,
                            decoration: BoxDecoration(
                              color: p.ink,
                              borderRadius: v.stats.help > 0 ? null : const BorderRadius.vertical(top: Radius.circular(6)),
                            ),
                          ),
                        ]),
                      ),
                    ),
                ]),
                if (salaryY != null)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: salaryY,
                    child: Row(children: [
                      for (var k = 0; k < 40; k++)
                        Expanded(child: Container(height: 1.5, color: k.isEven ? p.over : Colors.transparent)),
                    ]),
                  ),
              ]);
            }),
          ),
          const SizedBox(height: 6),
          Row(children: [
            for (final v in done)
              Expanded(child: Center(child: Text(mon.format(v.start), style: T.label.copyWith(color: p.muted, fontSize: 11)))),
          ]),
          const SizedBox(height: 10),
          Wrap(spacing: 14, children: [
            _Key(color: p.ink, label: 'Spending'),
            _Key(color: p.help, label: 'Covered by help'),
            _Key(color: p.over, label: 'Salary', dashed: true),
          ]),
          const SizedBox(height: 18),
          LineRow(title: 'Needed help', trailing: Text(helped.isEmpty ? 'Never' : '${helped.length} of $n · ${rupees(helpTotal)}', style: T.bodyBold.copyWith(color: p.ink))),
          LineRow(title: 'Regular spending', trailing: Text('$regularPct% of salary', style: T.bodyBold.copyWith(color: p.ink))),
          LineRow(title: 'Surprises per cycle', trailing: Text(rupees(unexpectedAvg), style: T.bodyBold.copyWith(color: p.ink))),
          LineRow(title: 'Went past salary', trailing: Text('$overCount of $n cycles', style: T.bodyBold.copyWith(color: p.ink))),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: nudge ? p.extraSoft : p.surface, borderRadius: BorderRadius.circular(18)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                nudge
                    ? (gap > 0 ? 'Your salary is about ${rupees(gap)} short of what your life costs.' : 'Your salary has no room left for surprises.')
                    : 'Your salary is keeping up.',
                style: T.bodyBold.copyWith(color: p.ink, fontSize: 16),
              ),
              const SizedBox(height: 6),
              Text(
                nudge
                    ? '${helped.length >= 3 ? 'Surprises keep landing on family and friends. ' : ''}'
                        'Worth thinking about: asking for a raise, switching jobs, or upskilling for a better-paid role. '
                        'A cushion of ${rupees((unexpectedAvg * 6).clamp(1000000, 1 << 40))} would cover most surprises.'
                    : 'Keep logging. This card speaks up if the same squeeze shows up in 3 of your last 6 cycles.',
                style: T.body.copyWith(color: p.ink, height: 1.45),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({required this.color, required this.label, this.dashed = false});
  final Color color;
  final String label;
  final bool dashed;
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: dashed ? 14 : 9, height: dashed ? 2 : 9, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text(label, style: T.label.copyWith(color: context.p.muted)),
      ]);
}
