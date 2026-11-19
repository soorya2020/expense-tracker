import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/money.dart';
import '../../data/budgets.dart';
import '../../data/categories.dart';
import '../../data/settings.dart';
import '../../shared/cat_widgets.dart';
import '../../shared/motion.dart';
import '../../shared/widgets.dart';
import '../report/notifications.dart';

/// A monthly cap for each category you care about.
class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  Future<void> _edit(BuildContext context, WidgetRef ref, [BudgetLine? line]) async {
    final p = context.p;
    final s = ref.read(settingsProvider);
    final views = ref.read(cycleViewsProvider);
    final cur = views.where((v) => v.isCurrent).firstOrNull;
    final prev = cur == null ? null : views.skipWhile((v) => v != cur).skip(1).firstOrNull;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: p.bg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => _BudgetSheet(
        s: s,
        catId: line?.cat.id,
        cap: line?.cap,
        salary: _salary(s, cur),
        caps: _caps(s),
        lastSpent: prev == null ? const {} : spendByCat(prev.entries, catRules(s)),
      ),
    );
  }

  static int _salary(Settings s, CycleView? cur) => planSalary(cycleSalary: cur?.stats.salary ?? 0, usualSalary: s.usualSalary);

  /// Budgets for categories that still exist, biggest first.
  static Map<String, int> _caps(Settings s) {
    final ids = allCats(s).map((c) => c.id).toSet();
    final e = loadBudgets(s).entries.where((e) => ids.contains(e.key)).toList()..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(e);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.p;
    final s = ref.watch(settingsProvider);
    final cur = ref.watch(cycleViewsProvider).where((v) => v.isCurrent).firstOrNull;
    final caps = _caps(s);
    final plan = SalaryPlan(_salary(s, cur), caps);
    final lines = cur == null ? <BudgetLine>[] : budgetLines(s, cur.entries);
    final pace = cur == null ? 0.0 : cur.dayNumber / cur.length;
    final budgeted = lines.where((l) => l.cap != null).toList();
    final rest = lines.where((l) => l.cap == null).toList();

    return Scaffold(
      appBar: AppBar(leading: const BackButton()),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 30),
        children: [
          Text('Budgets', style: T.title.copyWith(color: p.ink)),
          const SizedBox(height: 8),
          Text(
            cur == null
                ? 'A monthly cap for each category you care about.'
                : 'This cycle · day ${cur.dayNumber} of ${cur.length}. The faint line shows where you should be by today.',
            style: T.body.copyWith(color: p.muted, height: 1.45),
          ),
          if (plan.hasSalary && caps.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SalaryCard(plan: plan, caps: caps, settings: s),
          ] else if (!plan.hasSalary && caps.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text('Add your salary and Tally shows how your budgets fit inside it.',
                  style: T.label.copyWith(color: p.muted, height: 1.4)),
            ),
          if (budgeted.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 22),
              child: Text(
                'No budgets yet. Set one for Food, Shopping or anything that tends to run away. '
                'Tally nudges you at 80% and tells you if you go over.',
                style: T.body.copyWith(color: p.muted, height: 1.5),
              ),
            ),
          for (final (i, l) in budgeted.indexed)
            RiseIn(delay: i * 40, child: _BudgetRow(l, pace: pace, onTap: () => _edit(context, ref, l))),
          if (rest.isNotEmpty) ...[
            const SizedBox(height: 22),
            Text('NO BUDGET YET', style: T.caps.copyWith(color: p.muted)),
            for (final l in rest)
              LineRow(
                title: l.cat.label,
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(rupees(l.spent), style: T.bodyBold.copyWith(color: p.ink)),
                  const SizedBox(width: 12),
                  Text('Set', style: T.label.copyWith(color: p.salary, fontWeight: FontWeight.w800)),
                ]),
                onTap: () => _edit(context, ref, l),
              ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 12),
          child: BigButton('+ Set a budget', onTap: () => _edit(context, ref)),
        ),
      ),
    );
  }
}

