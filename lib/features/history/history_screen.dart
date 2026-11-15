import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/money.dart';
import '../../data/repo.dart';
import '../../shared/widgets.dart';
import '../entry/add_entry_screen.dart';

enum _Filter { all, income, spending }

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});
  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  _Filter f = _Filter.all;

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final views = ref.watch(cycleViewsProvider);
    final repo = ref.read(repoProvider);

    final children = <Widget>[];
    for (final v in views) {
      final list = v.entries.where((e) => switch (f) {
            _Filter.all => true,
            _Filter.income => isIncome(e),
            _Filter.spending => !isIncome(e),
          });
      if (list.isEmpty && !v.isCurrent) continue;
      final s = v.stats;
      children.add(Padding(
        padding: const EdgeInsets.only(top: 22, bottom: 4),
        child: Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
          Text(rangeLabel(v.start, v.end), style: T.bodyBold.copyWith(color: p.ink, fontSize: 15)),
          if (v.supported) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: p.helpSoft, borderRadius: BorderRadius.circular(99)),
              child: Text('Supported', style: T.caps.copyWith(color: p.help, fontSize: 10)),
            ),
          ],
          const Spacer(),
          GestureDetector(
            onTap: v.isCurrent ? null : () => context.push('/report/${v.start.millisecondsSinceEpoch}'),
            child: Text(
              v.isCurrent ? 'now' : '${s.net >= 0 ? 'Saved' : 'Over'} ${rupees(s.net.abs(), symbol: false)} · Report ›',
              style: T.label.copyWith(color: v.isCurrent ? p.muted : (s.net >= 0 ? p.salary : p.over), fontWeight: FontWeight.w800),
            ),
          ),
        ]),
      ));
      for (final e in list) {
        children.add(Dismissible(
          key: ValueKey('e${e.id}'),
          direction: DismissDirection.endToStart,
          background: const DeleteSwipeBackground(),
          onDismissed: (_) async {
            final messenger = ScaffoldMessenger.of(context);
            await repo.deleteEntry(e.id);
            messenger.showSnackBar(SnackBar(
              content: Text('Deleted ${rupees(e.amount)}'),
              action: SnackBarAction(label: 'Undo', onPressed: () => repo.restoreEntry(e)),
            ));
          },
          child: EntryRow(e, onTap: () => context.push('/add', extra: AddArgs(edit: e))),
        ));
      }
    }

    return Scaffold(
      appBar: AppBar(leading: const BackButton(), actions: [
        TextButton(
          onPressed: () => context.push('/big-picture'),
          child: Text('Big picture  ›', style: T.label.copyWith(color: p.salary, fontWeight: FontWeight.w800, fontSize: 13)),
        ),
        const SizedBox(width: 8),
      ]),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 40),
        children: [
          Text('History', style: T.title.copyWith(color: p.ink)),
          const SizedBox(height: 14),
          Wrap(spacing: 8, children: [
            Pill('All', selected: f == _Filter.all, onTap: () => setState(() => f = _Filter.all)),
            Pill('Income', selected: f == _Filter.income, onTap: () => setState(() => f = _Filter.income)),
            Pill('Spending', selected: f == _Filter.spending, onTap: () => setState(() => f = _Filter.spending)),
          ]),
          if (children.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Text('Nothing here yet.', style: T.body.copyWith(color: p.muted)),
            ),
          ...children,
          if (children.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 18),
              child: Text('Tap to edit. Swipe left to delete.', style: T.label.copyWith(color: p.muted)),
            ),
        ],
      ),
    );
  }
}
