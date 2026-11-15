import 'dart:convert';
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'db.dart';
import 'settings.dart';

/// What a backup file holds, read back before restoring.
class BackupInfo {
  BackupInfo(this.data, this.madeAt, this.entries, this.cycles);
  final Map<String, dynamic> data;
  final DateTime? madeAt;
  final int entries, cycles;
}

/// Everything in Tally as JSON. The PIN is not included.
Future<Map<String, Object?>> buildBackup(AppDb db, Settings settings) async => {
      'app': 'tally',
      'version': 1,
      'madeAt': DateTime.now().millisecondsSinceEpoch,
      'prefs': settings.exportPrefs(),
      'entries': (await db.select(db.entries).get()).map((e) => e.toJson()).toList(),
      'cycles': (await db.select(db.cycles).get()).map((e) => e.toJson()).toList(),
      'bankSms': (await db.select(db.bankSms).get()).map((e) => e.toJson()).toList(),
    };

/// Writes a backup file and opens the share sheet (Drive, Files, WhatsApp...).
Future<void> shareBackup(AppDb db, Settings settings) async {
  final json = jsonEncode(await buildBackup(db, settings));
  final dir = await getTemporaryDirectory();
  final name = 'Tally-backup-${DateFormat('d-MMM-yyyy').format(DateTime.now())}.json';
  final f = File('${dir.path}/$name');
  await f.writeAsString(json, flush: true);
  await SharePlus.instance.share(ShareParams(files: [XFile(f.path, mimeType: 'application/json')], subject: name));
  await settings.setLastBackup(DateTime.now());
}

/// Reads a backup file. Throws [FormatException] if it isn't one.
BackupInfo readBackup(List<int> bytes) {
  final data = jsonDecode(utf8.decode(bytes));
  if (data is! Map<String, dynamic> || data['app'] != 'tally') {
    throw const FormatException('This isn’t a Tally backup file.');
  }
  final at = (data['madeAt'] as num?)?.toInt();
  return BackupInfo(
    data,
    at == null ? null : DateTime.fromMillisecondsSinceEpoch(at),
    (data['entries'] as List?)?.length ?? 0,
    (data['cycles'] as List?)?.length ?? 0,
  );
}

/// Replaces everything on this phone with [b].
Future<void> restoreBackup(AppDb db, Settings settings, BackupInfo b) async {
  List<Map<String, dynamic>> rows(String k) => ((b.data[k] as List?) ?? const []).cast<Map<String, dynamic>>();
  await db.transaction(() async {
    await db.delete(db.entries).go();
    await db.delete(db.cycles).go();
    await db.delete(db.bankSms).go();
    await db.batch((x) {
      x.insertAll(db.entries, rows('entries').map(Entry.fromJson));
      x.insertAll(db.cycles, rows('cycles').map(Cycle.fromJson));
      x.insertAll(db.bankSms, rows('bankSms').map(BankMessage.fromJson));
    });
  });
  await settings.importPrefs((b.data['prefs'] as Map?)?.cast<String, dynamic>() ?? const {});
}
