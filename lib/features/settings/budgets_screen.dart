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
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: p.bg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => _BudgetSheet(s: s, catId: line?.cat.id, cap: line?.cap),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.p;
    final s = ref.watch(settingsProvider);
    final cur = ref.watch(cycleViewsProvider).where((v) => v.isCurrent).firstOrNull;
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

class _BudgetSheet extends StatefulWidget {
  const _BudgetSheet({required this.s, this.catId, this.cap});
  final Settings s;
  final String? catId;
  final int? cap;
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
            const SizedBox(height: 16),
            BigButton(
              c == null ? 'Pick a category' : 'Save ${c.label} budget',
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
