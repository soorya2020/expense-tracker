import 'package:flutter_test/flutter_test.dart';
import 'package:tally/core/cycle_math.dart';
import 'package:tally/core/money.dart';

void main() {
  group('cycle math', () {
    test('cycle on the 3rd', () {
      final s = cycleStartOnOrBefore(DateTime(2026, 11, 14), 3);
      expect(s, DateTime(2026, 11, 3));
      expect(cycleEndFor(s, 3), DateTime(2026, 12, 2));
    });

    test('before the start day falls into the previous cycle', () {
      expect(cycleStartOnOrBefore(DateTime(2026, 11, 2), 3), DateTime(2026, 10, 3));
    });

    test('year wraps', () {
      expect(cycleStartOnOrBefore(DateTime(2026, 1, 1), 5), DateTime(2025, 12, 5));
      expect(cycleEndFor(DateTime(2026, 12, 5), 5), DateTime(2027, 1, 4));
    });

    test('last day of month', () {
      expect(cycleStartOnOrBefore(DateTime(2026, 2, 27), lastDay), DateTime(2026, 1, 31));
      expect(cycleStartOnOrBefore(DateTime(2026, 2, 28), lastDay), DateTime(2026, 2, 28));
      expect(cycleEndFor(DateTime(2026, 2, 28), lastDay), DateTime(2026, 3, 30));
    });

    test('ordinals', () {
      expect(ordinal(1), '1st');
      expect(ordinal(3), '3rd');
      expect(ordinal(11), '11th');
      expect(ordinal(22), '22nd');
    });
  });

  test('rupees use Indian grouping', () {
    expect(rupees(10000000), '₹1,00,000');
    expect(signed(500000, positive: true), '+5,000');
  });
}
