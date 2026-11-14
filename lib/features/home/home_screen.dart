import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/money.dart';
import '../../data/stats.dart';
import '../../shared/widgets.dart';
import '../entry/add_entry_screen.dart';
import '../report/insights.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int index = 0; // 0 = newest cycle

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final views = ref.watch(cycleViewsProvider);
    final bal = ref.watch(balanceProvider);
    if (views.isEmpty) return const Scaffold(body: SizedBox());
    final i = index.clamp(0, views.length - 1);
    final v = views[i];
    final s = v.stats;

    return Scaffold(
      body: SafeArea(
        child: Stack(children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(22, 10, 22, 120),
            children: [
              Row(children: [
                _Arrow('‹', i < views.length - 1 ? () => setState(() => index = i + 1) : null),
                Text(rangeLabel(v.start, v.end), style: T.label.copyWith(color: p.muted, fontSize: 13)),
                _Arrow('›', i > 0 ? () => setState(() => index = i - 1) : null),
                const Spacer(),
                IconButton(
                  onPressed: () => context.push('/settings'),
                  icon: Icon(Icons.settings_outlined, color: p.muted, size: 22),
                  tooltip: 'Settings',
                ),
              ]),
              if (v.isCurrent && i + 1 < views.length && v.dayNumber <= 3) ...[
                const SizedBox(height: 8),
                _LastCycleCard(prev: views[i + 1]),
              ],
              const SizedBox(height: 14),
              Text(v.isCurrent ? 'Balance' : (s.net >= 0 ? 'You saved' : 'You overspent'),
                  style: T.label.copyWith(color: p.muted)),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(v.isCurrent ? rupees(bal) : rupees(s.net.abs()), style: T.huge.copyWith(color: p.ink)),
              ),
              const SizedBox(height: 18),
              Text.rich(TextSpan(children: storySpans(context, s, current: v.isCurrent)), style: T.sentence.copyWith(color: p.ink)),
              if (v.isCurrent) ...[
                const SizedBox(height: 18),
                _CycleTrack(day: v.dayNumber, length: v.length, start: v.start, end: v.end),
              ],
              const SizedBox(height: 16),
              if (v.entries.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Text(
                    v.isCurrent
                        ? 'Nothing logged in this cycle yet.\nTap + In when your salary arrives, and − Out when you add up your spending.'
                        : 'Nothing was logged in this cycle.',
                    style: T.body.copyWith(color: p.muted, height: 1.5),
                  ),
                )
              else ...[
                for (final e in v.entries.take(8))
                  EntryRow(e, onTap: () => context.push('/add', extra: AddArgs(edit: e))),
                if (v.entries.length > 8 || views.length > 1)
                  Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: GestureDetector(
                      onTap: () => context.push('/history'),
                      child: Text('See all history  ›', style: T.label.copyWith(color: p.salary, fontWeight: FontWeight.w800, fontSize: 13)),
                    ),
                  ),
              ],
            ],
          ),
          Positioned(
            left: 22,
            right: 22,
            bottom: 18,
            child: _Dock(
              onIn: () => context.push('/add', extra: const AddArgs(income: true)),
              onOut: () => context.push('/add', extra: const AddArgs(income: false)),
            ),
          ),
        ]),
      ),
    );
  }
}

