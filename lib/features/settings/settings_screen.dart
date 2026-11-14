import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/cycle_math.dart';
import '../../core/money.dart';
import '../../shared/widgets.dart';
import '../auth/secret_entry.dart';
import '../report/notifications.dart';
import '../sms/sms_service.dart';
import '../../main.dart' show scheduleNotifications;

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.p;
    final s = ref.watch(settingsProvider);
    final themeLabel = switch (s.themeMode) {
      ThemeMode.light => 'Light',
      ThemeMode.dark => 'Dark',
      _ => 'Match phone',
    };
    return Scaffold(
      appBar: AppBar(leading: const BackButton()),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 40),
        children: [
          Text('Settings', style: T.title.copyWith(color: p.ink)),
          const SizedBox(height: 10),
          LineRow(
            title: 'Pay cycle',
            trailing: TrailingText(s.cycleDay == lastDay ? 'Last day' : 'Starts on the ${ordinal(s.cycleDay)}'),
            onTap: () => context.push('/settings/cycle'),
          ),
          LineRow(
            title: 'Change PIN',
            trailing: const TrailingText('PIN'),
            onTap: () => _changeSecret(context, ref),
          ),
          LineRow(
            title: 'Fingerprint unlock',
            subtitle: 'Use your phone’s fingerprint or face to open Tally',
            trailing: Switch(
              value: s.biometric,
              onChanged: (v) async {
                if (v && !await ref.read(authProvider).canUseBiometrics()) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No fingerprint or face set up on this phone.')),
                    );
                  }
                  return;
                }
                await s.setBiometric(v);
              },
            ),
          ),
          LineRow(
            title: 'Starting balance',
            subtitle: 'What was in your account on ${longDate(s.startingDate)}',
            trailing: TrailingText(rupees(s.startingBalance)),
            onTap: () => _editBalance(context, ref),
          ),
          LineRow(title: 'Currency', trailing: const TrailingText('₹ INR')),
          LineRow(
            title: 'Theme',
            trailing: TrailingText(themeLabel),
            onTap: () {
              final next = switch (s.themeMode) {
                ThemeMode.system => ThemeMode.light,
                ThemeMode.light => ThemeMode.dark,
                _ => ThemeMode.system,
              };
              s.setThemeMode(next);
            },
          ),
          const SizedBox(height: 26),
          const CapsLabel('Extras'),
          LineRow(
            title: 'Read bank SMS',
            subtitle: 'Show credits and debits from your bank so you can add them in one tap',
            trailing: Switch(value: s.smsEnabled, onChanged: (v) async {
              if (v && !await askSmsPermission()) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('SMS access is off. You can allow it in Android settings for Tally.')));
                }
                return;
              }
              await s.setSmsEnabled(v);
              if (v) await scanSms(ref.read(repoProvider), s);
            }),
            onTap: s.smsEnabled ? () => context.push('/sms') : null,
          ),
          LineRow(
            title: 'Salary-day reminder',
            subtitle: 'A nudge on the first day of each cycle to log your salary',
            trailing: Switch(value: s.salaryReminder, onChanged: (v) async {
              await s.setSalaryReminder(v);
              if (v) await AppNotifications.instance.askPermission();
              await scheduleNotifications(ref.read(repoProvider), s);
            }),
          ),
          const SizedBox(height: 30),
          Text('Tally keeps everything on this phone. Nothing is uploaded.',
              style: T.label.copyWith(color: p.muted, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Future<void> _editBalance(BuildContext context, WidgetRef ref) async {
    final s = ref.read(settingsProvider);
    var digits = (s.startingBalance ~/ 100).toString();
    final p = context.p;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: p.bg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 16),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Starting balance', style: T.title.copyWith(color: p.ink)),
              const SizedBox(height: 14),
              Text(rupees(rupeesToPaise(int.tryParse(digits) ?? 0)), style: T.huge.copyWith(color: p.ink, fontSize: 44)),
              const SizedBox(height: 10),
              Keypad(onKey: (k) => set(() => digits = applyKey(digits, k))),
              const SizedBox(height: 10),
              BigButton('Save', onTap: () async {
                await s.setStartingBalance(rupeesToPaise(int.tryParse(digits) ?? 0));
                if (ctx.mounted) Navigator.pop(ctx);
              }),
            ]),
          ),
        ),
      ),
    );
  }

  Future<void> _changeSecret(BuildContext context, WidgetRef ref) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (ctx) => Builder(
        builder: (ctx) => Scaffold(
          appBar: AppBar(leading: const BackButton()),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 20),
              child: SecretSetup(
                onDone: (secret) async {
                  await ref.read(authProvider).setSecret(secret);
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('New PIN saved')));
                  }
                },
              ),
            ),
          ),
        ),
      ),
    ));
  }
}
