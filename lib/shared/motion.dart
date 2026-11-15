import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shared animation pieces. Everything here turns itself off when the phone's
/// "Remove animations" setting is on.
const motionCurve = Curves.easeOutCubic;

bool reduceMotion(BuildContext context) => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

Duration motion(BuildContext context, int ms) => reduceMotion(context) ? Duration.zero : Duration(milliseconds: ms);

/// Sinks slightly while pressed and gives a light tick, so taps feel solid.
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child, this.enabled = true, this.scale = 0.95, this.haptic = true});
  final Widget child;
  final bool enabled, haptic;
  final double scale;
  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool down = false;
  void _set(bool v) {
    if (!widget.enabled || down == v) return;
    setState(() => down = v);
    if (v && widget.haptic) HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) => Listener(
        onPointerDown: (_) => _set(true),
        onPointerUp: (_) => _set(false),
        onPointerCancel: (_) => _set(false),
        child: AnimatedScale(
          scale: down ? widget.scale : 1,
          duration: motion(context, down ? 90 : 160),
          curve: Curves.easeOut,
          child: widget.child,
        ),
      );
}

/// Shows [value] and rolls to each new one. The first value counts up from [from].
class CountUp extends StatefulWidget {
  const CountUp(this.value, {super.key, required this.format, this.style, this.from = 0, this.ms = 800});
  final int value;
  final int from, ms;
  final String Function(int) format;
  final TextStyle? style;
  @override
  State<CountUp> createState() => _CountUpState();
}

class _CountUpState extends State<CountUp> {
  late int begin = widget.from;
  int shown = 0;

  @override
  void didUpdateWidget(CountUp old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) begin = shown;
  }

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        key: ValueKey(widget.value),
        tween: Tween(begin: begin.toDouble(), end: widget.value.toDouble()),
        duration: motion(context, widget.ms),
        curve: motionCurve,
        builder: (_, v, _) {
          shown = v.round();
          return Text(widget.format(shown), style: widget.style);
        },
      );
}

/// Fades and rises into place once, after [delay]. Used to stagger a screen in.
class RiseIn extends StatefulWidget {
  const RiseIn({super.key, required this.child, this.delay = 0, this.offset = 14});
  final Widget child;
  final int delay;
  final double offset;
  @override
  State<RiseIn> createState() => _RiseInState();
}

class _RiseInState extends State<RiseIn> with SingleTickerProviderStateMixin {
  late final c = AnimationController(vsync: this, duration: Duration(milliseconds: 420 + widget.delay));
  late final a = CurvedAnimation(parent: c, curve: Interval(widget.delay / (420 + widget.delay), 1, curve: motionCurve));

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
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: a,
        child: widget.child,
        builder: (_, child) => Opacity(
          opacity: a.value,
          child: Transform.translate(offset: Offset(0, widget.offset * (1 - a.value)), child: child),
        ),
      );
}

/// A new list row: opens up its space and slides in from the side.
class AppearRow extends StatefulWidget {
  const AppearRow({super.key, required this.child, this.animate = true, this.highlight});
  final Widget child;
  final bool animate;
  final Color? highlight;
  @override
  State<AppearRow> createState() => _AppearRowState();
}

class _AppearRowState extends State<AppearRow> with SingleTickerProviderStateMixin {
  late final c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (c.isDismissed && !c.isAnimating) {
      if (!widget.animate || reduceMotion(context)) {
        c.value = 1;
      } else {
        c.forward();
      }
    }
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = CurvedAnimation(parent: c, curve: const Interval(0, .22, curve: motionCurve));
    final slide = CurvedAnimation(parent: c, curve: const Interval(.08, .3, curve: motionCurve));
    final glow = CurvedAnimation(parent: c, curve: const Interval(.25, 1, curve: Curves.easeIn));
    return SizeTransition(
      sizeFactor: size,
      alignment: Alignment.topCenter,
      child: AnimatedBuilder(
        animation: c,
        child: widget.child,
        builder: (_, child) => DecoratedBox(
          decoration: BoxDecoration(color: widget.highlight?.withValues(alpha: (1 - glow.value) * (c.isCompleted ? 0 : 1))),
          child: Opacity(
            opacity: slide.value,
            child: Transform.translate(offset: Offset(40 * (1 - slide.value), 0), child: child),
          ),
        ),
      ),
    );
  }
}

