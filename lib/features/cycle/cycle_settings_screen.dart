import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/cycle_math.dart';
import '../../core/money.dart';
import '../../shared/widgets.dart';
import 'day_strip.dart';

class CycleSettingsScreen extends ConsumerWidget {
  const CycleSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.p;
    final s = ref.watch(settingsProvider);
    final cur = ref.watch(currentCycleProvider);
    final day = s.cycleDay;
    DateTime? nextStart = cur == null ? null : cur.end.add(const Duration(days: 1));
    return Scaffold(
      appBar: AppBar(leading: const BackButton()),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 40),
        children: [
          Text('Your cycle starts on the', style: T.label.copyWith(color: p.muted, fontSize: 14)),
          const SizedBox(height: 4),
          Text(day == lastDay ? 'Last day' : ordinal(day), style: T.huge.copyWith(color: p.ink)),
          const SizedBox(height: 18),
          DayStrip(selected: day, onSelect: (d) => ref.read(repoProvider).changeCycleDay(d)),
          const SizedBox(height: 18),
          if (cur != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: p.surface, borderRadius: BorderRadius.circular(16)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(rangeLabel(cur.start, cur.end), style: T.bodyBold.copyWith(color: p.ink, fontSize: 15)),
                const SizedBox(height: 4),
                Text(
                  'Next cycle: ${rangeLabel(nextStart!, cycleEndFor(nextStart, day))}. '
                  'A new day takes effect from your next cycle. Past cycles and reports never change.',
                  style: T.label.copyWith(color: p.muted, fontWeight: FontWeight.w500, height: 1.4),
                ),
              ]),
            ),
          const SizedBox(height: 10),
          LineRow(
            title: 'Follow my salary',
            subtitle: 'If salary comes up to 7 days early or late, ask to move the cycle',
            trailing: Switch(value: s.followSalary, onChanged: s.setFollowSalary),
          ),
          LineRow(
            title: 'Report notification',
            subtitle: 'First morning of each cycle · 9:00 AM',
            trailing: Switch(value: s.reportNotify, onChanged: s.setReportNotify),
          ),
        ],
      ),
    );
  }
}
