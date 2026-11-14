import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../shared/widgets.dart';
import 'secret_entry.dart';

class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});
  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  String pin = '';
  bool wrong = false;
  bool canBio = false;

  @override
  void initState() {
    super.initState();
    _bio();
  }

  Future<void> _bio() async {
    if (!ref.read(settingsProvider).biometric) return;
    final auth = ref.read(authProvider);
    final ok = await auth.canUseBiometrics();
    if (!mounted) return;
    setState(() => canBio = ok);
    if (ok) await auth.biometricUnlock();
  }

  Future<void> _try(String secret) async {
    final ok = await ref.read(authProvider).verify(secret);
    if (!mounted) return;
    if (ok) {
      ref.read(authProvider).unlock();
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        wrong = true;
        pin = '';
      });
    }
  }

  void _key(String k) {
    setState(() {
      wrong = false;
      pin = applyKey(pin, k, max: 4);
    });
    if (pin.length == 4) _try(pin);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 40, 22, 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Hi again.', style: T.huge.copyWith(fontSize: 46, color: p.ink)),
            const SizedBox(height: 8),
            Text(
              wrong ? 'That’s not it. Try again.' : 'Enter your PIN',
              style: T.label.copyWith(fontSize: 14, color: wrong ? p.over : p.muted),
            ),
            const SizedBox(height: 32),
            ...[
              PinDots(filled: pin.length, error: wrong),
              const Spacer(),
              Keypad(
                onKey: _key,
                rowGap: 10,
                leftKey: canBio
                    ? IconButton(
                        onPressed: () => ref.read(authProvider).biometricUnlock(),
                        icon: Icon(Icons.fingerprint_rounded, size: 34, color: p.salary),
                      )
                    : const SizedBox(),
              ),
            ],
          ]),
        ),
      ),
    );
  }
}