/// Shakes sideways each time [trigger] changes. Used for a wrong PIN.
class Shake extends StatefulWidget {
  const Shake({super.key, required this.trigger, required this.child});
  final int trigger;
  final Widget child;
  @override
  State<Shake> createState() => _ShakeState();
}

class _ShakeState extends State<Shake> with SingleTickerProviderStateMixin {
  late final c = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));

  @override
  void didUpdateWidget(Shake old) {
    super.didUpdateWidget(old);
    if (old.trigger != widget.trigger && !reduceMotion(context)) c.forward(from: 0);
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: c,
        child: widget.child,
        builder: (_, child) => Transform.translate(
          offset: Offset(math.sin(c.value * math.pi * 6) * 10 * (1 - c.value), 0),
          child: child,
        ),
      );
}

/// Bounces once each time [value] goes up. Used for the SMS badge.
class Bump extends StatefulWidget {
  const Bump({super.key, required this.value, required this.child, this.wiggle = false});
  final int value;
  final Widget child;
  final bool wiggle;
  @override
  State<Bump> createState() => _BumpState();
}

class _BumpState extends State<Bump> with SingleTickerProviderStateMixin {
  late final c = AnimationController(vsync: this, duration: const Duration(milliseconds: 480));

  @override
  void didUpdateWidget(Bump old) {
    super.didUpdateWidget(old);
    if (widget.value > old.value && !reduceMotion(context)) c.forward(from: 0);
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: c,
        child: widget.child,
        builder: (_, child) {
          final t = c.value;
          if (widget.wiggle) {
            return Transform.rotate(angle: math.sin(t * math.pi * 3) * .25 * (1 - t), child: child);
          }
          final s = t < .35 ? 1 + .5 * (t / .35) : t < .7 ? 1.5 - .62 * ((t - .35) / .35) : .88 + .12 * ((t - .7) / .3);
          return Transform.scale(scale: c.isAnimating ? s : 1, child: child);
        },
      );
}

/// Small spring when the text changes, for amounts typed on the keypad.
class PopOnChange extends StatefulWidget {
  const PopOnChange({super.key, required this.value, required this.child, this.alignment = Alignment.centerLeft});
  final Object value;
  final Widget child;
  final Alignment alignment;
  @override
  State<PopOnChange> createState() => _PopOnChangeState();
}

class _PopOnChangeState extends State<PopOnChange> with SingleTickerProviderStateMixin {
  late final c = AnimationController(vsync: this, duration: const Duration(milliseconds: 220));

  @override
  void didUpdateWidget(PopOnChange old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value && !reduceMotion(context)) c.forward(from: 0);
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: c,
        child: widget.child,
        builder: (_, child) => Transform.scale(
          alignment: widget.alignment,
          scale: 1 + .08 * math.sin(c.value * math.pi),
          child: child,
        ),
      );
}

/// Screen transitions: new screens slide in from the right while the one
/// underneath eases back and dims a little.
class SlideBackTransitionsBuilder extends PageTransitionsBuilder {
  const SlideBackTransitionsBuilder();
  @override
  Widget buildTransitions<T>(PageRoute<T> route, BuildContext context, Animation<double> a, Animation<double> b, Widget child) {
    final inA = CurvedAnimation(parent: a, curve: motionCurve, reverseCurve: Curves.easeInCubic);
    final outA = CurvedAnimation(parent: b, curve: motionCurve, reverseCurve: Curves.easeInCubic);
    return SlideTransition(
      position: Tween(begin: const Offset(1, 0), end: Offset.zero).animate(inA),
      child: SlideTransition(
        position: Tween(begin: Offset.zero, end: const Offset(-.22, 0)).animate(outA),
        child: AnimatedBuilder(
          animation: outA,
          child: child,
          builder: (_, c) => outA.value == 0
              ? c!
              : ColorFiltered(
                  colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: .25 * outA.value), BlendMode.srcATop),
                  child: c,
                ),
        ),
      ),
    );
  }
}
