import 'package:drift/drift.dart' show Value;
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../data/db.dart';
import '../../data/repo.dart';
import '../../data/settings.dart';
import 'sms_parser.dart';

const _channel = MethodChannel('tally/sms');

/// Asks for SMS access. Returns true when granted.
Future<bool> askSmsPermission() async => (await Permission.sms.request()).isGranted;

Future<bool> hasSmsPermission() async => (await Permission.sms.status).isGranted;

/// Reads new bank SMS from the inbox into the BankSms table.
/// Looks back at most 45 days. Safe to call often.
Future<int> scanSms(Repo repo, Settings settings) async {
  if (!settings.smsEnabled) return 0;
  if (!await hasSmsPermission()) return 0;
  final floor = DateTime.now().subtract(const Duration(days: 45));
  final last = settings.smsLastScan;
  final since = last.isAfter(floor) ? last.subtract(const Duration(minutes: 5)) : floor;
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
