import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/theme.dart';
import '../core/money.dart';
import '../data/db.dart';
import '../data/repo.dart';

/// Number pad used for amounts and PINs.
class Keypad extends StatelessWidget {
  const Keypad({super.key, required this.onKey, this.leftKey, this.showDoubleZero = true, this.rowGap = 4});

  /// Receives '0'–'9', '00' or 'del'.
  final ValueChanged<String> onKey;
  final Widget? leftKey;
  final bool showDoubleZero;
  final double rowGap;

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    Widget key(String k, {Widget? child}) => Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              HapticFeedback.selectionClick();
              onKey(k);
            },
            onLongPress: k == 'del' ? () => onKey('clear') : null,
            child: SizedBox(
              height: 58,
              child: Center(
                child: child ??
                    Text(k, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w500, color: p.ink)),
              ),
            ),
          ),
        );
    Widget row(List<Widget> c) => Row(children: c);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        row([key('1'), key('2'), key('3')]),
        SizedBox(height: rowGap),
        row([key('4'), key('5'), key('6')]),
        SizedBox(height: rowGap),
        row([key('7'), key('8'), key('9')]),
        SizedBox(height: rowGap),
        row([
          if (leftKey != null) Expanded(child: SizedBox(height: 58, child: Center(child: leftKey)))
          else if (showDoubleZero) key('00')
          else const Expanded(child: SizedBox()),
          key('0'),
          key('del', child: Icon(Icons.backspace_outlined, color: p.ink, size: 22)),
        ]),
      ],
    );
  }
}

/// Applies a keypad key to a digit string, max 9 digits (₹99,99,99,999).
String applyKey(String current, String k, {int max = 9}) {
  if (k == 'del') return current.isEmpty ? current : current.substring(0, current.length - 1);
  if (k == 'clear') return '';
  final next = current == '0' ? k : current + k;
  final trimmed = next.replaceFirst(RegExp(r'^0+(?=\d)'), '');
  return trimmed.length > max ? current : trimmed;
}

/// A rounded pill. Filled when [selected].
class Pill extends StatelessWidget {
  const Pill(this.label, {super.key, this.selected = false, this.color, this.outlined = false, this.onTap, this.icon});
  final String label;
  final bool selected, outlined;
  final Color? color;
  final VoidCallback? onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final c = color ?? p.ink;
    final bg = selected ? c : (outlined ? Colors.transparent : p.surface);
    final fg = selected ? (color == null ? p.bg : (c == p.extra ? const Color(0xFF1A1205) : Colors.white)) : p.ink;
    return Material(
      color: bg,
      shape: StadiumBorder(side: outlined && !selected ? BorderSide(color: p.line) : BorderSide.none),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (icon != null) ...[Icon(icon, size: 15, color: fg), const SizedBox(width: 6)],
            Text(label, style: T.label.copyWith(color: fg, fontSize: 13)),
          ]),
        ),
      ),
    );
  }
}

/// Round arrow button that saves or moves on.
class GoButton extends StatelessWidget {
  const GoButton({super.key, required this.onTap, this.color, this.icon = Icons.arrow_forward_rounded});
  final VoidCallback? onTap;
  final Color? color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final c = color ?? p.salary;
    return Material(
      color: onTap == null ? p.line : c,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap == null
            ? null
            : () {
                HapticFeedback.mediumImpact();
                onTap!();
              },
        child: SizedBox(width: 64, height: 64, child: Icon(icon, color: c == p.ink ? p.bg : Colors.white, size: 28)),
      ),
    );
  }
}

/// Full-width pill button.
class BigButton extends StatelessWidget {
  const BigButton(this.label, {super.key, required this.onTap, this.filled = true, this.color});
  final String label;
  final VoidCallback? onTap;
  final bool filled;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final bg = filled ? (color ?? p.ink) : p.surface;
    final fg = filled ? (color == null ? p.bg : Colors.white) : p.ink;
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: bg,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 17),
            child: Center(child: Text(label, style: T.bodyBold.copyWith(color: fg, fontSize: 15))),
          ),
        ),
      ),
    );
  }
}

class CapsLabel extends StatelessWidget {
  const CapsLabel(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Text(text.toUpperCase(), style: T.caps.copyWith(color: context.p.muted));
}

/// A settings-style row with a title, optional subtitle and trailing widget.
class LineRow extends StatelessWidget {
  const LineRow({super.key, required this.title, this.subtitle, this.trailing, this.onTap});
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: p.line))),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: T.body.copyWith(color: p.ink, fontSize: 15)),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle!, style: T.label.copyWith(color: p.muted, fontWeight: FontWeight.w500)),
              ],
            ]),
          ),
          if (trailing != null) trailing!,
        ]),
      ),
    );
  }
}

class TrailingText extends StatelessWidget {
  const TrailingText(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) =>
      Text('$text  ›', style: T.body.copyWith(color: context.p.muted, fontSize: 13));
}

/// One entry in a list: name and kind on the left, signed amount on the right.
class EntryRow extends StatelessWidget {
  const EntryRow(this.e, {super.key, this.onTap});
  final Entry e;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    final inc = isIncome(e);
    final name = inc
        ? ((e.title?.isNotEmpty ?? false) ? e.title! : IncomeKind.label(e.incomeKind ?? 'extra'))
        : ((e.title?.isNotEmpty ?? false) ? e.title! : 'Spending');
    final sub = inc
        ? IncomeKind.label(e.incomeKind ?? '')
        : e.endDate != null
            ? rangeLabel(e.date, e.endDate!)
            : shortDate(e.date);
    final color = inc ? p.forIncome(e.incomeKind) : (e.unexpected ? p.over : p.ink);
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: p.line))),
        child: Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
          Flexible(child: Text(name, style: T.body.copyWith(color: p.ink, fontSize: 15), overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 8),
          Text(e.unexpected ? '$sub · Unexpected' : sub, style: T.label.copyWith(color: p.muted, fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(signed(e.amount, positive: inc), style: T.bodyBold.copyWith(color: color, fontSize: 15)),
        ]),
      ),
    );
  }
}
