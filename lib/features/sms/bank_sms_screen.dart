import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/cycle_math.dart';
import '../../core/money.dart';
import '../../data/db.dart';
import '../../shared/widgets.dart';
import '../entry/add_entry_screen.dart';
import 'sms_service.dart';

/// Only messages from the current pay cycle (from [start] on).
List<BankMessage> cycleSms(List<BankMessage> all, DateTime? start) =>
    start == null ? all : all.where((m) => !m.receivedAt.isBefore(start)).toList();

/// Opens Add with this SMS filled in. Marks the SMS added once saved.
void addFromSms(BuildContext context, WidgetRef ref, BankMessage m) {
  final repo = ref.read(repoProvider);
  final usual = ref.read(settingsProvider).usualSalary;
  final credit = m.direction == 'credit';
  final looksLikeSalary = credit && usual > 0 && (m.amount - usual).abs() * 10 <= usual;
  context.push(
    '/add',
    extra: AddArgs(
      income: credit,
      amount: m.amount,
      date: m.receivedAt,
      title: m.counterparty,
      kind: looksLikeSalary ? IncomeKind.salary : null,
      sourceText: m.rawText,
      onSaved: (id) => repo.setSmsStatus([m.id], 'added', entryId: id),
    ),
  );
}

/// Credits and debits read from bank SMS, ready to add with one tap.
class BankSmsScreen extends ConsumerStatefulWidget {
  const BankSmsScreen({super.key, this.debits = true});
  final bool debits;
  @override
  ConsumerState<BankSmsScreen> createState() => _BankSmsScreenState();
}

