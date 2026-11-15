import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/money.dart';
import '../../data/daily.dart';

/// Home's progress card: a bar for each day of the cycle, the safe daily line,
/// and how far through the cycle and the salary you are.
class DailyCard extends StatelessWidget {
  const DailyCard({super.key, required this.d, required this.start, required this.end});
  final DailySpend d;
  final DateTime start, end;

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final (chip, chipFg, chipBg) = switch (d.pace) {
      Pace.onTrack => ('On track', p.help, p.helpSoft),
      Pace.bitFast => ('A bit fast', p.extra, p.extraSoft),
      Pace.tooFast => ('Too fast', p.over, p.overSoft),
      Pace.pastSalary => ('Past salary', p.over, p.overSoft),
      Pace.noSalary => ('', p.muted, p.surface),
    };
    final hasLine = d.pace != Pace.noSalary && d.pace != Pace.pastSalary;
    final fixedNote = d.fixedTotal > 0 ? 'Average a day, not counting rent and bills' : 'Average a day so far';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: dark ? p.surface : p.bg,
        borderRadius: BorderRadius.circular(22),
        border: dark ? null : Border.all(color: p.line),
        boxShadow: dark ? null : const [BoxShadow(color: Color(0x12000000), blurRadius: 18, offset: Offset(0, 6))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('SPENT PER DAY', style: T.caps.copyWith(color: p.muted)),
              const SizedBox(height: 4),
              Text.rich(
                TextSpan(children: [
                  TextSpan(text: rupees(d.average)),
                  TextSpan(text: '  a day', style: T.body.copyWith(letterSpacing: 0, color: p.muted, fontWeight: FontWeight.w700, fontSize: 15)),
                ]),
                style: T.title.copyWith(color: p.ink),
              ),
              const SizedBox(height: 2),
              Text(fixedNote, style: T.label.copyWith(color: p.muted)),
            ]),
          ),
          if (chip.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: chipBg, borderRadius: BorderRadius.circular(99)),
              child: Text(chip, style: T.label.copyWith(color: chipFg, fontWeight: FontWeight.w800)),
            ),
        ]),
        const SizedBox(height: 14),
        SizedBox(
          height: 110,
          child: CustomPaint(
            size: Size.infinite,
            painter: _BarsPainter(
              d: d,
              ink: p.ink,
              today: p.salary,
              faint: p.line,
              fixedColor: p.muted.withValues(alpha: 0.35),
              lineColor: hasLine ? p.salary : null,
              labelStyle: T.label.copyWith(color: p.muted, fontSize: 10, fontWeight: FontWeight.w700),
              lineLabel: hasLine ? '${rupees(d.perDayLeft)}/day left' : null,
              lineLabelStyle: T.label.copyWith(color: p.salary, fontSize: 11, fontWeight: FontWeight.w800),
              bg: dark ? p.surface : p.bg,
            ),
          ),
        ),
        const SizedBox(height: 6),
        // "today" sits under today's bar unless it would hit the dates at the ends.
        LayoutBuilder(builder: (_, c) {
          final x = c.maxWidth * (d.dayNumber - 0.5) / d.length;
          final showToday = x > 52 && x < c.maxWidth - 52;
          return SizedBox(
            height: 16,
            child: Stack(clipBehavior: Clip.none, children: [
              Positioned(left: 0, child: Text(shortDate(start), style: T.label.copyWith(color: p.muted, fontSize: 11))),
              Positioned(right: 0, child: Text(shortDate(end), style: T.label.copyWith(color: p.muted, fontSize: 11))),
              if (showToday)
                Positioned(
                  left: x - 20,
                  width: 40,
                  child: Text('today', textAlign: TextAlign.center, style: T.label.copyWith(color: p.salary, fontSize: 11, fontWeight: FontWeight.w800)),
                ),
            ]),
          );
        }),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: _Mini(label: 'DAYS', value: '${d.dayNumber}/${d.length}', f: d.dayNumber / d.length, color: p.ink)),
          const SizedBox(width: 16),
          Expanded(
            child: _Mini(
              label: 'SALARY USED',
              value: d.salary <= 0 ? 'no salary yet' : '${(d.spent * 100 / d.salary).round()}%',
              f: d.salaryUsed,
              color: d.pace == Pace.pastSalary ? p.over : p.salary,
            ),
          ),
        ]),
      ]),
    );
  }
}

