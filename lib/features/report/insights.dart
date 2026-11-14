import 'package:flutter/material.dart';

import '../../app/providers.dart';
import '../../core/money.dart';
import '../../data/db.dart';
import '../../data/repo.dart';

enum CardTone { blue, ink }

enum Visual { none, salaryBar, trend }

/// One story card in a cycle report.
class ReportCard {
  ReportCard({required this.headline, required this.body, this.tone = CardTone.blue, this.badge, this.visual = Visual.none});
  final String headline;
  final String body;
  final CardTone tone;
  final String? badge;
  final Visual visual;
}

String _pct(int part, int whole) => whole == 0 ? '0%' : '${(part * 100 / whole).round()}%';

/// Builds the 3–5 cards for [v]. [older] are the cycles before it, newest first.
List<ReportCard> buildReport(CycleView v, List<CycleView> older) {
  final s = v.stats;
  final cards = <ReportCard>[];

  // 1 · Result (or the supported story)
  if (v.supported && s.help > 0) {
    final who = s.topSource(IncomeKind.help)?.name ?? 'Someone';
    final unexpected = v.entries.where((e) => !isIncome(e) && e.unexpected).toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
    final cause = unexpected.isNotEmpty
        ? '${unexpected.first.title ?? Reasons.label(unexpected.first.reason ?? 'other')} (${rupees(unexpected.first.amount)})'
        : 'Spending of ${rupees(s.spent)}';
    final without = s.net - s.help;
    cards.add(ReportCard(
      tone: CardTone.ink,
      badge: 'Supported cycle',
      headline: '$who got you through.',
      body: s.overSalary > 0
          ? '$cause pushed you ${rupees(s.overSalary)} past your salary. '
              'Without their help you’d have ended at ${without < 0 ? '−' : ''}${rupees(without.abs())}.'
          : '$who sent ${rupees(s.help)} to help this cycle.',
      visual: Visual.salaryBar,
    ));
  } else {
    cards.add(ReportCard(
      headline: s.net >= 0 ? 'You saved ${rupees(s.net)}.' : 'You overspent ${rupees(-s.net)}.',
      body: '${rupees(s.income)} came in and ${rupees(s.spent)} went out.',
      visual: Visual.salaryBar,
    ));
  }

  // 2 · Salary against spending
  if (!s.hasSalary) {
    cards.add(ReportCard(headline: 'No salary was logged this cycle.', body: 'If it came in, add it from History so this report adds up.'));
  } else if (s.overSalary > 0) {
    final by = s.help > 0
        ? 'Help from ${s.topSource(IncomeKind.help)?.name ?? 'others'}'
        : s.extra > 0
            ? 'Extra money from ${s.topSource(IncomeKind.extra)?.name ?? 'outside your pay'} (${rupees(s.extra)})'
            : s.borrowed > 0
                ? 'Borrowed money'
                : 'Your savings';
    cards.add(ReportCard(headline: 'You spent ${rupees(s.overSalary)} more than your salary.', body: '$by filled the gap.'));
  } else {
    cards.add(ReportCard(
      headline: 'You stayed within your salary.',
      body: '${rupees(-s.overSalary)} of your ${rupees(s.salary)} salary was left over.',
    ));
  }

  // 3 · Money from outside your pay, and surprises
  if (s.extra > 0 && !(v.supported && s.help > 0 && s.extra == 0)) {
    final top = s.topSource(IncomeKind.extra);
    cards.add(ReportCard(
      headline: 'Extra was ${_pct(s.extra, s.income)} of what came in.',
      body: top == null ? '${rupees(s.extra)} in total.' : 'Mostly from ${top.name} (${rupees(top.amount)}).',
    ));
  }
  if (s.unexpected > 0) {
    final yearly = v.entries.where((e) => !isIncome(e) && e.yearly).toList();
    cards.add(ReportCard(
      headline: 'Unexpected costs were ${rupees(s.unexpected)}.',
      body: '${_pct(s.unexpected, s.spent)} of this cycle’s spending. '
          '${yearly.isNotEmpty ? '${yearly.first.title ?? 'It'} comes back every year, so set aside ${rupees(yearly.first.amount ~/ 12)} a cycle from now on.' : 'Your regular spending was ${rupees(s.regular)}.'}',
    ));
  }

  // 4 · Trend
  final perDay = s.spent ~/ v.length;
  final prev = older.where((o) => o.stats.spent > 0).firstOrNull;
  var streak = s.hasSalary && s.overSalary <= 0 ? 1 : 0;
  if (streak == 1) {
    for (final o in older) {
      if (o.stats.hasSalary && o.stats.overSalary <= 0) {
        streak++;
      } else {
        break;
      }
    }
  }
  final big = s.biggestSpend;
  final extraLine = [
    if (streak >= 2) 'Within your salary $streak cycles in a row.',
    if (big != null && s.spent > 0 && big.amount * 4 > s.spent)
      'Your biggest lump was ${big.title ?? (big.endDate != null ? rangeLabel(big.date, big.endDate!) : shortDate(big.date))} (${rupees(big.amount)}).',
  ].join(' ');
  if (prev != null && s.spent > 0) {
    final diff = s.spent - prev.stats.spent;
    final pct = (diff.abs() * 100 / prev.stats.spent).round();
    cards.add(ReportCard(
      headline: pct == 0 ? 'About the same as last cycle.' : '$pct% ${diff < 0 ? 'less' : 'more'} than last cycle.',
      body: 'About ${rupees(perDay)} a day. $extraLine'.trim(),
      visual: Visual.trend,
    ));
  } else {
    cards.add(ReportCard(headline: 'About ${rupees(perDay)} a day.', body: extraLine.isEmpty ? 'Next cycle you’ll see how this one compares.' : extraLine, visual: Visual.trend));
  }
  return cards;
}

/// Short line for Home and notifications, e.g. "Saved ₹2,800".
String resultLine(CycleView v) {
  final n = v.stats.net;
  return n >= 0 ? 'Saved ${rupees(n)}' : 'Overspent ${rupees(-n)}';
}

Color toneColor(CardTone t) => t == CardTone.ink ? const Color(0xFF0F1115) : const Color(0xFF2B4CFF);