class _BudgetRow extends StatelessWidget {
  const _BudgetRow(this.l, {required this.pace, required this.onTap});
  final BudgetLine l;
  final double pace;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final color = switch (l.state) { BudgetState.over => p.over, BudgetState.near => p.extra, BudgetState.fine => l.cat.color };
    final pct = (l.used * 100).round();
    final ahead = l.used > pace + .05;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: p.line))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: l.cat.color, shape: BoxShape.circle)),
            const SizedBox(width: 10),
            Expanded(child: Text(l.cat.label, style: T.bodyBold.copyWith(color: p.ink, fontSize: 15))),
            Text.rich(TextSpan(children: [
              TextSpan(text: rupees(l.spent), style: T.bodyBold.copyWith(color: p.ink, fontSize: 15)),
              TextSpan(text: ' / ${rupees(l.cap!, symbol: false)}', style: T.body.copyWith(color: p.muted)),
            ])),
          ]),
          const SizedBox(height: 10),
          LayoutBuilder(builder: (_, c) {
            return SizedBox(
              height: 12,
              child: Stack(alignment: Alignment.centerLeft, children: [
                Container(height: 8, decoration: BoxDecoration(color: p.line, borderRadius: BorderRadius.circular(4))),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: l.used.clamp(0.0, 1.0)),
                  duration: motion(context, 800),
                  curve: motionCurve,
                  builder: (_, v, _) => Container(
                    width: c.maxWidth * v,
                    height: 8,
                    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
                  ),
                ),
                Positioned(
                  left: (c.maxWidth * pace.clamp(0.0, 1.0) - 1).clamp(0, c.maxWidth - 2),
                  child: Container(width: 2, height: 12, decoration: BoxDecoration(color: p.ink.withValues(alpha: .35), borderRadius: BorderRadius.circular(1))),
                ),
              ]),
            );
          }),
          const SizedBox(height: 6),
          Row(children: [
            Text(
              switch (l.state) {
                BudgetState.over => 'Over by ${rupees(-l.left)}',
                BudgetState.near => '$pct%${ahead ? ' · ahead of pace' : ''}',
                BudgetState.fine => '$pct%${ahead ? ' · ahead of pace' : ''}',
              },
              style: T.label.copyWith(
                color: l.state == BudgetState.fine ? (ahead ? p.extra : p.muted) : color,
                fontWeight: l.state == BudgetState.fine && !ahead ? FontWeight.w600 : FontWeight.w800,
              ),
            ),
            const Spacer(),
            if (l.left > 0) Text('${rupees(l.left)} left', style: T.label.copyWith(color: p.muted)),
          ]),
        ]),
      ),
    );
  }
}

/// Your salary at the top of Budgets: how much is in budgets and how much is free.
class _SalaryCard extends StatelessWidget {
  const _SalaryCard({required this.plan, required this.caps, required this.settings});
  final SalaryPlan plan;
  final Map<String, int> caps;
  final Settings settings;
  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 13),
        decoration: BoxDecoration(color: p.surface, borderRadius: BorderRadius.circular(18)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(child: Text('SALARY ${rupees(plan.salary)}', style: T.caps.copyWith(color: p.muted))),
            Text(
              plan.over ? '${rupees(-plan.free)} over' : '${rupees(plan.free)} free',
              style: T.title.copyWith(fontSize: 22, color: plan.over ? p.over : p.ink, fontFeatures: const [FontFeature.tabularFigures()]),
            ),
          ]),
          const SizedBox(height: 10),
          SalaryBar(salary: plan.salary, caps: caps, settings: settings),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: Text('${rupees(plan.planned)} in budgets', style: T.label.copyWith(color: p.ink, fontWeight: FontWeight.w700))),
            Text(
              plan.over ? 'More than you earn' : '${(plan.share * 100).round()}% of salary',
              style: T.label.copyWith(color: plan.over ? p.over : p.muted, fontWeight: FontWeight.w700),
            ),
          ]),
        ]),
      ),
      if (plan.over) ...[
        const SizedBox(height: 8),
        _Note(
          bad: true,
          parts: [
            const TextSpan(text: 'Your budgets add up to '),
            TextSpan(text: rupees(plan.planned), style: TextStyle(color: p.over, fontWeight: FontWeight.w800)),
            const TextSpan(text: ', which is '),
            TextSpan(text: rupees(-plan.free), style: const TextStyle(fontWeight: FontWeight.w800)),
            const TextSpan(text: ' more than your salary. Trim one to fit.'),
          ],
        ),
      ],
    ]);
  }
}