class _Mini extends StatelessWidget {
  const _Mini({required this.label, required this.value, required this.f, required this.color});
  final String label, value;
  final double f;
  final Color color;
  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(label, style: T.caps.copyWith(color: p.muted, fontSize: 10)),
        const Spacer(),
        Text(value, style: T.bodyBold.copyWith(color: p.ink, fontSize: 13)),
      ]),
      const SizedBox(height: 6),
      ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: LinearProgressIndicator(value: f.clamp(0.0, 1.0), minHeight: 6, color: color, backgroundColor: p.line),
      ),
    ]);
  }
}

class _BarsPainter extends CustomPainter {
  _BarsPainter({
    required this.d,
    required this.ink,
    required this.today,
    required this.faint,
    required this.fixedColor,
    required this.lineColor,
    required this.labelStyle,
    required this.lineLabel,
    required this.lineLabelStyle,
    required this.bg,
  });
  final DailySpend d;
  final Color ink, today, faint, fixedColor, bg;
  final Color? lineColor;
  final TextStyle labelStyle, lineLabelStyle;
  final String? lineLabel;

  @override
  void paint(Canvas canvas, Size size) {
    final n = d.length;
    final slot = size.width / n;
    final gap = (slot * 0.28).clamp(1.0, 4.0);
    final w = slot - gap;
    const top = 16.0; // room for labels
    final h = size.height - top;

    var peak = 0.0;
    for (var i = 0; i < d.dayNumber; i++) {
      if (d.daily[i] > peak) peak = d.daily[i];
    }
    if (lineColor != null && d.perDayLeft > peak) peak = d.perDayLeft.toDouble();
    if (peak <= 0) peak = 1;
    final scale = h / (peak * 1.25);

    final r = Radius.circular((w / 2).clamp(1.0, 3.0));
    String? shownLabel;
    for (var i = 0; i < n; i++) {
      final x = i * slot + gap / 2;
      if (i >= d.dayNumber) {
        canvas.drawRRect(RRect.fromLTRBR(x, size.height - 3, x + w, size.height, r), Paint()..color = faint);
        continue;
      }
      final isToday = i == d.dayNumber - 1;
      final dayH = (d.daily[i] * scale).clamp(0.0, h);
      if (d.fixed[i] > 0) {
        // Rent and bills: a full-height pale bar with a break, labelled once.
        canvas.drawRRect(RRect.fromLTRBR(x, top, x + w, size.height, r), Paint()..color = fixedColor);
        final y = top + 10;
        canvas.drawLine(Offset(x - 1, y + 3), Offset(x + w + 1, y - 1), Paint()
          ..color = bg
          ..strokeWidth = 2.5);
        if (shownLabel == null) {
          shownLabel = d.fixedLabel[i] ?? 'Bills';
          final tp = TextPainter(text: TextSpan(text: shownLabel, style: labelStyle), textDirection: TextDirection.ltr)..layout();
          final lx = (x + w + 4).clamp(0.0, size.width - tp.width);
          tp.paint(canvas, Offset(lx, top - 2));
        }
      }
      if (dayH > 0) {
        final barH = dayH < 3 ? 3.0 : dayH;
        canvas.drawRRect(
          RRect.fromLTRBR(x, size.height - barH, x + w, size.height, r),
          Paint()..color = isToday ? today : ink,
        );
      } else {
        canvas.drawRRect(RRect.fromLTRBR(x, size.height - 3, x + w, size.height, r),
            Paint()..color = isToday ? today : faint);
      }
    }

    if (lineColor != null) {
      final y = size.height - d.perDayLeft * scale;
      final paint = Paint()
        ..color = lineColor!
        ..strokeWidth = 1.5;
      for (var x = 0.0; x < size.width; x += 7) {
        canvas.drawLine(Offset(x, y), Offset((x + 4).clamp(0, size.width), y), paint);
      }
      final tp = TextPainter(text: TextSpan(text: lineLabel, style: lineLabelStyle), textDirection: TextDirection.ltr)..layout();
      final rect = Rect.fromLTWH(size.width - tp.width - 6, y - tp.height - 3, tp.width + 6, tp.height + 2);
      canvas.drawRect(rect, Paint()..color = bg.withValues(alpha: 0.85));
      tp.paint(canvas, Offset(size.width - tp.width - 3, y - tp.height - 2));
    }
  }

  @override
  bool shouldRepaint(covariant _BarsPainter old) => true;
}
