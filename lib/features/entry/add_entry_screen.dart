import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/cycle_math.dart';
import '../../core/money.dart';
import '../../data/db.dart';
import '../../data/repo.dart';
import '../../shared/widgets.dart';
import 'after_save.dart';

/// What the add screen opens with.
class AddArgs {
  const AddArgs({this.income = true, this.edit, this.amount, this.date, this.endDate, this.title, this.sourceText, this.onSaved, this.kind});
  final bool income;
  final String? kind;
  final Entry? edit;
  final int? amount; // paise, prefilled (e.g. from an SMS)
  final DateTime? date;
  final DateTime? endDate; // for a range, e.g. several debits added as one
  final String? title;
  final String? sourceText; // original SMS shown on top
  final Future<void> Function(int entryId)? onSaved;
}

enum Period { today, week, sinceLast, custom }

class AddEntryScreen extends ConsumerStatefulWidget {
  const AddEntryScreen({super.key, required this.args});
  final AddArgs args;
  @override
  ConsumerState<AddEntryScreen> createState() => _AddEntryScreenState();
}

class _AddEntryScreenState extends ConsumerState<AddEntryScreen> {
  late bool income;
  String digits = '';
  String kind = IncomeKind.extra;
  String? title;
  String? note;
  DateTime date = dateOnly(DateTime.now());
  DateTime? endDate;
  Period period = Period.today;
  bool unexpected = false;
  String? reason;
  bool yearly = false;
  int? helpedEntryId;
  DateTime? lastSpendEnd;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    final a = widget.args;
    income = a.income;
    final e = a.edit;
    if (e != null) {
      income = isIncome(e);
      digits = (e.amount ~/ 100).toString();
      kind = e.incomeKind ?? IncomeKind.extra;
      title = e.title;
      note = e.note;
      date = e.date;
      endDate = e.endDate;
      period = e.endDate != null ? Period.custom : Period.today;
      unexpected = e.unexpected;
      reason = e.reason;
      yearly = e.yearly;
      helpedEntryId = e.helpedEntryId;
    } else {
      if (a.amount != null) digits = (a.amount! ~/ 100).toString();
      if (a.date != null) date = dateOnly(a.date!);
      if (a.endDate != null && dateOnly(a.endDate!) != date) {
        endDate = dateOnly(a.endDate!);
        period = Period.custom;
      } else if (a.date != null && date != dateOnly(DateTime.now())) {
        period = Period.custom;
      }
      title = a.title;
      if (a.kind != null) kind = a.kind!;
      if (income && ref.read(settingsProvider).usualSalary > 0 && a.amount == null) {
        // Leave kind as Extra; Salary is one tap away.
      }
    }
    ref.read(repoProvider).lastSpendingEnd().then((d) {
      if (mounted) setState(() => lastSpendEnd = d);
    });
  }

  int get amount => rupeesToPaise(int.tryParse(digits) ?? 0);

  Color _accent(Palette p) => income ? p.forIncome(kind) : (unexpected ? p.over : p.ink);

  Future<void> _pickPeriod(Period pr) async {
    final today = dateOnly(DateTime.now());
    switch (pr) {
      case Period.today:
        setState(() {
          period = pr;
          date = today;
          endDate = null;
        });
      case Period.week:
        setState(() {
          period = pr;
          date = today.subtract(const Duration(days: 6));
          endDate = today;
        });
      case Period.sinceLast:
        final from = lastSpendEnd == null ? today : lastSpendEnd!.add(const Duration(days: 1));
        setState(() {
          period = pr;
          date = from.isAfter(today) ? today : from;
          endDate = date == today ? null : today;
        });
      case Period.custom:
        final r = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: today,
          initialDateRange: DateTimeRange(start: date, end: endDate ?? date),
        );
        if (r == null) return;
        setState(() {
          period = pr;
          date = dateOnly(r.start);
          endDate = r.start == r.end ? null : dateOnly(r.end);
        });
    }
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(context: context, firstDate: DateTime(2020), lastDate: DateTime.now(), initialDate: date);
    if (d != null) setState(() => date = dateOnly(d));
  }

  Future<String?> _ask(String label, String? initial) async {
    final c = TextEditingController(text: initial);
    final p = context.p;
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: p.bg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(22, 22, 22, 22 + MediaQuery.of(ctx).viewInsets.bottom),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: T.title.copyWith(color: p.ink)),
          const SizedBox(height: 14),
          TextField(controller: c, autofocus: true, textCapitalization: TextCapitalization.sentences, onSubmitted: (v) => Navigator.pop(ctx, v)),
          const SizedBox(height: 14),
          BigButton('Done', onTap: () => Navigator.pop(ctx, c.text)),
        ]),
      ),
    );
  }

  Future<void> _save() async {
    if (amount <= 0 || saving) return;
    setState(() => saving = true);
    final repo = ref.read(repoProvider);
    final t = (title?.trim().isEmpty ?? true) ? null : title!.trim();
    final n = (note?.trim().isEmpty ?? true) ? null : note!.trim();
    int id;
    final edit = widget.args.edit;
    if (edit != null) {
      id = edit.id;
      await repo.updateEntry(edit.copyWith(
        kind: income ? EntryKind.income : EntryKind.spending,
        amount: amount,
        incomeKind: Value(income ? kind : null),
        title: Value(t),
        note: Value(n),
        date: date,
        endDate: Value(income ? null : endDate),
        unexpected: !income && unexpected,
        reason: Value(!income && unexpected ? reason : null),
        yearly: !income && yearly,
        helpedEntryId: Value(income && kind == IncomeKind.help ? helpedEntryId : null),
      ));
    } else {
      id = await repo.addEntry(EntriesCompanion.insert(
        kind: income ? EntryKind.income : EntryKind.spending,
        amount: amount,
        incomeKind: Value(income ? kind : null),
        title: Value(t),
        note: Value(n),
        date: date,
        endDate: Value(income ? null : endDate),
        unexpected: Value(!income && unexpected),
        reason: Value(!income && unexpected ? reason : null),
        yearly: Value(!income && yearly),
        helpedEntryId: Value(income && kind == IncomeKind.help ? helpedEntryId : null),
      ));
    }
    await widget.args.onSaved?.call(id);
    if (!mounted) return;
    final label = income ? IncomeKind.label(kind) : (unexpected ? 'Unexpected spending' : 'Spending');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved ${rupees(amount)} · $label')));
    final router = GoRouter.of(context);
    router.pop();
    if (edit == null && income && kind == IncomeKind.salary) {
      await afterSalarySaved(ref, router, date, amount);
    }
  }

  Future<void> _delete() async {
    final e = widget.args.edit!;
    final repo = ref.read(repoProvider);
    final messenger = ScaffoldMessenger.of(context);
    await repo.deleteEntry(e.id);
    if (!mounted) return;
    context.pop();
    messenger.showSnackBar(SnackBar(
      content: Text('Deleted ${rupees(e.amount)}'),
      action: SnackBarAction(label: 'Undo', onPressed: () => repo.restoreEntry(e)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final accent = _accent(p);
    final today = dateOnly(DateTime.now());
    String dateLabel(DateTime d) => d == today ? 'Today' : shortDate(d);

    final options = <Widget>[
      if (widget.args.sourceText != null)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: p.surface, borderRadius: BorderRadius.circular(14)),
          child: Text('“${widget.args.sourceText}”', style: T.label.copyWith(color: p.ink, fontWeight: FontWeight.w500, height: 1.4), maxLines: 3, overflow: TextOverflow.ellipsis),
        ),
      if (income) ...[
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final k in IncomeKind.all)
            Pill(IncomeKind.label(k), selected: kind == k, color: p.forIncome(k) == p.muted ? p.ink : p.forIncome(k), onTap: () => setState(() => kind = k)),
        ]),
        Text(_kindHint(kind), style: T.label.copyWith(color: p.muted, fontWeight: FontWeight.w500)),
        if (kind == IncomeKind.help) ..._helpPicker(p),
        Wrap(spacing: 8, runSpacing: 8, children: [
          Pill(title == null || title!.isEmpty ? (kind == IncomeKind.salary ? '+ Label' : '+ Who from') : 'From $title', outlined: true,
              onTap: () async {
            final v = await _ask(kind == IncomeKind.salary ? 'Label' : 'Who is it from?', title);
            if (v != null) setState(() => title = v);
          }),
          Pill(dateLabel(date), outlined: true, icon: Icons.calendar_today_rounded, onTap: _pickDate),
          Pill(note == null || note!.isEmpty ? '+ Note' : note!, outlined: true, onTap: () async {
            final v = await _ask('Note', note);
            if (v != null) setState(() => note = v);
          }),
        ]),
      ] else ...[
        Wrap(spacing: 8, runSpacing: 8, children: [
          Pill('Today', selected: period == Period.today, onTap: () => _pickPeriod(Period.today)),
          Pill('This week', selected: period == Period.week, onTap: () => _pickPeriod(Period.week)),
          Pill('Since last entry', selected: period == Period.sinceLast, onTap: () => _pickPeriod(Period.sinceLast)),
          Pill(period == Period.custom ? (endDate == null ? dateLabel(date) : rangeLabel(date, endDate!)) : 'Pick dates',
              selected: period == Period.custom, icon: Icons.date_range_rounded, onTap: () => _pickPeriod(Period.custom)),
        ]),
        if (period != Period.custom && endDate != null)
          Text('Covers ${rangeLabel(date, endDate!)}', style: T.label.copyWith(color: p.muted)),
        Wrap(spacing: 8, runSpacing: 8, children: [
          Pill(title == null || title!.isEmpty ? '+ Label' : title!, outlined: true, onTap: () async {
            final v = await _ask('Label', title);
            if (v != null) setState(() => title = v);
          }),
        ]),
        _ToggleRow(
          title: 'Unexpected?',
          subtitle: 'Medical, vehicle, insurance… kept apart from normal spending',
          value: unexpected,
          color: p.over,
          onChanged: (v) => setState(() {
            unexpected = v;
            reason ??= v ? 'other' : null;
          }),
        ),
        if (unexpected) ...[
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final r in Reasons.all)
              Pill(Reasons.label(r), selected: reason == r, color: p.over, onTap: () => setState(() => reason = r)),
          ]),
          _ToggleRow(
            title: 'Comes back every year',
            subtitle: amount > 0 ? 'Set aside ${rupees(amount ~/ 12)} a cycle so next year is planned' : 'Tally will suggest a monthly set-aside',
            value: yearly,
            onChanged: (v) => setState(() => yearly = v),
          ),
        ],
      ],
    ];

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              _Tab('In', income, () => setState(() => income = true)),
              const SizedBox(width: 18),
              _Tab('Out', !income, () => setState(() => income = false)),
              const Spacer(),
              if (widget.args.edit != null)
                IconButton(onPressed: _delete, icon: Icon(Icons.delete_outline_rounded, color: p.muted), tooltip: 'Delete'),
              IconButton(onPressed: () => context.pop(), icon: Icon(Icons.close_rounded, color: p.muted), tooltip: 'Close'),
            ]),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text.rich(TextSpan(children: [
                TextSpan(text: digits.isEmpty ? '0' : rupees(amount, symbol: false), style: TextStyle(color: digits.isEmpty ? p.line : accent)),
                TextSpan(text: '|', style: TextStyle(color: p.line, fontWeight: FontWeight.w300)),
              ]), style: T.huge.copyWith(fontSize: 58)),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  for (final w in options) Padding(padding: const EdgeInsets.only(bottom: 12), child: w),
                ]),
              ),
            ),
            Keypad(onKey: (k) => setState(() => digits = applyKey(digits, k))),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: GoButton(onTap: amount > 0 ? _save : null, color: accent, icon: widget.args.edit != null ? Icons.check_rounded : Icons.arrow_forward_rounded),
            ),
          ]),
        ),
      ),
    );
  }

  List<Widget> _helpPicker(Palette p) {
    final cutoff = DateTime.now().subtract(const Duration(days: 60));
    final spends = (ref.watch(entriesProvider).value ?? const [])
        .where((e) => !isIncome(e) && effectiveDate(e).isAfter(cutoff))
        .toList()
      ..sort((a, b) {
        if (a.unexpected != b.unexpected) return a.unexpected ? -1 : 1;
        return effectiveDate(b).compareTo(effectiveDate(a));
      });
    if (spends.isEmpty) return const [];
    return [
      const CapsLabel('What did this help with?'),
      for (final e in spends.take(4))
        InkWell(
          onTap: () => setState(() => helpedEntryId = helpedEntryId == e.id ? null : e.id),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: p.line))),
            child: Row(children: [
              Icon(helpedEntryId == e.id ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                  color: helpedEntryId == e.id ? p.help : p.line, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(e.title ?? 'Spending', style: T.body.copyWith(color: p.ink)),
                  Text(
                    '${e.unexpected ? 'Unexpected · ' : ''}${e.endDate != null ? rangeLabel(e.date, e.endDate!) : shortDate(e.date)}',
                    style: T.label.copyWith(color: p.muted, fontWeight: FontWeight.w500),
                  ),
                ]),
              ),
              Text(rupees(e.amount, symbol: false), style: T.bodyBold.copyWith(color: p.ink)),
            ]),
          ),
        ),
    ];
  }

  String _kindHint(String k) => switch (k) {
        IncomeKind.salary => 'Your regular pay.',
        IncomeKind.extra => 'Pocket money, gifts, refunds, side work.',
        IncomeKind.help => 'Someone helped you through a tough month. Not paid back.',
        _ => 'Money you’ll pay back. It stays on a “to repay” list.',
      };
}

class _Tab extends StatelessWidget {
  const _Tab(this.label, this.on, this.onTap);
  final String label;
  final bool on;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Text(label, style: T.title.copyWith(fontSize: 28, color: on ? context.p.ink : context.p.line)),
      );
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({required this.title, required this.subtitle, required this.value, required this.onChanged, this.color});
  final String title, subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return Row(children: [
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: T.body.copyWith(color: p.ink, fontSize: 15)),
          Text(subtitle, style: T.label.copyWith(color: p.muted, fontWeight: FontWeight.w500)),
        ]),
      ),
      Switch(
        value: value,
        onChanged: onChanged,
        trackColor: color == null ? null : WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? color : p.line),
      ),
    ]);
  }
}