/// Your salary as one bar, split into a coloured piece per budget. Anything past the
/// salary turns red, with a tick where the salary ends. [highlight] dims the others.
class SalaryBar extends StatelessWidget {
  const SalaryBar({super.key, required this.salary, required this.caps, required this.settings, this.highlight});
  final int salary;
  final Map<String, int> caps;
  final Settings settings;
  final String? highlight;

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final total = caps.values.fold(0, (a, v) => a + v);
    final scale = math.max(math.max(salary, total), 1);
    final d = motion(context, 450);
    return LayoutBuilder(builder: (_, c) {
      final w = c.maxWidth;
      final pieces = <Widget>[];
      var acc = 0;
      for (final MapEntry(key: id, value: v) in caps.entries) {
        if (v <= 0) continue;
        final inside = (salary - acc).clamp(0, v);
        final outside = v - inside;
        final a = highlight != null && id != highlight ? .3 : 1.0;
        final color = catById(settings, id)?.color ?? p.muted;
        if (inside > 0) {
          pieces.add(AnimatedContainer(key: ValueKey('$id-in'), duration: d, curve: motionCurve, width: w * inside / scale, color: color.withValues(alpha: a)));
        }
        if (outside > 0) {
          pieces.add(AnimatedContainer(key: ValueKey('$id-out'), duration: d, curve: motionCurve, width: w * outside / scale, color: p.over.withValues(alpha: a)));
        }
        acc += v;
      }
      return SizedBox(
        height: 22,
        child: Stack(alignment: Alignment.centerLeft, children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: Container(height: 14, color: p.line, child: Row(children: pieces)),
          ),
          if (total > salary && salary > 0)
            AnimatedPositioned(
              duration: d,
              curve: motionCurve,
              left: (w * salary / scale - 1).clamp(0, w - 2),
              top: 0,
              bottom: 0,
              child: Container(width: 2, decoration: BoxDecoration(color: p.ink, borderRadius: BorderRadius.circular(1))),
            ),
        ]),
      );
    });
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.parts, this.bad = false});
  final List<InlineSpan> parts;
  final bool bad;
  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(color: bad ? p.overSoft : p.helpSoft, borderRadius: BorderRadius.circular(14)),
      child: Text.rich(TextSpan(children: parts), style: T.label.copyWith(color: p.ink, fontSize: 13, height: 1.45)),
    );
  }
}

class _BudgetSheet extends StatefulWidget {
  const _BudgetSheet({required this.s, this.catId, this.cap, required this.salary, required this.caps, required this.lastSpent});
  final Settings s;
  final String? catId;
  final int? cap;
  final int salary; // paise, 0 when Tally doesn't know it yet
  final Map<String, int> caps; // every budget as saved
  final Map<String?, int> lastSpent; // spending per category last cycle
  @override
  State<_BudgetSheet> createState() => _BudgetSheetState();
}

class _BudgetSheetState extends State<_BudgetSheet> {
  late String? cat = widget.catId;
  late final amount = TextEditingController(text: widget.cap == null ? '' : '${widget.cap! ~/ 100}');

