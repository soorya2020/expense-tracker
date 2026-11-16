import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/money.dart';
import '../../data/daily.dart';
import '../../data/db.dart';
import '../../data/repo.dart';
import '../../data/stats.dart';
import '../../shared/motion.dart';
import '../../shared/widgets.dart';
import '../entry/add_entry_screen.dart';
import '../report/insights.dart';
import '../sms/bank_sms_screen.dart';
import '../settings/budgets_screen.dart';
import '../widget/home_widgets.dart';
import 'budget_cards.dart';
import 'daily_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int index = 0; // 0 = newest cycle
  int dir = 1; // 1 = moved to an older cycle, -1 = newer
  final known = <int>{}; // entries already on screen, so only new ones animate in
  bool seeded = false;

  Future<void> _delete(Entry e) async {
    final repo = ref.read(repoProvider), messenger = ScaffoldMessenger.of(context);
    known.remove(e.id);
    await repo.deleteEntry(e.id);
    messenger.showSnackBar(
      SnackBar(
        content: Text('Deleted ${rupees(e.amount)}'),
        action: SnackBarAction(label: 'Undo', onPressed: () => repo.restoreEntry(e)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final views = ref.watch(cycleViewsProvider);
    final bal = ref.watch(balanceProvider);
    if (views.isEmpty) return const Scaffold(body: SizedBox());
    final i = index.clamp(0, views.length - 1);
    final v = views[i];
    final s = v.stats;
    final animateNew = seeded && v.isCurrent;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      known.addAll(v.entries.map((e) => e.id));
      seeded = true;
      if (v.isCurrent) {
        checkBudgetAlerts(ref.read(settingsProvider), v);
        pushWidgetData(ref.read(settingsProvider), v, bal);
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(22, 10, 22, 120),
              children: [
                Row(
                  children: [
                    _Arrow(
                      '‹',
                      i < views.length - 1
                          ? () => setState(() {
                              dir = 1;
                              index = i + 1;
                            })
                          : null,
                    ),
                    Text(rangeLabel(v.start, v.end), style: T.label.copyWith(color: p.muted, fontSize: 13)),
                    _Arrow(
                      '›',
                      i > 0
                          ? () => setState(() {
                              dir = -1;
                              index = i - 1;
                            })
                          : null,
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => context.push('/settings'),
                      icon: Icon(Icons.settings_outlined, color: p.muted, size: 22),
                      tooltip: 'Settings',
                    ),
                  ],
                ),
                AnimatedSwitcher(
                  duration: motion(context, 300),
                  reverseDuration: motion(context, 170),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  layoutBuilder: (cur, prev) => Stack(alignment: Alignment.topCenter, children: [...prev, ?cur]),
                  transitionBuilder: (child, a) {
                    final incoming = child.key == ValueKey(i);
                    return FadeTransition(
                      opacity: a,
                      child: SlideTransition(
                        position: Tween(begin: Offset((incoming ? -dir : dir) * .12, 0), end: Offset.zero).animate(a),
                        child: child,
                      ),
                    );
                  },
                  child: Column(
                    key: ValueKey(i),
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (v.isCurrent && i + 1 < views.length && v.dayNumber <= 3) ...[const SizedBox(height: 8), _LastCycleCard(prev: views[i + 1])],
                      const SizedBox(height: 14),
                      RiseIn(
                        child: Text(v.isCurrent ? 'Balance' : (s.net >= 0 ? 'You saved' : 'You overspent'), style: T.label.copyWith(color: p.muted)),
                      ),
                      const SizedBox(height: 6),
                      RiseIn(
                        delay: 50,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: CountUp(
                            v.isCurrent ? bal : s.net.abs(),
                            format: rupees,
                            ms: 900,
                            style: T.huge.copyWith(color: p.ink),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      if (!v.isCurrent || s.overSalary > 0)
                        RiseIn(
                          delay: 100,
                          child: Text.rich(
                            TextSpan(children: storySpans(context, s, current: v.isCurrent)),
                            style: T.sentence.copyWith(color: p.ink),
                          ),
                        ),
                      if (v.isCurrent) ...[
                        BudgetNudge(v: v),
                        const SizedBox(height: 14),
                        RiseIn(
                          delay: 100,
                          child: DailyCard(
                            d: DailySpend.of(v.entries, v.start, v.end, DateTime.now()),
                            start: v.start,
                            end: v.end,
                          ),
                        ),
                        RiseIn(delay: 150, child: WhereItWent(v: v)),
                        ..._extras(context, ref),
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
                          Dismissible(
                            key: ValueKey('h${e.id}'),
                            direction: DismissDirection.endToStart,
                            background: const DeleteSwipeBackground(),
                            onDismissed: (_) => _delete(e),
                            child: AppearRow(
                              key: ValueKey('a${e.id}'),
                              animate: animateNew && !known.contains(e.id),
                              highlight: p.salarySoft,
                              child: EntryRow(
                                e,
                                onTap: () => context.push('/add', extra: AddArgs(edit: e)),
                              ),
                            ),
                          ),
                        if (v.entries.length > 8 || views.length > 1)
                          Padding(
                            padding: const EdgeInsets.only(top: 14),
                            child: GestureDetector(
                              onTap: () => context.push('/history'),
                              child: Text(
                                'See all history  ›',
                                style: T.label.copyWith(color: p.salary, fontWeight: FontWeight.w800, fontSize: 13),
                              ),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              left: 22,
              right: 22,
              bottom: 18,
              child: _Dock(
                onIn: () => context.push('/add', extra: const AddArgs(income: true)),
                onOut: () => context.push('/add', extra: const AddArgs(income: false)),
                middle: ref.watch(settingsProvider).smsEnabled ? _SmsButton() : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "To repay" and "Set aside" lines on Home.
List<Widget> _extras(BuildContext context, WidgetRef ref) {
  final p = context.p;
  final all = ref.watch(entriesProvider).value ?? const [];
  final owed = all.where((e) => isIncome(e) && e.incomeKind == IncomeKind.borrowed && e.repaidAt == null).toList();
  final yearAgo = DateTime.now().subtract(const Duration(days: 365));
  final yearly = all.where((e) => !isIncome(e) && e.yearly && e.date.isAfter(yearAgo)).toList();
  final aside = yearly.fold(0, (a, e) => a + e.amount) ~/ 12;
  final sms = ref.watch(settingsProvider).smsEnabled
      ? cycleSms(ref.watch(bankSmsProvider).value ?? const <BankMessage>[], ref.watch(currentCycleProvider)?.start)
      : const <BankMessage>[];
  final credit = sms.where((m) => m.direction == 'credit' && m.status == 'new').firstOrNull;
  return [
    AnimatedSwitcher(
      duration: motion(context, 380),
      transitionBuilder: (c, a) => SizeTransition(
        sizeFactor: CurvedAnimation(parent: a, curve: Curves.easeOutCubic),
        alignment: Alignment.topCenter,
        child: FadeTransition(opacity: a, child: c),
      ),
      child: credit == null
          ? const SizedBox(key: ValueKey('no-credit'), width: double.infinity)
          : Padding(
              key: ValueKey(credit.refNo),
              padding: const EdgeInsets.only(top: 14),
              child: Material(
                color: p.salarySoft,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => addFromSms(context, ref, credit),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        Icon(Icons.mail_outline_rounded, color: p.salary, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${rupees(credit.amount)} credited${credit.counterparty != null ? ' from ${credit.counterparty}' : ''}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: T.body.copyWith(color: p.ink, fontWeight: FontWeight.w600),
                          ),
                        ),
                        Text(
                          'Add',
                          style: T.label.copyWith(color: p.salary, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    ),
    for (final e in owed)
      Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'You owe ${e.title ?? 'someone'} ${rupees(e.amount)}',
                style: T.body.copyWith(color: p.ink, fontWeight: FontWeight.w600),
              ),
            ),
            GestureDetector(
              onTap: () async {
                await ref.read(repoProvider).markRepaid(e);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Marked ${rupees(e.amount)} as repaid')));
                }
              },
              child: Text(
                'Mark repaid',
                style: T.label.copyWith(color: p.salary, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    if (aside > 0)
      Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Text(
          'Set aside ${rupees(aside)} a cycle for ${yearly.map((e) => e.title ?? Reasons.label(e.reason ?? 'other')).toSet().join(', ')}.',
          style: T.label.copyWith(color: p.muted, fontSize: 13),
        ),
      ),
  ];
}

/// The plain-language sentence under the balance.
List<InlineSpan> storySpans(BuildContext context, Stats s, {required bool current}) {
  final p = context.p;
  TextSpan c(String t, Color col) => TextSpan(
    text: t,
    style: TextStyle(color: col),
  );
  final spent = c(rupees(s.spent), p.salary);
  final verb = current ? 'You’ve spent ' : 'You spent ';
  if (s.spent == 0 && s.income == 0) {
    return [TextSpan(text: current ? 'A fresh cycle. Nothing spent yet.' : 'A quiet cycle.')];
  }
  if (!s.hasSalary) {
    return [TextSpan(text: verb), spent, TextSpan(text: current ? '. No salary logged yet this cycle.' : '. No salary was logged this cycle.')];
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
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Last cycle: ${resultLine(prev)}', style: T.bodyBold.copyWith(color: p.ink, fontSize: 15)),
                    Text(rangeLabel(prev.start, prev.end), style: T.label.copyWith(color: p.muted)),
                  ],
                ),
              ),
              Text(
                'Report ›',
                style: T.label.copyWith(color: p.salary, fontWeight: FontWeight.w800, fontSize: 13),
              ),
            ],
          ),
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

class _Dock extends StatelessWidget {
  const _Dock({required this.onIn, required this.onOut, this.middle});
  final VoidCallback onIn, onOut;
  final Widget? middle;
  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(color: p.ink, borderRadius: BorderRadius.circular(999)),
      child: Row(
        children: [
          Expanded(
            child: Pressable(
              child: Material(
                color: p.bg,
                shape: const StadiumBorder(),
                child: InkWell(
                  customBorder: const StadiumBorder(),
                  onTap: onIn,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      heightFactor: 1,
                      child: Text('+ In', style: T.bodyBold.copyWith(color: p.ink, fontSize: 15)),
                    ),
                  ),
                ),
              ),
            ),
          ),
          ?middle,
          Expanded(
            child: Pressable(
              child: InkWell(
                customBorder: const StadiumBorder(),
                onTap: onOut,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    heightFactor: 1,
                    child: Text('− Out', style: T.bodyBold.copyWith(color: p.bg, fontSize: 15)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SmsButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.p;
    final n = cycleSms(
      ref.watch(bankSmsProvider).value ?? const <BankMessage>[],
      ref.watch(currentCycleProvider)?.start,
    ).where((m) => m.status == 'new').length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: IconButton(
        tooltip: 'Bank SMS',
        onPressed: () => context.push('/sms'),
        icon: Bump(
          value: n,
          child: Badge(
            isLabelVisible: n > 0,
            backgroundColor: p.over,
            label: Text(n > 99 ? '99+' : '$n'),
            child: Bump(
              value: n,
              wiggle: true,
              child: Icon(Icons.mail_outline_rounded, color: p.bg, size: 24),
            ),
          ),
        ),
      ),
    );
  }
}
