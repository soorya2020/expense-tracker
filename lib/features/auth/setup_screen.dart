import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/cycle_math.dart';
import '../../core/money.dart';
import '../../shared/widgets.dart';
import 'secret_entry.dart';
import '../sms/sms_service.dart';
import '../report/notifications.dart';
import '../../main.dart' show scheduleNotifications;
import '../cycle/day_strip.dart';

/// First run: lock, starting balance, pay cycle day, bank SMS.
class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});
  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  int step = 0;
  String? secret;
  bool useFingerprint = false;
  String balance = '';
  int cycleDay = 1;
  static const steps = 4;
  bool readSms = false;

  Future<void> _finish() async {
    final settings = ref.read(settingsProvider);
    final auth = ref.read(authProvider);
    await auth.setSecret(secret!);
    await settings.setBiometric(useFingerprint);
    await settings.completeSetup(
      startingBalance: rupeesToPaise(int.tryParse(balance) ?? 0),
      cycleDay: cycleDay,
    );
    await ref.read(repoProvider).rollCycles();
    await settings.setSmsEnabled(readSms);
    if (readSms) await scanSms(ref.read(repoProvider), settings).catchError((_) => 0);
    try {
      await AppNotifications.instance.askPermission();
      await scheduleNotifications(ref.read(repoProvider), settings);
    } catch (_) {}
    auth.unlock();
    if (mounted) context.go('/');
  }

  Future<void> _pinChosen(String pin) async {
    secret = pin;
    final auth = ref.read(authProvider);
    if (await auth.canUseBiometrics() && mounted) {
      final p = context.p;
      final yes = await showModalBottomSheet<bool>(
        context: context,
        backgroundColor: p.bg,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        builder: (ctx) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 26, 22, 16),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.fingerprint_rounded, size: 44, color: p.salary),
              const SizedBox(height: 12),
              Text('Unlock with your fingerprint too?', style: T.title.copyWith(color: p.ink)),
              const SizedBox(height: 8),
              Text('Your PIN still works whenever the fingerprint doesn’t.', style: T.body.copyWith(color: p.muted)),
              const SizedBox(height: 18),
              BigButton('Use fingerprint', onTap: () => Navigator.pop(ctx, true)),
              const SizedBox(height: 10),
              BigButton('Not now', filled: false, onTap: () => Navigator.pop(ctx, false)),
            ]),
          ),
        ),
      );
      useFingerprint = yes ?? false;
    }
    if (mounted) setState(() => step = 1);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    Widget header(String right) => Row(children: [
          Text('Set up · ${step + 1} of $steps', style: T.label.copyWith(color: p.muted)),
          const Spacer(),
          if (step > 0)
            GestureDetector(
              onTap: () => setState(() => step--),
              child: Text(right, style: T.label.copyWith(color: p.muted)),
            ),
        ]);

    final body = switch (step) {
      0 => SecretSetup(onDone: _pinChosen),
      1 => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('How much is in your account today?', style: T.title.copyWith(color: p.ink)),
          const SizedBox(height: 10),
          Text('This becomes your starting balance. You can change it later.',
              style: T.label.copyWith(color: p.muted, fontSize: 13)),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text.rich(TextSpan(children: [
              TextSpan(text: '₹', style: T.huge.copyWith(fontSize: 32, color: p.muted)),
              TextSpan(
                  text: balance.isEmpty ? '0' : rupees(rupeesToPaise(int.parse(balance)), symbol: false),
                  style: T.huge.copyWith(color: balance.isEmpty ? p.line : p.ink)),
            ])),
          ),
          const Spacer(),
          Keypad(onKey: (k) => setState(() => balance = applyKey(balance, k))),
          const SizedBox(height: 12),
          Align(alignment: Alignment.centerRight, child: GoButton(onTap: () => setState(() => step = 2))),
        ]),
      2 => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Your pay cycle starts on the', style: T.label.copyWith(color: p.muted, fontSize: 14)),
          const SizedBox(height: 4),
          Text(ordinal(cycleDay) == 'last day' ? 'Last day' : ordinal(cycleDay), style: T.huge.copyWith(color: p.ink)),
          const SizedBox(height: 18),
          DayStrip(selected: cycleDay, onSelect: (d) => setState(() => cycleDay = d)),
          const SizedBox(height: 18),
          Text(
            'Pick the day your salary usually lands. Reports, Home and History all follow this cycle. '
            'If your payday moves, you can change it any time.',
            style: T.label.copyWith(color: p.muted, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: p.surface, borderRadius: BorderRadius.circular(16)),
            child: Builder(builder: (_) {
              final s = cycleStartOnOrBefore(DateTime.now(), cycleDay);
              return Text('This cycle: ${rangeLabel(s, cycleEndFor(s, cycleDay))}',
                  style: T.bodyBold.copyWith(color: p.ink));
            }),
          ),
          const Spacer(),
          Align(alignment: Alignment.centerRight, child: GoButton(onTap: () => setState(() => step = 3))),
        ]),
      _ => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.mail_outline_rounded, size: 44, color: p.salary),
          const SizedBox(height: 14),
          Text('Add money from bank SMS?', style: T.title.copyWith(color: p.ink)),
          const SizedBox(height: 10),
          Text(
            'Tally can read the credit and debit messages your bank sends, so you can add them with one tap. '
            'OTPs and personal messages are ignored, and nothing leaves your phone.',
            style: T.body.copyWith(color: p.muted, height: 1.5),
          ),
          const SizedBox(height: 14),
          Text('You can turn this on or off later in Settings.', style: T.label.copyWith(color: p.muted)),
          const Spacer(),
          BigButton('Allow SMS access', onTap: () async {
            readSms = await askSmsPermission();
            await _finish();
          }),
          const SizedBox(height: 10),
          BigButton('Not now', filled: false, onTap: () {
            readSms = false;
            _finish();
          }),
        ]),
    };

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            header('Back'),
            const SizedBox(height: 24),
            Expanded(child: body),
          ]),
        ),
      ),
    );
  }
}