class _BankSmsScreenState extends ConsumerState<BankSmsScreen> {
  late bool debits = widget.debits;
  final picked = <int>{};
  bool? allowed;
  bool fetching = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh({bool full = false}) async {
    final ok = await hasSmsPermission();
    if (mounted) setState(() => allowed = ok);
    if (!ok) return;
    if (mounted) setState(() => fetching = true);
    try {
      final n = await scanSms(ref.read(repoProvider), ref.read(settingsProvider), full: full);
      if (full && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(n == 0 ? 'No bank messages found in this cycle.' : 'Checked $n bank messages from this cycle.')),
        );
      }
    } finally {
      if (mounted) setState(() => fetching = false);
    }
  }

  Future<void> _allow() async {
    final settings = ref.read(settingsProvider);
    final ok = await askSmsPermission();
    await settings.setSmsEnabled(ok);
    if (mounted) setState(() => allowed = ok);
    if (ok) {
      await scanSms(ref.read(repoProvider), settings);
    } else if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('SMS access is off. You can allow it in Android settings for Tally.')));
    }
  }

  void _addPicked(List<BankMessage> all) {
    final sel = all.where((m) => picked.contains(m.id)).toList()..sort((a, b) => a.receivedAt.compareTo(b.receivedAt));
    if (sel.isEmpty) return;
    final repo = ref.read(repoProvider);
    final ids = sel.map((m) => m.id).toList();
    context.push(
      '/add',
      extra: AddArgs(
        income: false,
        amount: sel.fold<int>(0, (a, m) => a + m.amount),
        date: sel.first.receivedAt,
        endDate: sel.last.receivedAt,
        sourceText: '${sel.length} bank debits added as one',
        onSaved: (id) => repo.setSmsStatus(ids, 'added', entryId: id),
      ),
    );
    setState(picked.clear);
  }

  Future<void> _more(BankMessage m) async {
    final p = context.p;
    final repo = ref.read(repoProvider);
    final settings = ref.read(settingsProvider);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: p.bg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('From ${m.sender}', style: T.label.copyWith(color: p.muted)),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: p.surface, borderRadius: BorderRadius.circular(16)),
                child: Text(m.rawText, style: T.body.copyWith(color: p.ink, height: 1.4)),
              ),
              const SizedBox(height: 14),
              if (m.status != 'added')
                LineRow(
                  title: m.status == 'skipped' ? 'Bring it back' : 'Skip this one',
                  onTap: () {
                    repo.setSmsStatus([m.id], m.status == 'skipped' ? 'new' : 'skipped');
                    Navigator.pop(ctx);
                  },
                ),
              if (m.account != null && m.status != 'added')
                LineRow(
                  title: 'Always skip ${m.account}',
                  subtitle: 'For accounts that aren’t yours to track, like a business card',
                  onTap: () async {
                    await settings.addSmsSkipAccount(m.account!);
                    final all = ref.read(bankSmsProvider).value ?? const [];
                    await repo.setSmsStatus(
                      all.where((x) => x.account == m.account && x.status == 'new').map((x) => x.id).toList(),
                      'skipped',
                    );
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final from = ref.watch(currentCycleProvider)?.start;
    final all = cycleSms(ref.watch(bankSmsProvider).value ?? const <BankMessage>[], from);
    final list = all.where((m) => m.direction == (debits ? 'debit' : 'credit')).toList();
    final newOnes = list.where((m) => m.status == 'new').toList();
    final newCredits = all.where((m) => m.direction == 'credit' && m.status == 'new').length;
    final newDebits = all.where((m) => m.direction == 'debit' && m.status == 'new').length;
    final selecting = picked.isNotEmpty;
    final intro = allowed == false && !ref.watch(settingsProvider).smsEnabled && all.isEmpty;
    final pickedTotal = all.where((m) => picked.contains(m.id)).fold<int>(0, (a, m) => a + m.amount);
    final day = DateFormat('EEE d MMM');
    final time = DateFormat('h:mm a');

    final rows = <Widget>[];
    DateTime? lastDay;
    for (final m in list) {
      final d = dateOnly(m.receivedAt);
      if (d != lastDay) {
        lastDay = d;
        rows.add(
          Padding(
            padding: const EdgeInsets.only(top: 18, bottom: 4),
            child: Text(d == dateOnly(DateTime.now()) ? 'Today' : day.format(d), style: T.caps.copyWith(color: p.muted)),
          ),
        );
      }
      rows.add(
        _SmsRow(
          m: m,
          selected: picked.contains(m.id),
          onTap: () {
            if (selecting && debits && m.status == 'new') {
              setState(() => picked.contains(m.id) ? picked.remove(m.id) : picked.add(m.id));
            } else if (!selecting && m.status == 'new') {
              addFromSms(context, ref, m);
            } else if (!selecting) {
              _more(m);
            }
          },
          onLongPress: debits && m.status == 'new' ? () => setState(() => picked.add(m.id)) : () => _more(m),
          onMore: () => _more(m),
          time: time.format(m.receivedAt),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: selecting
            ? IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => setState(picked.clear))
            : const BackButton(),
        title: selecting ? Text('${picked.length} picked', style: T.bodyBold.copyWith(color: p.ink, fontSize: 17)) : null,
        actions: [
          if (!selecting && allowed == true)
            fetching
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                : IconButton(tooltip: 'Fetch SMS again', icon: const Icon(Icons.refresh_rounded), onPressed: () => _refresh(full: true)),
        ],
      ),
      body: intro
          ? _Intro(onAllow: _allow)
          : RefreshIndicator(
              onRefresh: () => _refresh(full: true),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 120),
                children: [
                  Text('Bank SMS', style: T.title.copyWith(color: p.ink)),
                  if (from != null) ...[
                    const SizedBox(height: 4),
                    Text('This cycle · ${rangeLabel(from, ref.watch(currentCycleProvider)!.end)}', style: T.label.copyWith(color: p.muted)),
                  ],
                  const SizedBox(height: 14),
                  const SizedBox(height: 14),
                  Text(
                    newOnes.isEmpty
                        ? (list.isEmpty ? 'No bank ${debits ? 'debits' : 'credits'} in this cycle yet.' : 'All caught up.')
                        : '${newOnes.length} new · ${rupees(newOnes.fold<int>(0, (a, m) => a + m.amount))}',
                    style: T.sentence.copyWith(color: p.ink),
                  ),
                  if (debits && newOnes.length > 1 && !selecting) ...[
                    const SizedBox(height: 4),
                    Text('Long-press to pick several and add them as one spending.', style: T.label.copyWith(color: p.muted)),
                  ],
                  if (allowed == false) ...[
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: _allow,
                      child: Text('SMS access is off. Tap to allow ›', style: T.bodyBold.copyWith(color: p.over)),
                    ),
                  ],
                  ...rows,
                ],
              ),
            ),
      bottomNavigationBar: selecting
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 12),
                child: BigButton('Add ${picked.length} as one · ${rupees(pickedTotal)}', onTap: () => _addPicked(all)),
              ),
            )
          : intro
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 12),
                child: SmsTabs(
                  debits: debits,
                  credits: 'Credits${newCredits > 0 ? ' · $newCredits' : ''}',
                  debitsLabel: 'Debits${newDebits > 0 ? ' · $newDebits' : ''}',
                  onChanged: (d) => setState(() {
                    debits = d;
                    picked.clear();
                  }),
                ),
              ),
            ),
    );
  }
}