  @override
  void dispose() {
    amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final paise = (int.tryParse(amount.text) ?? 0) * 100;
    final c = catById(widget.s, cat);
    // The budgets as they would be after saving, in the same order as on the page.
    final draft = <String, int>{
      for (final MapEntry(key: k, value: v) in widget.caps.entries)
        if (k == widget.catId || k == cat) ...{if (c != null && paise > 0) c.id: paise} else k: v,
      if (c != null && paise > 0) c.id: paise,
    };
    final room = SalaryPlan.roomFor(widget.salary, {...widget.caps}..remove(widget.catId), cat ?? '');
    final plan = SalaryPlan(widget.salary, draft);
    final over = c != null && paise > 0 && plan.over;
    final last = c == null ? 0 : (widget.lastSpent[c.id] ?? 0) ~/ 100 * 100;
    void use(int v) => setState(() {
          amount.text = '${v ~/ 100}';
          amount.selection = TextSelection.collapsed(offset: amount.text.length);
        });
    return Padding(
      padding: EdgeInsets.fromLTRB(22, 22, 22, 16 + MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(widget.cap == null ? 'Set a budget' : 'Edit budget', style: T.title.copyWith(color: p.ink, fontSize: 22)),
              const Spacer(),
              if (widget.cap != null)
                IconButton(
                  tooltip: 'Remove budget',
                  icon: Icon(Icons.delete_outline_rounded, color: p.muted),
                  onPressed: () async {
                    await setBudget(widget.s, cat!, null);
                    if (context.mounted) Navigator.pop(context);
                  },
                ),
            ]),
            const SizedBox(height: 14),
            CatPills(
              settings: widget.s,
              selected: cat,
              onPick: (v) => setState(() => cat = v),
              onNew: () async {
                final id = await newCatDialog(context, widget.s);
                if (id != null) setState(() => cat = id);
              },
            ),
            const SizedBox(height: 16),
            Text('Each cycle, up to', style: T.label.copyWith(color: p.muted)),
            const SizedBox(height: 8),
            TextField(
              controller: amount,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(8)],
              onChanged: (_) => setState(() {}),
              style: T.huge.copyWith(fontSize: 34, color: p.ink),
              decoration: InputDecoration(
                prefixText: '₹ ',
                prefixStyle: T.huge.copyWith(fontSize: 34, color: p.muted),
                hintText: '5,000',
                hintStyle: T.huge.copyWith(fontSize: 34, color: p.line),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            if (paise > 0 && c != null) ...[
              const SizedBox(height: 8),
              Text('About ${rupees(paise ~/ 30)} a day. Tally nudges you at ${rupees(paise * 8 ~/ 10)}.',
                  style: T.label.copyWith(color: p.muted)),
            ],
            if (widget.salary > 0) ...[
              const SizedBox(height: 14),
              SalaryBar(salary: widget.salary, caps: draft, settings: widget.s, highlight: c != null && paise > 0 ? c.id : null),
              if (c != null && ((room > 0 && room ~/ 100 * 100 != paise) || (last > 0 && last != paise))) ...[
                const SizedBox(height: 10),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  if (room > 0 && room ~/ 100 * 100 != paise)
                    Pill('Use what\'s free · ${rupees(room)}', color: p.salary, onTap: () => use(room)),
                  if (last > 0 && last != paise) Pill('Last cycle · ${rupees(last)}', onTap: () => use(last)),
                ]),
              ],
              const SizedBox(height: 10),
              _Note(
                bad: over,
                parts: c == null || paise <= 0
                    ? room > 0
                        ? [
                            TextSpan(text: rupees(room), style: TextStyle(color: p.help, fontWeight: FontWeight.w800)),
                            const TextSpan(text: ' of your salary is free to budget.'),
                          ]
                        : [TextSpan(text: 'Your budgets already use all of your ${rupees(widget.salary)} salary.')]
                    : over
                        ? [
                            const TextSpan(text: 'This puts your budgets '),
                            TextSpan(text: '${rupees(-plan.free)} over', style: TextStyle(color: p.over, fontWeight: FontWeight.w800)),
                            TextSpan(text: ' your ${rupees(widget.salary)} salary.'),
                          ]
                        : [
                            const TextSpan(text: 'Leaves '),
                            TextSpan(text: rupees(plan.free), style: TextStyle(color: p.help, fontWeight: FontWeight.w800)),
                            const TextSpan(text: ' of your salary free.'),
                          ],
              ),
            ],
            const SizedBox(height: 16),
            BigButton(
              c == null
                  ? 'Pick a category'
                  : over
                      ? 'Save anyway · ${rupees(-plan.free)} over'
                      : 'Save ${c.label} budget',
              color: over ? p.over : null,
              onTap: c == null || paise <= 0
                  ? null
                  : () async {
                      await setBudget(widget.s, c.id, paise);
                      if (context.mounted) Navigator.pop(context);
                    },
            ),
          ]),
        ),
      ),
    );
  }
}

/// Sends a notification the first time a budget passes 80%, and again if it goes over.
Future<void> checkBudgetAlerts(Settings s, CycleView cur) async {
  final flags = s.budgetFlags.toSet();
  final left = cur.length - cur.dayNumber;
  for (final (i, l) in budgetLines(s, cur.entries).indexed) {
    if (l.cap == null || l.state == BudgetState.fine) continue;
    final f = alertFlag(cur.start, l);
    if (flags.contains(f)) continue;
    await s.addBudgetFlag(f);
    final over = l.state == BudgetState.over;
    final title = over ? '${l.cat.label} is over budget' : '${l.cat.label} is at ${(l.used * 100).round()}% of its budget';
    final body = s.hideAmountsInNotifications
        ? 'Tap to see your budgets.'
        : over
            ? '${rupees(l.spent)} of ${rupees(l.cap!)}. Over by ${rupees(-l.left)}.'
            : '${rupees(l.spent)} of ${rupees(l.cap!)} with $left days to go.';
    try {
      await AppNotifications.instance.showBudget(i, title, body);
    } catch (_) {}
  }
}
