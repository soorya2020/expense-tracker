import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/money.dart';
import '../../shared/motion.dart';
import 'insights.dart';
import 'pdf_report.dart';

/// A cycle report shown as story cards. Tap the right side for next, left for back.
class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({super.key, required this.startMillis});
  final int startMillis;
  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> with SingleTickerProviderStateMixin {
  int i = 0, count = 1;
  bool busy = false;

  /// Fills the current card's bar, then moves on by itself.
  late final timer = AnimationController(vsync: this, duration: const Duration(seconds: 7))
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed && i < count - 1) _go(i + 1);
    });

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (timer.isDismissed && !timer.isAnimating) timer.forward();
  }

  @override
  void dispose() {
    timer.dispose();
    super.dispose();
  }

  void _go(int to) {
    if (to < 0 || to >= count) return;
    setState(() => i = to);
    timer.forward(from: 0);
  }

  Future<void> _pdf(CycleView v, List<CycleView> older) async {
    setState(() => busy = true);
    try {
      final s = ref.read(settingsProvider);
      final all = ref.read(entriesProvider).value ?? const [];
      await shareReportPdf(v, older, all, s.startingBalance, s.startingDate);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Couldn’t make the PDF: $e')));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final views = ref.watch(cycleViewsProvider);
    final idx = views.indexWhere((v) => v.start.millisecondsSinceEpoch == widget.startMillis);
    if (idx < 0) return const Scaffold(body: Center(heightFactor: 1, child: Text('This cycle has no report.')));
    final v = views[idx];
    final older = views.sublist(idx + 1);
    final cards = buildReport(v, older);
    count = cards.length;
    final c = cards[i.clamp(0, cards.length - 1)];
    final bg = toneColor(c.tone);
    final last = i >= cards.length - 1;
    const white = Colors.white;

    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(end: bg),
      duration: motion(context, 350),
      builder: (_, color, child) => Scaffold(backgroundColor: color, body: child),
      child: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (d) {
            final w = MediaQuery.of(context).size.width;
            _go(d.localPosition.dx < w / 3 ? i - 1 : i + 1);
          },
          onLongPressStart: (_) => timer.stop(),
          onLongPressEnd: (_) => timer.forward(),
          onHorizontalDragEnd: (d) {
            if ((d.primaryVelocity ?? 0) < 0) _go(i + 1);
            if ((d.primaryVelocity ?? 0) > 0) _go(i - 1);
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                for (var k = 0; k < cards.length; k++)
                  Expanded(
                    child: Container(
                      height: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(color: white.withValues(alpha: .35), borderRadius: BorderRadius.circular(2)),
                      alignment: Alignment.centerLeft,
                      child: AnimatedBuilder(
                        animation: timer,
                        builder: (_, _) => FractionallySizedBox(
                          widthFactor: k < i ? 1 : (k == i ? (reduceMotion(context) || last ? 1 : timer.value) : 0),
                          child: Container(decoration: BoxDecoration(color: white, borderRadius: BorderRadius.circular(2))),
                        ),
                      ),
                    ),
                  ),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Text('Your cycle · ${rangeLabel(v.start, v.end)}', style: T.label.copyWith(color: white.withValues(alpha: .8))),
                const Spacer(),
                if (v.cycle != null)
                  IconButton(
                    tooltip: v.supported ? 'Remove the Supported badge' : 'Mark as a tough cycle',
                    onPressed: () => ref.read(repoProvider).updateCycle(v.cycle!.copyWith(supported: Value(!v.supported))),
                    icon: Icon(v.supported ? Icons.flag_rounded : Icons.outlined_flag_rounded, color: white),
                  ),
                IconButton(
                  tooltip: 'Download PDF',
                  onPressed: busy ? null : () => _pdf(v, older),
                  icon: busy
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: white))
                      : const Icon(Icons.picture_as_pdf_outlined, color: white),
                ),
                IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.close_rounded, color: white)),
              ]),
              const Spacer(),
              Text('${i + 1} of ${cards.length}', style: T.label.copyWith(color: white.withValues(alpha: .8))),
              const SizedBox(height: 12),
              if (c.badge != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Palette.dark.help, borderRadius: BorderRadius.circular(99)),
                  child: Text(c.badge!, style: T.caps.copyWith(color: Palette.dark.bg)),
                ),
                const SizedBox(height: 12),
              ],
              AnimatedSwitcher(
                duration: motion(context, 320),
                switchInCurve: Curves.easeOutCubic,
                layoutBuilder: (cur, prev) => Stack(alignment: Alignment.topLeft, children: [...prev, ?cur]),
                transitionBuilder: (child, a) => FadeTransition(
                  opacity: a,
                  child: SlideTransition(position: Tween(begin: const Offset(.08, 0), end: Offset.zero).animate(a), child: child),
                ),
                child: Column(
                  key: ValueKey(i),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CountHeadline(c.headline, style: T.story.copyWith(color: white, fontSize: 40)),
                    const SizedBox(height: 16),
                    Text(c.body, style: T.body.copyWith(color: white.withValues(alpha: .88), fontSize: 16, height: 1.45)),
                    const SizedBox(height: 22),
                    if (c.visual == Visual.salaryBar) _SalaryBar(v: v),
                    if (c.visual == Visual.trend) _Trend(views: [v, ...older.take(5)].reversed.toList()),
                  ],
                ),
              ),
              const Spacer(),
              if (last && older.length >= 1) ...[
                GestureDetector(
                  onTap: () => context.push('/big-picture'),
                  child: Text('See the big picture  ›', style: T.bodyBold.copyWith(color: white)),
                ),
                const SizedBox(height: 14),
              ],
              if (last)
                SizedBox(
                  width: double.infinity,
                  child: Material(
                    color: white,
                    shape: const StadiumBorder(),
                    child: InkWell(
                      customBorder: const StadiumBorder(),
                      onTap: () => context.pop(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Center(heightFactor: 1, child: Text('Done', style: T.bodyBold.copyWith(color: bg, fontSize: 15))),
                      ),
                    ),
                  ),
                )
              else
                Row(children: [
                  Text('Tap for next', style: T.label.copyWith(color: white.withValues(alpha: .7))),
                  const Spacer(),
                  const Icon(Icons.arrow_forward_rounded, color: white),
                ]),
            ]),
          ),
        ),
      ),
    );
  }
}