/// Credits / Debits switch at the bottom of the page, in thumb reach.
class SmsTabs extends StatelessWidget {
  const SmsTabs({required this.debits, required this.credits, required this.debitsLabel, required this.onChanged});
  final bool debits;
  final String credits, debitsLabel;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) {
    final p = context.p;
    Widget seg(String label, bool on, bool value) => Expanded(
      child: GestureDetector(
        onTap: () => onChanged(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: on ? p.bg : Colors.transparent,
            borderRadius: BorderRadius.circular(99),
            boxShadow: on ? const [BoxShadow(color: Color(0x22000000), blurRadius: 4, offset: Offset(0, 1))] : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            style: T.bodyBold.copyWith(fontSize: 15, color: on ? p.ink : p.muted),
          ),
        ),
      ),
    );
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: p.surface, borderRadius: BorderRadius.circular(99)),
      child: Row(children: [seg(credits, !debits, false), seg(debitsLabel, debits, true)]),
    );
  }
}

class _SmsRow extends StatelessWidget {
  const _SmsRow({
    required this.m,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
    required this.onMore,
    required this.time,
  });
  final BankMessage m;
  final bool selected;
  final VoidCallback onTap, onLongPress, onMore;
  final String time;

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final credit = m.direction == 'credit';
    final done = m.status != 'new';
    final color = done ? p.muted : (credit ? p.salary : p.ink);
    final sub = [m.account, time, if (m.status == 'added') 'Added', if (m.status == 'skipped') 'Skipped'].whereType<String>().join(' · ');
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? p.salarySoft : null,
          border: Border(bottom: BorderSide(color: p.line)),
        ),
        child: Row(
          children: [
            if (selected) ...[Icon(Icons.check_circle_rounded, color: p.salary, size: 20), const SizedBox(width: 10)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    m.counterparty ?? (credit ? 'Money in' : 'Money out'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: T.body.copyWith(
                      color: done ? p.muted : p.ink,
                      fontSize: 15,
                      decoration: m.status == 'skipped' ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sub,
                    style: T.label.copyWith(color: p.muted, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            Text(
              signed(m.amount, positive: credit),
              style: T.bodyBold.copyWith(color: color, fontSize: 15),
            ),
            if (!done && !selected)
              Padding(
                padding: const EdgeInsets.only(left: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: credit ? p.salarySoft : p.surface, borderRadius: BorderRadius.circular(99)),
                  child: Text(
                    'Add',
                    style: T.label.copyWith(color: credit ? p.salary : p.ink, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Intro extends StatelessWidget {
  const _Intro({required this.onAllow});
  final VoidCallback onAllow;
  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Bank SMS', style: T.title.copyWith(color: p.ink)),
          const SizedBox(height: 14),
          Text(
            'Tally can read the credit and debit messages your bank sends, so you can add them with one tap.',
            style: T.sentence.copyWith(color: p.ink),
          ),
          const SizedBox(height: 14),
          Text(
            'Only bank messages are read. OTPs and personal messages are ignored. Nothing leaves your phone.',
            style: T.body.copyWith(color: p.muted, height: 1.5),
          ),
          const Spacer(),
          BigButton('Allow SMS access', onTap: onAllow),
        ],
      ),
    );
  }
}