/// The plain-language sentence under the balance.
List<InlineSpan> storySpans(BuildContext context, Stats s, {required bool current}) {
  final p = context.p;
  TextSpan c(String t, Color col) => TextSpan(text: t, style: TextStyle(color: col));
  final spent = c(rupees(s.spent), p.salary);
  final verb = current ? 'You’ve spent ' : 'You spent ';
  if (s.spent == 0 && s.income == 0) {
    return [TextSpan(text: current ? 'A fresh cycle. Nothing spent yet.' : 'A quiet cycle.')];
  }
  if (!s.hasSalary) {
    return [
      TextSpan(text: verb),
      spent,
      TextSpan(text: current ? '. No salary logged yet this cycle.' : '. No salary was logged this cycle.'),
    ];
  }
  if (s.overSalary > 0) {
    final coveredBy = s.help > 0
        ? c('Help from others', p.help)
        : s.extra + s.borrowed > 0
            ? c('Extra money', p.extra)
            : const TextSpan(text: 'Your savings');
    return [
      TextSpan(text: verb),
      spent,
      const TextSpan(text: ', that’s '),
      c('${rupees(s.overSalary)} past your salary', p.over),
      const TextSpan(text: '. '),
      coveredBy,
      TextSpan(text: current ? ' is covering it.' : ' covered it.'),
    ];
  }
  final left = s.salary - s.spent;
  return [
    TextSpan(text: verb),
    spent,
    const TextSpan(text: ' of your '),
    c(rupees(s.salary), p.salary),
    TextSpan(text: current ? ' salary. ' : ' salary, '),
    TextSpan(text: current ? '${rupees(left)} of it is left.' : 'keeping ${rupees(left)} of it.'),
  ];
}

class _LastCycleCard extends StatelessWidget {
  const _LastCycleCard({required this.prev});
  final CycleView prev;
  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return Material(
      color: p.salarySoft,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => context.push('/report/${prev.start.millisecondsSinceEpoch}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Last cycle: ${resultLine(prev)}', style: T.bodyBold.copyWith(color: p.ink, fontSize: 15)),
                Text(rangeLabel(prev.start, prev.end), style: T.label.copyWith(color: p.muted)),
              ]),
            ),
            Text('Report ›', style: T.label.copyWith(color: p.salary, fontWeight: FontWeight.w800, fontSize: 13)),
          ]),
        ),
      ),
    );
  }
}

class _Arrow extends StatelessWidget {
  const _Arrow(this.t, this.onTap);
  final String t;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Text(t, style: T.bodyBold.copyWith(fontSize: 18, color: onTap == null ? context.p.line : context.p.muted)),
        ),
      );
}

class _CycleTrack extends StatelessWidget {
  const _CycleTrack({required this.day, required this.length, required this.start, required this.end});
  final int day, length;
  final DateTime start, end;
  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final f = (day / length).clamp(0.0, 1.0);
    return Column(children: [
      LayoutBuilder(builder: (_, c) {
        final w = c.maxWidth;
        return SizedBox(
          height: 16,
          child: Stack(alignment: Alignment.centerLeft, children: [
            Container(height: 4, decoration: BoxDecoration(color: p.line, borderRadius: BorderRadius.circular(2))),
            Container(width: w * f, height: 4, decoration: BoxDecoration(color: p.ink, borderRadius: BorderRadius.circular(2))),
            Positioned(
              left: (w * f - 8).clamp(0, w - 16),
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(color: p.ink, shape: BoxShape.circle, border: Border.all(color: p.bg, width: 3)),
              ),
            ),
          ]),
        );
      }),
      const SizedBox(height: 6),
      Row(children: [
        Text(shortDate(start), style: T.label.copyWith(color: p.muted, fontSize: 11)),
        const Spacer(),
        Text('day $day · ${length - day} to go', style: T.label.copyWith(color: p.muted, fontSize: 11)),
        const Spacer(),
        Text(shortDate(end), style: T.label.copyWith(color: p.muted, fontSize: 11)),
      ]),
    ]);
  }
}

class _Dock extends StatelessWidget {
  const _Dock({required this.onIn, required this.onOut});
  final VoidCallback onIn, onOut;
  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(color: p.ink, borderRadius: BorderRadius.circular(999)),
      child: Row(children: [
        Expanded(
          child: Material(
            color: p.bg,
            shape: const StadiumBorder(),
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: onIn,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(child: Text('+ In', style: T.bodyBold.copyWith(color: p.ink, fontSize: 15))),
              ),
            ),
          ),
        ),
        Expanded(
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: onOut,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(child: Text('− Out', style: T.bodyBold.copyWith(color: p.bg, fontSize: 15))),
            ),
          ),
        ),
      ]),
    );
  }
}
