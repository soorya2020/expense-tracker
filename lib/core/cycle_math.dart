/// Pure date math for pay cycles. A cycle starts on a chosen day of the month
/// (1–28) or on the last day of the month ([lastDay]).
library;

const int lastDay = 0;

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

int daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

/// The start date for [cycleDay] in the given month. Days past the end of the
/// month, and [lastDay], fall on the month's last day.
DateTime startInMonth(int year, int month, int cycleDay) {
  final norm = DateTime(year, month, 1);
  final dim = daysInMonth(norm.year, norm.month);
  final day = (cycleDay == lastDay || cycleDay > dim) ? dim : cycleDay;
  return DateTime(norm.year, norm.month, day);
}

/// The most recent cycle start on or before [date].
DateTime cycleStartOnOrBefore(DateTime date, int cycleDay) {
  final d = dateOnly(date);
  final here = startInMonth(d.year, d.month, cycleDay);
  if (!d.isBefore(here)) return here;
  return startInMonth(d.year, d.month - 1, cycleDay);
}

/// The first cycle start strictly after [date].
DateTime nextCycleStartAfter(DateTime date, int cycleDay) {
  final d = dateOnly(date);
  final here = startInMonth(d.year, d.month, cycleDay);
  if (here.isAfter(d)) return here;
  return startInMonth(d.year, d.month + 1, cycleDay);
}

/// Inclusive end date of a cycle that starts on [start].
DateTime cycleEndFor(DateTime start, int cycleDay) =>
    nextCycleStartAfter(start, cycleDay).subtract(const Duration(days: 1));

int daysBetweenInclusive(DateTime a, DateTime b) =>
    dateOnly(b).difference(dateOnly(a)).inDays + 1;

String ordinal(int n) {
  if (n == lastDay) return 'last day';
  if (n % 100 >= 11 && n % 100 <= 13) return '${n}th';
  switch (n % 10) {
    case 1:
      return '${n}st';
    case 2:
      return '${n}nd';
    case 3:
      return '${n}rd';
    default:
      return '${n}th';
  }
}
