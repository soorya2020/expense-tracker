import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/cycle_math.dart';

/// Horizontal strip of days 1–28 plus "Last day".
class DayStrip extends StatefulWidget {
  const DayStrip({super.key, required this.selected, required this.onSelect});
  final int selected;
  final ValueChanged<int> onSelect;
  @override
  State<DayStrip> createState() => _DayStripState();
}

class _DayStripState extends State<DayStrip> {
  late final ScrollController _c;
  static const _w = 52.0;

  @override
  void initState() {
    super.initState();
    final i = widget.selected == lastDay ? 28 : widget.selected - 1;
    _c = ScrollController(initialScrollOffset: (i - 2).clamp(0, 40) * _w);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final days = [for (var d = 1; d <= 28; d++) d, lastDay];
    return SizedBox(
      height: 56,
      child: ListView.separated(
        controller: _c,
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final d = days[i];
          final on = d == widget.selected;
          return GestureDetector(
            onTap: () => widget.onSelect(d),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: d == lastDay ? 84 : 44,
              decoration: BoxDecoration(color: on ? p.ink : p.surface, borderRadius: BorderRadius.circular(14)),
              alignment: Alignment.center,
              child: Text(
                d == lastDay ? 'Last day' : '$d',
                style: T.bodyBold.copyWith(color: on ? p.bg : p.ink, fontSize: d == lastDay ? 13 : 17),
              ),
            ),
          );
        },
      ),
    );
  }
}
