import 'package:drift/drift.dart' show Value;
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/cycle_math.dart';
import '../../data/db.dart';
import '../../data/repo.dart';
import '../../data/settings.dart';
import 'sms_parser.dart';

const _channel = MethodChannel('tally/sms');

/// Asks for SMS access. Returns true when granted.
Future<bool> askSmsPermission() async => (await Permission.sms.request()).isGranted;

Future<bool> hasSmsPermission() async => (await Permission.sms.status).isGranted;

/// The first day of the pay cycle that contains today.
Future<DateTime> currentCycleStart(Repo repo, Settings settings) async {
  final today = dateOnly(DateTime.now());
  for (final c in await repo.allCycles()) {
    if (!today.isBefore(dateOnly(c.startDate)) && !today.isAfter(dateOnly(c.endDate))) return dateOnly(c.startDate);
  }
  return cycleStartOnOrBefore(today, settings.cycleDay);
}

/// Reads bank SMS from the current pay cycle into the BankSms table.
/// Normally only messages since the last check; [full] re-reads the whole
/// cycle. Messages already added or skipped keep their status.
Future<int> scanSms(Repo repo, Settings settings, {bool full = false}) async {
  if (!settings.smsEnabled) return 0;
  if (!await hasSmsPermission()) return 0;
  final from = await currentCycleStart(repo, settings);
  final last = settings.smsLastScan.subtract(const Duration(minutes: 5));
  final since = !full && last.isAfter(from) ? last : from;
  final List<dynamic> raw;
  try {
    raw = await _channel.invokeMethod<List<dynamic>>('inbox', {'since': since.millisecondsSinceEpoch}) ?? const [];
  } on PlatformException {
    return 0;
  }
  final skip = settings.smsSkipAccounts.toSet();
  final rows = <BankSmsCompanion>[];
  for (final m in raw.cast<Map<dynamic, dynamic>>()) {
    final sender = m['sender'] as String? ?? '';
    final body = m['body'] as String? ?? '';
    final at = DateTime.fromMillisecondsSinceEpoch((m['date'] as num).toInt());
    final p = parseBankSms(sender: sender, body: body, at: at);
    if (p == null) continue;
    rows.add(BankSmsCompanion.insert(
      refNo: p.refNo,
      direction: p.direction,
      amount: p.amount,
      account: Value(p.account),
      counterparty: Value(p.counterparty),
      sender: sender,
      receivedAt: at,
      status: Value(p.account != null && skip.contains(p.account) ? 'skipped' : 'new'),
      rawText: body,
    ));
  }
  if (rows.isNotEmpty) await repo.insertBankSms(rows);
  await settings.setSmsLastScan(DateTime.now());
  return rows.length;
}
