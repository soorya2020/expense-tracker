import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/money.dart';
import '../../data/daily.dart';
import '../../shared/motion.dart';

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
                  WidgetSpan(
                    alignment: PlaceholderAlignment.baseline,
                    baseline: TextBaseline.alphabetic,
                    child: CountUp(d.average, format: rupees, ms: 900, style: T.title.copyWith(color: p.ink)),
                  ),
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
          child: _AnimatedBars(
            d: d,
            hasLine: hasLine,
            builder: (values, perDay, peak, reveal) => CustomPaint(
            size: Size.infinite,
            painter: _BarsPainter(
              d: d,
              values: values,
              perDay: perDay,
              peak: peak,
              reveal: reveal,
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
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: f.clamp(0.0, 1.0)),
          duration: motion(context, 900),
          curve: motionCurve,
          builder: (_, v, _) => LinearProgressIndicator(value: v, minHeight: 6, color: color, backgroundColor: p.line),
        ),
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
    required this.values,
    required this.perDay,
    required this.peak,
    required this.reveal,
  });
  final DailySpend d;
  final List<double> values;
  final double perDay, peak, reveal;
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
      final dayH = (values[i] * scale).clamp(0.0, h);
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

    if (lineColor != null && reveal > 0) {
      canvas.save();
      canvas.clipRect(Rect.fromLTWH(0, 0, size.width * reveal, size.height));
      final y = size.height - perDay * scale;
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
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _BarsPainter old) => true;
}

/// The peak a chart of [d] is scaled to.
double _peakOf(DailySpend d, bool hasLine) {
  var peak = 0.0;
  for (var i = 0; i < d.dayNumber; i++) {
    if (d.daily[i] > peak) peak = d.daily[i];
  }
  if (hasLine && d.perDayLeft > peak) peak = d.perDayLeft.toDouble();
  return peak <= 0 ? 1 : peak;
}

/// Grows the bars in from left to right the first time, then glides between
/// values when an entry is added or removed.
class _AnimatedBars extends StatefulWidget {
  const _AnimatedBars({required this.d, required this.hasLine, required this.builder});
  final DailySpend d;
  final bool hasLine;
  final Widget Function(List<double> values, double perDay, double peak, double reveal) builder;
  @override
  State<_AnimatedBars> createState() => _AnimatedBarsState();
}

class _AnimatedBarsState extends State<_AnimatedBars> with SingleTickerProviderStateMixin {
  late final c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
  late List<double> from = List.filled(widget.d.length, 0);
  late double fromPerDay = widget.d.perDayLeft.toDouble(), fromPeak = _peakOf(widget.d, widget.hasLine);
  bool first = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (c.isDismissed && !c.isAnimating) {
      if (reduceMotion(context)) {
        c.value = 1;
      } else {
        c.forward();
      }
    }
  }

  @override
  void didUpdateWidget(_AnimatedBars old) {
    super.didUpdateWidget(old);
    final a = old.d, b = widget.d;
    final same = a.length == b.length && a.perDayLeft == b.perDayLeft && a.dayNumber == b.dayNumber &&
        List.generate(a.length, (i) => a.daily[i] == b.daily[i]).every((x) => x);
    if (same) return;
    // Start from what is on screen now.
    final now = _frame(old.d, old.hasLine);
    from = a.length == b.length ? now.$1 : List.filled(b.length, 0);
    fromPerDay = now.$2;
    fromPeak = now.$3;
    first = false;
    c.duration = const Duration(milliseconds: 600);
    if (reduceMotion(context)) {
      c.value = 1;
    } else {
      c.forward(from: 0);
    }
  }

  (List<double>, double, double, double) _frame(DailySpend d, bool hasLine) {
    final t = c.value, n = d.length;
    double ease(double x) => Curves.easeOutCubic.transform(x.clamp(0.0, 1.0));
    final values = [
      for (var i = 0; i < n; i++)
        from.length == n
            ? from[i] + (d.daily[i] - from[i]) * ease(first ? (t - .45 * i / n) / .55 : t)
            : d.daily[i],
    ];
    final e = ease(t);
    final peak = fromPeak + (_peakOf(d, hasLine) - fromPeak) * e;
    final perDay = fromPerDay + (d.perDayLeft - fromPerDay) * e;
    final reveal = first ? ease((t - .3) / .6) : 1.0;
    return (values, perDay, peak, reveal);
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: c,
        builder: (_, _) {
          final f = _frame(widget.d, widget.hasLine);
          return widget.builder(f.$1, f.$2, f.$3, f.$4);
        },
      );
}
