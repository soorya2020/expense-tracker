import 'package:intl/intl.dart';

final _inr = NumberFormat.decimalPattern('en_IN');
final _date = DateFormat('d MMM');
final _dateLong = DateFormat('d MMM y');

/// Amounts are stored in paise. Shows rupees with Indian grouping, e.g. ₹1,00,000.
String rupees(int paise, {bool symbol = true}) {
  final r = (paise / 100).round();
  final s = _inr.format(r.abs());
  return '${r < 0 ? '−' : ''}${symbol ? '₹' : ''}$s';
}

/// Signed amount without the rupee symbol, e.g. +5,000 or −9,600.
String signed(int paise, {required bool positive}) =>
    '${positive ? '+' : '−'}${_inr.format((paise / 100).round().abs())}';

String shortDate(DateTime d) => _date.format(d);
String longDate(DateTime d) => _dateLong.format(d);

String rangeLabel(DateTime a, DateTime b) => '${shortDate(a)} – ${shortDate(b)}';

int rupeesToPaise(int rupees) => rupees * 100;
