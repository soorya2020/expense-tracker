import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/cycle_math.dart';
import '../../core/money.dart';
import '../../data/db.dart';
import '../../data/recurring.dart';
import '../../main.dart' show scheduleNotifications;
import '../../shared/widgets.dart';
import '../cycle/day_strip.dart';
import '../report/notifications.dart';

/// Salary, rent, EMIs and subscriptions that Tally adds each cycle.
class RecurringScreen extends ConsumerStatefulWidget {
  const RecurringScreen({super.key});
  @override
  ConsumerState<RecurringScreen> createState() => _RecurringScreenState();
}

class _RecurringScreenState extends ConsumerState<RecurringScreen> {
  final next = <String, DateTime>{};

  @override
  void initState() {
    super.initState();
    _loadNext();
  }

  Future<void> _loadNext() async {
    final s = ref.read(settingsProvider), repo = ref.read(repoProvider);
    for (final r in loadRules(s)) {
      next[r.id] = await nextDue(r, repo, s);
    }
    if (mounted) setState(() {});
  }

  Future<void> _afterChange() async {
    final s = ref.read(settingsProvider), repo = ref.read(repoProvider);
    final added = await applyRecurring(repo, s);
    try {
      await scheduleNotifications(repo, s);
    } catch (_) {}
    await _loadNext();
    if (added > 0 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Added $added for this cycle')));
    }
  }

  Future<void> _edit([RecurringRule? r]) async {
    final s = ref.read(settingsProvider);
    final result = await showModalBottomSheet<_SheetResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.p.bg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => _RuleSheet(rule: r),
    );
    if (result == null) return;
    final rules = loadRules(s);
    if (result.delete) {
      rules.removeWhere((x) => x.id == r!.id);
    } else {
      final rule = await startRule(result.rule!, ref.read(repoProvider), s);
      if (r == null) {
        rules.add(rule);
      } else {
        final i = rules.indexWhere((x) => x.id == r.id);
        if (i >= 0) rules[i] = rule;
      }
      if (rule.remind && !rule.income) await AppNotifications.instance.askPermission();
    }
    await saveRules(s, rules);
    await _afterChange();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final rules = loadRules(ref.watch(settingsProvider));
    String dayText(int d) => d == lastDay ? 'last day' : ordinal(d);
    return Scaffold(
      appBar: AppBar(leading: const BackButton()),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 30),
        children: [
          Text('Recurring', style: T.title.copyWith(color: p.ink)),
          const SizedBox(height: 8),
          Text('Added for you each cycle on the day. Bills can remind you at 9 AM the day before.',
              style: T.body.copyWith(color: p.muted, height: 1.45)),
          const SizedBox(height: 10),
          if (rules.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Text('Nothing yet. Add your salary, rent, EMIs or subscriptions once and Tally logs them every cycle.',
                  style: T.body.copyWith(color: p.muted, height: 1.5)),
            ),
          for (final r in rules)
            LineRow(
              title: r.title.isEmpty ? (r.income ? IncomeKind.label(r.kind ?? IncomeKind.salary) : 'Spending') : r.title,
              subtitle: [
                r.income ? 'In' : 'Out',
                'every ${dayText(r.day)}',
                if (next[r.id] != null) 'next ${shortDate(next[r.id]!)}',
                if (!r.income && r.remind) 'reminder on',
              ].join(' · '),
              trailing: Text(signed(r.amount, positive: r.income),
                  style: T.bodyBold.copyWith(color: r.income ? p.forIncome(r.kind) : p.ink, fontSize: 15)),
              onTap: () => _edit(r),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 12),
          child: BigButton('+ Add recurring', onTap: () => _edit()),
        ),
      ),
    );
  }
}

class _SheetResult {
  _SheetResult.save(this.rule) : delete = false;
  _SheetResult.remove()
      : rule = null,
        delete = true;
  final RecurringRule? rule;
  final bool delete;
}

