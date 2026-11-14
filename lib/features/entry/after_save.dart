import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/cycle_math.dart';
import '../../core/money.dart';
import '../../shared/widgets.dart';

/// After a salary is saved: remember the usual amount, and if it landed a few
/// days away from the cycle's start, offer to move the cycle.
Future<void> afterSalarySaved(WidgetRef ref, GoRouter router, DateTime date, int amount) async {
  final settings = ref.read(settingsProvider);
  await settings.setUsualSalary(amount);
  if (!settings.followSalary) return;
  final repo = ref.read(repoProvider);
  final cycles = await repo.allCycles();
  if (cycles.isEmpty) return;
  final cur = cycles.first;
  final d = dateOnly(date);
  // Distance from the nearest expected start (this cycle's start or the next one).
  final nextStart = cur.endDate.add(const Duration(days: 1));
  final diffCur = d.difference(cur.startDate).inDays;
  final diffNext = d.difference(nextStart).inDays;
  final diff = diffCur.abs() <= diffNext.abs() ? diffCur : diffNext;
  if (diff == 0 || diff.abs() > 7) return;
  final early = diff != diffCur;
  if (early && diffNext > 0) return;
  {
    final ctx = router.routerDelegate.navigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) return;
    await showModalBottomSheet<void>(
      context: ctx,
      backgroundColor: ctx.p.bg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (c) => _ShiftSheet(date: d, early: early),
    );
  }
}

class _ShiftSheet extends ConsumerWidget {
  const _ShiftSheet({required this.date, required this.early});
  final DateTime date;
  final bool early;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.p;
    final day = ref.read(settingsProvider).cycleDay;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 16),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Salary came on the ${ordinal(date.day)}.', style: T.title.copyWith(color: p.ink)),
          const SizedBox(height: 8),
          Text(
            'Your cycle starts on the ${ordinal(day)}. Start this one from ${shortDate(date)} instead?',
            style: T.body.copyWith(color: p.muted, height: 1.4),
          ),
          const SizedBox(height: 18),
          BigButton('Yes, just this once', onTap: () async {
            await ref.read(repoProvider).shiftCycle(date, early: early);
            if (context.mounted) Navigator.pop(context);
          }),
          const SizedBox(height: 10),
          BigButton('Always use the ${ordinal(date.day)}', filled: false, onTap: () async {
            final repo = ref.read(repoProvider);
            await ref.read(settingsProvider).setCycleDay(date.day > 28 ? lastDay : date.day);
            await repo.shiftCycle(date, early: early);
            final cycles = await repo.allCycles();
            if (cycles.isNotEmpty) {
              final c = cycles.first;
              await repo.updateCycle(c.copyWith(endDate: cycleEndFor(c.startDate, ref.read(settingsProvider).cycleDay)));
            }
            if (context.mounted) Navigator.pop(context);
          }),
          const SizedBox(height: 6),
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Keep the ${ordinal(day)}', style: T.label.copyWith(color: p.muted, fontWeight: FontWeight.w800)),
            ),
          ),
        ]),
      ),
    );
  }
}
