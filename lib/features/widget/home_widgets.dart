import 'dart:convert';

import 'package:flutter/services.dart';

import '../../app/providers.dart';
import '../../core/money.dart';
import '../../data/budgets.dart';
import '../../data/daily.dart';
import '../../data/settings.dart';

const _ch = MethodChannel('tally/widget');
String? _last;

/// Sends today's numbers to the home screen widgets. Cheap to call often:
/// nothing is sent when the numbers haven't changed.
Future<void> pushWidgetData(Settings s, CycleView cur, int balance) async {
  final d = DailySpend.of(cur.entries, cur.start, cur.end, DateTime.now(), usualSalary: s.usualSalary);
  final hide = s.widgetHide;
  String money(int paise) => hide ? '₹ ••••' : rupees(paise);
  final safe = d.perDayLeft;
  final (pace, code) = switch (d.pace) {
    Pace.onTrack => ('On track', 'ok'),
    Pace.bitFast => ('A bit fast', 'warn'),
    Pace.tooFast => ('Too fast', 'bad'),
    Pace.pastSalary => ('Past salary', 'bad'),
    Pace.noSalary => ('', 'none'),
  };
  // One letter per day: r = rent and bills day, u/n/o = under, near or over the safe amount, t = today, - = still to come.
  final days = StringBuffer();
  for (var i = 0; i < d.length; i++) {
    if (i == d.dayNumber - 1) {
      days.write('t');
    } else if (i >= d.dayNumber) {
      days.write('-');
    } else if (d.fixed[i] > 0 && d.daily[i] == 0) {
      days.write('r');
    } else {
      final v = d.daily[i];
      days.write(safe <= 0 ? 'o' : v <= safe ? 'u' : v <= safe * 1.2 ? 'n' : 'o');
    }
  }
  final budgets = [
    for (final l in budgetLines(s, cur.entries).where((l) => l.cap != null).take(4))
      '${l.cat.label}|${(l.used * 100).round()}|${l.state.name}',
  ].join(';');
  final daysLeft = cur.length - cur.dayNumber;
  final sentence = switch (d.pace) {
    Pace.noSalary => 'Add your salary and Tally will tell you what you can spend each day.',
    Pace.pastSalary => 'You’ve spent past your salary this cycle. Go easy until payday.',
    _ => 'You can spend ${money(safe)} a day and still be fine on payday.',
  };
  final data = <String, String>{
    'safe': money(safe),
    'pace': pace,
    'paceCode': code,
    'avg': money(d.average),
    'balance': money(balance),
    'used': '${(d.salaryUsed * 100).round()}%',
    'usedFrac': d.salaryUsed.toStringAsFixed(3),
    'dayFrac': (d.dayNumber / d.length).toStringAsFixed(3),
    'daysLeft': '$daysLeft',
    'day': '${d.dayNumber}',
    'length': '${d.length}',
    'days': days.toString(),
    'daily': d.daily.map((x) => (x / 100).round()).join(','),
    'perDay': '${safe ~/ 100}',
    'budgets': budgets,
    'sentence': sentence,
    'cycle': rangeLabel(cur.start, cur.end),
  };
  final json = jsonEncode(data);
  if (json == _last) return;
  _last = json;
  try {
    await _ch.invokeMethod('update', data);
  } on MissingPluginException {
    // Not on Android (tests).
  } on PlatformException {
    _last = null;
  }
}