class _SalaryBar extends StatelessWidget {
  const _SalaryBar({required this.v});
  final CycleView v;
  @override
  Widget build(BuildContext context) {
    final s = v.stats;
    final parts = [
      (s.salary, Colors.white, 'Salary'),
      (s.extra, const Color(0xFFFFC24D), 'Extra'),
      (s.help, Palette.dark.help, 'Help'),
      (s.borrowed, Colors.white54, 'Borrowed'),
    ].where((x) => x.$1 > 0).toList();
    if (parts.isEmpty) return const SizedBox();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        for (final x in parts)
          Expanded(
            flex: (x.$1 ~/ 100).clamp(1, 1 << 30),
            child: Container(height: 8, margin: const EdgeInsets.only(right: 3), decoration: BoxDecoration(color: x.$2, borderRadius: BorderRadius.circular(4))),
          ),
      ]),
      const SizedBox(height: 8),
      Wrap(spacing: 14, children: [
        for (final x in parts)
          Text('${x.$3} ${rupees(x.$1, symbol: false)}', style: T.label.copyWith(color: Colors.white.withValues(alpha: .85))),
      ]),
    ]);
  }
}

class _Trend extends StatelessWidget {
  const _Trend({required this.views});
  final List<CycleView> views; // oldest first, last is this cycle
  @override
  Widget build(BuildContext context) {
    final max = views.map((v) => v.stats.spent).fold(1, (a, b) => a > b ? a : b);
    return SizedBox(
      height: 70,
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        for (var k = 0; k < views.length; k++)
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              height: 8 + 62 * views[k].stats.spent / max,
              decoration: BoxDecoration(
                color: k == views.length - 1 ? Colors.white : Colors.white.withValues(alpha: .35),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
      ]),
    );
  }
}

/// The headline, with its first rupee amount counting up from zero.
class _CountHeadline extends StatelessWidget {
  const _CountHeadline(this.text, {required this.style});
  final String text;
  final TextStyle style;
  @override
  Widget build(BuildContext context) {
    final m = RegExp(r'₹([\d,]+)').firstMatch(text);
    final n = m == null ? null : int.tryParse(m.group(1)!.replaceAll(',', ''));
    if (m == null || n == null || reduceMotion(context)) return Text(text, style: style);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: n.toDouble()),
      duration: const Duration(milliseconds: 900),
      curve: motionCurve,
      builder: (_, v, _) => Text(text.replaceRange(m.start, m.end, rupees(v.round() * 100)), style: style),
    );
  }
}
