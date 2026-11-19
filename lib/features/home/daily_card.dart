import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/money.dart';
import '../../data/categories.dart';
import '../../data/daily.dart';
import '../../shared/motion.dart';

final _dayName = DateFormat('EEE, d MMM');

// Chart geometry, shared by the painter and the tap handling.
const _gutter = 30.0; // room for the ₹ labels on the left
const _top = 16.0; // room for the labels above the bars
const _axis = 30.0; // dates and "today" under the bars

/// Home's progress card: a bar for each day of the cycle split by category,
/// the safe daily line, and how far through the cycle and the salary you are.
/// Tap or drag across the bars to see what a day went on.
class DailyCard extends ConsumerStatefulWidget {
  const DailyCard({super.key, required this.d, required this.start, required this.end});
  final DailySpend d;
  final DateTime start, end;

  @override
  ConsumerState<DailyCard> createState() => _DailyCardState();
}

class _DailyCardState extends ConsumerState<DailyCard> {
  /// The day shown in the panel, as an index into the cycle. Null means the
  /// latest day with spending, so the panel isn't empty first thing in the morning.
  int? picked;

  int get sel => (picked ?? _latest(widget.d)).clamp(0, widget.d.dayNumber - 1);

  static int _latest(DailySpend d) {
    for (var i = d.dayNumber - 1; i >= 0; i--) {
      if (d.items[i].isNotEmpty) return i;
    }
    return d.dayNumber - 1;
  }

  void _pick(int i) {
    i = i.clamp(0, widget.d.dayNumber - 1);
    if (i == sel) return;
    HapticFeedback.selectionClick();
    setState(() => picked = i);
  }

