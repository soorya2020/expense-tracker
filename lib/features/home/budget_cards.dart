import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/money.dart';
import '../../data/budgets.dart';
import '../../data/categories.dart';
import '../../data/settings.dart';
import '../../shared/motion.dart';

/// "Food is at 84% of its budget…" on Home, until you dismiss it.
class BudgetNudge extends ConsumerWidget {
  const BudgetNudge({super.key, required this.v});
  final CycleView v;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.p;
    final s = ref.watch(settingsProvider);
    final l = nudgeLine(s, v.entries, v.start);
    return AnimatedSize(
      duration: motion(context, 300),
      curve: motionCurve,
      alignment: Alignment.topCenter,
      child: l == null
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.only(top: 14),
              child: RiseIn(child: _card(context, p, s, l)),
            ),
    );
  }

  Widget _card(BuildContext context, Palette p, Settings s, BudgetLine l) {
    final over = l.state == BudgetState.over;
    final left = v.length - v.dayNumber;
    final fg = over ? p.over : const Color(0xFF9A6200);
    final darkFg = Theme.of(context).brightness == Brightness.dark ? (over ? p.over : p.extra) : fg;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: BoxDecoration(color: over ? p.overSoft : p.extraSoft, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text.rich(
          TextSpan(children: [
            TextSpan(
              text: over ? '${l.cat.label} is ${rupees(-l.left)} over' : '${l.cat.label} is at ${(l.used * 100).round()}%',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            TextSpan(
              text: over
                  ? ' its ${rupees(l.cap!)} budget, with $left days still to go.'
                  : ' of its ${rupees(l.cap!)} budget with $left days to go. '
                      '${left > 0 ? 'About ${rupees(l.left ~/ left)} a day keeps it inside.' : ''}',
            ),
          ]),
          style: T.body.copyWith(color: p.ink, fontSize: 14, height: 1.4, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Row(children: [
          TextButton(
            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 36), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
            onPressed: () => context.push('/settings/budgets'),
            child: Text('See budgets', style: T.label.copyWith(color: darkFg, fontWeight: FontWeight.w800, fontSize: 13)),
          ),
          const SizedBox(width: 18),
          TextButton(
            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 36), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
            onPressed: () => s.addBudgetFlag(dismissFlag(v.start, l)),
            child: Text('Dismiss', style: T.label.copyWith(color: darkFg, fontWeight: FontWeight.w800, fontSize: 13)),
          ),
        ]),
      ]),
    );
  }
}

/// A stacked bar of this cycle's spending by category. Shown once anything is tagged.
class WhereItWent extends ConsumerWidget {
  const WhereItWent({super.key, required this.v});
  final CycleView v;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.p;
    final s = ref.watch(settingsProvider);
    final by = spendByCat(v.entries, catRules(s));
    if (by.keys.every((k) => k == null)) return const SizedBox.shrink();
    final parts = [
      for (final e in by.entries.where((e) => e.key != null && e.value > 0))
        if (catById(s, e.key) case final c?) (c.label, c.color, e.value),
    ]..sort((a, b) => b.$3.compareTo(a.$3));
    if ((by[null] ?? 0) > 0) parts.add(('Untagged', untaggedColor, by[null]!));
    final total = parts.fold(0, (a, x) => a + x.$3);
    if (total <= 0) return const SizedBox.shrink();
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Material(
        color: dark ? p.surface : p.bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: dark ? BorderSide.none : BorderSide(color: p.line)),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => context.push('/settings/budgets'),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text('WHERE IT WENT', style: T.caps.copyWith(color: p.muted)),
                const Spacer(),
                Text('Budgets ›', style: T.label.copyWith(color: p.salary, fontWeight: FontWeight.w800)),
              ]),
              const SizedBox(height: 10),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: motion(context, 900),
                curve: motionCurve,
                builder: (_, t, _) => ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(
                    height: 12,
                    child: Row(children: [
                      for (final (i, x) in parts.indexed) ...[
                        if (i > 0) const SizedBox(width: 2),
                        Expanded(flex: (x.$3 ~/ 100).clamp(1, 1 << 30), child: Container(color: x.$2)),
                      ],
                      // Grows in from the left the first time.
                      if (t < 1) Expanded(flex: ((1 - t) * total / 100 * 1.2).round().clamp(0, 1 << 30), child: Container(color: dark ? p.surface : p.bg)),
                    ]),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(spacing: 12, runSpacing: 6, children: [
                for (final x in parts)
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: x.$2, shape: BoxShape.circle)),
                    const SizedBox(width: 5),
                    Text('${x.$1} ', style: T.label.copyWith(color: p.muted)),
                    Text(rupees(x.$3, symbol: false), style: T.label.copyWith(color: p.ink, fontWeight: FontWeight.w800)),
                  ]),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}