class _RuleSheet extends StatefulWidget {
  const _RuleSheet({this.rule});
  final RecurringRule? rule;
  @override
  State<_RuleSheet> createState() => _RuleSheetState();
}

class _RuleSheetState extends State<_RuleSheet> {
  late bool income = widget.rule?.income ?? false;
  late String kind = widget.rule?.kind ?? IncomeKind.salary;
  late int day = widget.rule?.day ?? 1;
  late bool remind = widget.rule?.remind ?? true;
  late final title = TextEditingController(text: widget.rule?.title ?? '');
  late final amount = TextEditingController(text: widget.rule == null ? '' : '${widget.rule!.amount ~/ 100}');

  int get paise => rupeesToPaise(int.tryParse(amount.text) ?? 0);

  @override
  void dispose() {
    title.dispose();
    amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    InputDecoration deco(String hint) => InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: p.surface,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        );
    Widget seg(String label, bool on, bool value) => GestureDetector(
          onTap: () => setState(() => income = value),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
            decoration: BoxDecoration(
              color: on ? p.bg : Colors.transparent,
              borderRadius: BorderRadius.circular(99),
              boxShadow: on ? const [BoxShadow(color: Color(0x22000000), blurRadius: 4, offset: Offset(0, 1))] : null,
            ),
            child: Text(label, style: T.bodyBold.copyWith(fontSize: 15, color: on ? p.ink : p.muted)),
          ),
        );

    return Padding(
      padding: EdgeInsets.fromLTRB(22, 22, 22, 16 + MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(widget.rule == null ? 'New recurring' : 'Edit recurring', style: T.title.copyWith(color: p.ink, fontSize: 22)),
              const Spacer(),
              if (widget.rule != null)
                IconButton(
                  tooltip: 'Delete',
                  icon: Icon(Icons.delete_outline_rounded, color: p.muted),
                  onPressed: () => Navigator.pop(context, _SheetResult.remove()),
                ),
            ]),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: p.surface, borderRadius: BorderRadius.circular(99)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [seg('In', income, true), seg('Out', !income, false)]),
            ),
            const SizedBox(height: 12),
            if (income) ...[
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final k in IncomeKind.all)
                  Pill(IncomeKind.label(k), selected: kind == k, color: p.forIncome(k) == p.muted ? p.ink : p.forIncome(k), onTap: () => setState(() => kind = k)),
              ]),
              const SizedBox(height: 12),
            ],
            Row(children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: title,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: deco(income ? 'Label, e.g. Salary' : 'What, e.g. Rent'),
                  style: T.bodyBold.copyWith(color: p.ink, fontSize: 15),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: amount,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(9)],
                  onChanged: (_) => setState(() {}),
                  decoration: deco('₹ Amount'),
                  style: T.bodyBold.copyWith(color: p.ink, fontSize: 15),
                ),
              ),
            ]),
            const SizedBox(height: 14),
            Text('Every month on the', style: T.label.copyWith(color: p.muted)),
            const SizedBox(height: 8),
            DayStrip(selected: day, onSelect: (d) => setState(() => day = d)),
            if (!income) ...[
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: Text('Remind me the day before', style: T.body.copyWith(color: p.ink, fontSize: 15))),
                Switch(value: remind, onChanged: (v) => setState(() => remind = v)),
              ]),
            ],
            const SizedBox(height: 14),
            BigButton(
              'Save',
              onTap: paise <= 0
                  ? null
                  : () => Navigator.pop(
                        context,
                        _SheetResult.save(RecurringRule(
                          id: widget.rule?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
                          income: income,
                          kind: income ? kind : null,
                          title: title.text.trim(),
                          amount: paise,
                          day: day,
                          remind: !income && remind,
                          lastCycle: widget.rule?.lastCycle,
                        )),
                      ),
            ),
          ]),
        ),
      ),
    );
  }
}
