import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme.dart';
import '../../shared/widgets.dart';

/// Set by CI with --dart-define=BUILD_NUMBER. 0 for local builds.
const appBuild = int.fromEnvironment('BUILD_NUMBER');

const _repo = 'soorya2020/expense-tracker';
const _app = MethodChannel('tally/app');

class Release {
  Release(this.build, this.apkUrl, this.pageUrl, this.published);
  final int build;
  final String apkUrl, pageUrl;
  final DateTime? published;
}

/// The newest published APK build, or null if none could be found.
/// Only asks GitHub for the release list. Nothing about you is sent.
Future<Release?> latestRelease() async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
  try {
    final req = await client.getUrl(Uri.parse('https://api.github.com/repos/$_repo/releases?per_page=10'));
    req.headers.set('Accept', 'application/vnd.github+json');
    req.headers.set('User-Agent', 'Tally-app');
    final res = await req.close().timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) throw HttpException('GitHub said ${res.statusCode}');
    final list = jsonDecode(await res.transform(utf8.decoder).join()) as List<dynamic>;
    Release? best;
    for (final r in list.cast<Map<String, dynamic>>()) {
      final n = int.tryParse((r['tag_name'] as String? ?? '').replaceFirst('build-', ''));
      if (n == null || r['draft'] == true) continue;
      final apk = (r['assets'] as List<dynamic>? ?? const [])
          .cast<Map<String, dynamic>>()
          .where((a) => (a['name'] as String? ?? '').endsWith('.apk'))
          .firstOrNull;
      if (apk == null) continue;
      if (best == null || n > best.build) {
        best = Release(n, apk['browser_download_url'] as String, r['html_url'] as String,
            DateTime.tryParse(r['published_at'] as String? ?? ''));
      }
    }
    return best;
  } finally {
    client.close();
  }
}

Future<void> checkForUpdates(BuildContext context) async {
  final p = context.p;
  final messenger = ScaffoldMessenger.of(context);
  messenger.showSnackBar(const SnackBar(content: Text('Checking for updates…'), duration: Duration(seconds: 2)));
  Release? r;
  try {
    r = await latestRelease();
  } catch (_) {
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(const SnackBar(content: Text('Couldn’t reach GitHub. Check your internet and try again.')));
    return;
  }
  messenger.hideCurrentSnackBar();
  if (!context.mounted) return;
  if (r == null || r.build <= appBuild) {
    messenger.showSnackBar(SnackBar(content: Text('You’re on the latest version${appBuild > 0 ? ' (build $appBuild)' : ''}.')));
    return;
  }
  final rel = r;
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: p.bg,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 16),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.system_update_rounded, size: 40, color: p.salary),
          const SizedBox(height: 12),
          Text('Build ${rel.build} is ready', style: T.title.copyWith(color: p.ink)),
          const SizedBox(height: 8),
          Text(
            '${appBuild > 0 ? 'You have build $appBuild. ' : ''}Tap Download, then open the file to install. '
            'It installs over this version and keeps all your entries.',
            style: T.body.copyWith(color: p.muted, height: 1.45),
          ),
          const SizedBox(height: 18),
          BigButton('Download', onTap: () async {
            Navigator.pop(ctx);
            await _app.invokeMethod('openUrl', {'url': rel.apkUrl});
          }),
          const SizedBox(height: 10),
          BigButton('Later', filled: false, onTap: () => Navigator.pop(ctx)),
        ]),
      ),
    ),
  );
}