  void _pickAt(double dx, double width) {
    final slot = (width - _gutter) / widget.d.length;
    _pick(((dx - _gutter) / slot).floor());
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.d;
    final p = context.p;
    final settings = ref.watch(settingsProvider);
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
    final order = d.catOrder;
    final cats = <String?, (String, Color)>{
      for (final id in order)
        id: switch (catById(settings, id)) {
          final c? => (c.label, c.color),
          null => ('Untagged', untaggedColor),
        },
    };

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
        Semantics(
          label: 'Spending per day. Tap a bar to see that day by category.',
          child: SizedBox(
            height: 150,
            child: LayoutBuilder(
              builder: (_, c) => GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (e) => _pickAt(e.localPosition.dx, c.maxWidth),
                onHorizontalDragStart: (e) => _pickAt(e.localPosition.dx, c.maxWidth),
                onHorizontalDragUpdate: (e) => _pickAt(e.localPosition.dx, c.maxWidth),
                child: _AnimatedBars(
                  d: d,
                  hasLine: hasLine,
                  builder: (values, perDay, peak, reveal) => CustomPaint(
                    size: Size.infinite,
                    painter: _BarsPainter(
                      d: d,
                      start: widget.start,
                      order: order,
                      colors: {for (final e in cats.entries) e.key: e.value.$2},
                      selected: sel,
                      values: values,
                      perDay: perDay,
                      peak: peak,
                      reveal: reveal,
                      ink: p.ink,
                      today: p.salary,
                      faint: p.line,
                      muted: p.muted,
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
            ),
          ),
        ),
        const SizedBox(height: 8),
        AnimatedSize(
          duration: motion(context, 220),
          curve: motionCurve,
          alignment: Alignment.topCenter,
          child: _DayPanel(
            d: d,
            i: sel,
            date: widget.start.add(Duration(days: sel)),
            cats: cats,
            perDay: hasLine ? d.perDayLeft : null,
            onPrev: sel > 0 ? () => _pick(sel - 1) : null,
            onNext: sel < d.dayNumber - 1 ? () => _pick(sel + 1) : null,
          ),
        ),
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

/// What the picked day went on: its total, how it compares with the safe
/// amount a day, and each category with the entries in it.
class _DayPanel extends StatelessWidget {
  const _DayPanel({
    required this.d,
    required this.i,
    required this.date,
    required this.cats,
    required this.perDay,
    required this.onPrev,
    required this.onNext,
  });
  final DailySpend d;
  final int i;
  final DateTime date;
  final Map<String?, (String, Color)> cats;
  final int? perDay;
  final VoidCallback? onPrev, onNext;

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final total = d.daily[i].round();
    final isToday = i == d.dayNumber - 1;
    final parts = [
      for (final id in cats.keys)
        if ((d.byCat[i][id] ?? 0) >= 50) (id, cats[id]!, d.byCat[i][id]!.round()),
    ];
    final fixedItems = d.items[i].where((x) => x.fixed).toList();

    String itemsOf(Iterable<DayItem> xs) => xs.map((x) {
          final name = x.entry.title ?? 'Spending';
          final amt = rupees(x.amount.round());
          return x.spread ? '$name $amt of ${rupees(x.entry.amount)}' : '$name $amt';
        }).join(' · ');

    Widget row(Color dot, String label, int amount, String items) => Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Container(width: 9, height: 9, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label, style: T.body.copyWith(color: p.ink, fontWeight: FontWeight.w600)),
                if (items.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text(items, style: T.label.copyWith(color: p.muted, height: 1.35)),
                ],
              ]),
            ),
            const SizedBox(width: 8),
            Text(rupees(amount), style: T.bodyBold.copyWith(color: p.ink)),
          ]),
        );

    String? versus;
    Color? versusColor;
    if (perDay != null && total > 0) {
      final diff = total - perDay!;
      versus = diff > 0 ? '${rupees(diff)} over ${rupees(perDay!)} a day' : '${rupees(-diff)} under ${rupees(perDay!)} a day';
      versusColor = diff > 0 ? p.over : p.help;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: p.line))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          _NavButton(icon: Icons.chevron_left_rounded, label: 'Previous day', onTap: onPrev),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(children: [
                TextSpan(text: _dayName.format(date)),
                if (isToday) TextSpan(text: ' · today', style: TextStyle(color: p.salary)),
              ]),
              style: T.bodyBold.copyWith(color: p.ink, fontSize: 15),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(rupees(total), style: T.bodyBold.copyWith(color: p.ink, fontSize: 18)),
          const SizedBox(width: 8),
          _NavButton(icon: Icons.chevron_right_rounded, label: 'Next day', onTap: onNext),
        ]),
        if (versus != null) ...[
          const SizedBox(height: 4),
          Text(versus, style: T.label.copyWith(color: versusColor, fontWeight: FontWeight.w700)),
        ],
        if (parts.isNotEmpty) ...[
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 8,
              child: Row(children: [
                for (final (k, x) in parts.indexed) ...[
                  if (k > 0) const SizedBox(width: 2),
                  Expanded(flex: x.$3.clamp(1, 1 << 30), child: Container(color: x.$2.$2)),
                ],
              ]),
            ),
          ),
          const SizedBox(height: 2),
          for (final x in parts)
            row(x.$2.$2, x.$2.$1, x.$3, itemsOf(d.items[i].where((it) => !it.fixed && it.cat == x.$1))),
        ] else
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('Nothing spent on this day.', style: T.label.copyWith(color: p.muted)),
          ),
        if (fixedItems.isNotEmpty)
          row(p.muted.withValues(alpha: 0.35), 'Rent and bills, not in the average', d.fixed[i].round(), itemsOf(fixedItems)),
      ]),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return Semantics(
      button: true,
      label: label,
      child: Material(
        shape: CircleBorder(side: BorderSide(color: p.line)),
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 32,
            height: 32,
            child: Icon(icon, size: 20, color: onTap == null ? p.line : p.ink),
          ),
        ),
      ),
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
    required this.start,
    required this.order,
    required this.colors,
    required this.selected,
    required this.ink,
    required this.today,
    required this.faint,
    required this.muted,
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
  final DateTime start;
  final List<String?> order;
  final Map<String?, Color> colors;
  final int selected;
  final List<double> values;
  final double perDay, peak, reveal;
  final Color ink, today, faint, muted, fixedColor, bg;
  final Color? lineColor;
  final TextStyle labelStyle, lineLabelStyle;
  final String? lineLabel;

  TextPainter _text(String s, TextStyle st) => TextPainter(text: TextSpan(text: s, style: st), textDirection: TextDirection.ltr)..layout();

  @override
  void paint(Canvas canvas, Size size) {
    final n = d.length;
    final plotW = size.width - _gutter;
    final slot = plotW / n;
    final gap = (slot * 0.28).clamp(1.0, 4.0);
    final w = slot - gap;
    final base = size.height - _axis;
    final h = base - _top;
    final scale = h / (peak * 1.25);
    final r = Radius.circular((w / 2).clamp(1.0, 3.0));
    double xOf(int i) => _gutter + i * slot + gap / 2;

    // Faint guide lines with their amounts.
    final step = _niceStep(peak * 1.25);
    for (var v = step; v * scale <= h; v += step) {
      final y = base - v * scale;
      canvas.drawLine(Offset(_gutter, y), Offset(size.width, y), Paint()
        ..color = faint
        ..strokeWidth = 1);
      final tp = _text(_compact(v), labelStyle);
      tp.paint(canvas, Offset(_gutter - tp.width - 6, y - tp.height / 2));
    }

    String? shownLabel;
    for (var i = 0; i < n; i++) {
      final x = xOf(i);
      if (i >= d.dayNumber) {
        canvas.drawRRect(RRect.fromLTRBR(x, base - 3, x + w, base, r), Paint()..color = faint);
        continue;
      }
      final dim = i != selected;
      Color c(Color x) => dim ? x.withValues(alpha: x.a * 0.35) : x;
      if (d.fixed[i] > 0) {
        // Rent and bills: a full-height pale bar with a break, labelled once.
        canvas.drawRRect(RRect.fromLTRBR(x, _top, x + w, base, r), Paint()..color = c(fixedColor));
        final y = _top + 10;
        canvas.drawLine(Offset(x - 1, y + 3), Offset(x + w + 1, y - 1), Paint()
          ..color = bg
          ..strokeWidth = 2.5);
        if (shownLabel == null) {
          shownLabel = d.fixedLabel[i] ?? 'Bills';
          final tp = _text(shownLabel, labelStyle);
          final lx = (x + w + 4).clamp(0.0, size.width - tp.width);
          tp.paint(canvas, Offset(lx, _top - 2));
        }
      }
      final dayH = (values[i] * scale).clamp(0.0, h);
      if (dayH <= 0) {
        canvas.drawRRect(RRect.fromLTRBR(x, base - 3, x + w, base, r), Paint()..color = dim ? faint : ink);
        continue;
      }
      // Stack the categories in the same order every day, biggest at the bottom.
      final barH = dayH < 3 ? 3.0 : dayH;
      final grow = d.daily[i] > 0 ? barH / (d.daily[i] * scale) : 0.0;
      canvas.save();
      canvas.clipRRect(RRect.fromLTRBR(x, base - barH, x + w, base, r));
      var y = base;
      for (final id in order) {
        final v = d.byCat[i][id] ?? 0;
        if (v <= 0) continue;
        final segH = v * scale * grow;
        canvas.drawRect(Rect.fromLTRB(x, y - segH, x + w, y), Paint()..color = c(colors[id] ?? muted));
        y -= segH;
        if (y > base - barH + 1) {
          canvas.drawRect(Rect.fromLTRB(x, y - 0.5, x + w, y + 0.5), Paint()..color = bg);
        }
      }
      canvas.restore();
    }

    // A small marker above the picked day.
    {
      final cx = xOf(selected) + w / 2;
      final top = base - (values[selected] * scale).clamp(3.0, h) - 5;
      final path = Path()
        ..moveTo(cx - 4, top - 5)
        ..lineTo(cx + 4, top - 5)
        ..lineTo(cx, top)
        ..close();
      canvas.drawPath(path, Paint()..color = ink);
    }

    if (lineColor != null && reveal > 0) {
      canvas.save();
      canvas.clipRect(Rect.fromLTWH(0, 0, _gutter + plotW * reveal, size.height));
      final y = base - perDay * scale;
      final paint = Paint()
        ..color = lineColor!
        ..strokeWidth = 1.5;
      for (var x = _gutter; x < size.width; x += 7) {
        canvas.drawLine(Offset(x, y), Offset((x + 4).clamp(0, size.width), y), paint);
      }
      final tp = _text(lineLabel ?? '', lineLabelStyle);
      final rect = Rect.fromLTWH(size.width - tp.width - 6, y - tp.height - 3, tp.width + 6, tp.height + 2);
      canvas.drawRect(rect, Paint()..color = bg.withValues(alpha: 0.85));
      tp.paint(canvas, Offset(size.width - tp.width - 3, y - tp.height - 2));
      canvas.restore();
    }

    // A date under the first day of each week, and "today" under today.
    for (var i = 0; i < n; i += 7) {
      final tp = _text(shortDate(start.add(Duration(days: i))), labelStyle);
      final cx = xOf(i) + w / 2;
      final lx = i == 0 ? xOf(0) : (cx - tp.width / 2).clamp(_gutter, size.width - tp.width);
      tp.paint(canvas, Offset(lx, base + 5));
    }
    final tt = _text('today', labelStyle.copyWith(color: today, fontWeight: FontWeight.w800));
    final tx = (xOf(d.dayNumber - 1) + w / 2 - tt.width / 2).clamp(_gutter, size.width - tt.width);
    tt.paint(canvas, Offset(tx, base + 17));
  }

  @override
  bool shouldRepaint(covariant _BarsPainter old) => true;
}

/// A round step for the guide lines: about two or three across [top] paise.
double _niceStep(double top) {
  for (final rupees in [50, 100, 200, 250, 500, 1000, 2000, 2500, 5000, 10000, 20000, 25000, 50000, 100000]) {
    if (top / (rupees * 100) <= 3) return rupees * 100.0;
  }
  return top / 2;
}

/// ₹200, ₹1k, ₹2.5k.
String _compact(double paise) {
  final r = (paise / 100).round();
  if (r < 1000) return '₹$r';
  final k = r / 1000;
  return '₹${k == k.roundToDouble() ? k.round() : k.toStringAsFixed(1)}k';
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
