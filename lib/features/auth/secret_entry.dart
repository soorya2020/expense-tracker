import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme.dart';
import '../../shared/motion.dart';
import '../../shared/widgets.dart';

/// Four PIN dots.
class PinDots extends StatelessWidget {
  const PinDots({super.key, required this.filled, this.error = false});
  final int filled;
  final bool error;
  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return Row(
      children: [
        for (var i = 0; i < 4; i++)
          AnimatedScale(
            scale: i < filled && !error ? 1.12 : 1,
            duration: motion(context, 160),
            curve: Curves.easeOutBack,
            child: AnimatedContainer(
              duration: motion(context, 120),
              margin: const EdgeInsets.only(right: 18),
              width: 18,
              height: 18,
              decoration: BoxDecoration(shape: BoxShape.circle, color: error ? p.over : (i < filled ? p.ink : p.line)),
            ),
          ),
      ],
    );
  }
}

/// Choose and confirm a 4-digit PIN.
class SecretSetup extends StatefulWidget {
  const SecretSetup({super.key, required this.onDone});
  final ValueChanged<String> onDone;
  @override
  State<SecretSetup> createState() => _SecretSetupState();
}

class _SecretSetupState extends State<SecretSetup> {
  String first = '';
  String pin = '';
  bool confirming = false;
  bool mismatch = false;

  void _key(String k) {
    setState(() {
      mismatch = false;
      pin = applyKey(pin, k, max: 4);
    });
    if (pin.length == 4) {
      Future.delayed(const Duration(milliseconds: 150), () {
        if (!mounted) return;
        if (!confirming) {
          setState(() {
            first = pin;
            pin = '';
            confirming = true;
          });
        } else if (pin == first) {
          widget.onDone(pin);
        } else {
          HapticFeedback.heavyImpact();
          setState(() {
            mismatch = true;
            pin = '';
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(confirming ? 'Type it once more' : 'Pick a 4-digit PIN', style: T.title.copyWith(color: p.ink)),
        const SizedBox(height: 8),
        Text(
          mismatch ? 'Those didn’t match. Try again.' : 'You’ll use it to open Tally. Your money stays private.',
          style: T.label.copyWith(color: mismatch ? p.over : p.muted, fontSize: 13),
        ),
        const SizedBox(height: 32),
        PinDots(filled: pin.length, error: mismatch),
        const Spacer(),
        Keypad(onKey: _key, showDoubleZero: false, rowGap: 8),
      ],
    );
  }
}
