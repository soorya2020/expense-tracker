import 'package:flutter_test/flutter_test.dart';
import 'package:tally/data/categories.dart';

void main() {
  test('guesses common shops and respects your own rules', () {
    expect(guessCat('SWIGGY', null, const {}), 'food');
    expect(guessCat('Uber India', null, const {}), 'travel');
    expect(guessCat('Indian Oil', null, const {}), 'fuel');
    expect(guessCat('Rent', null, const {}), 'bills');
    expect(guessCat('Ravi K', 'Rs 500 sent to Ravi K', const {}), isNull);
    expect(guessCat('Ravi K', null, const {'ravi k': 'groceries'}), 'groceries');
    // Only matches at the start of a word, so "parent" is not Rent.
    expect(guessCat('Parent', null, const {}), isNull);
  });
}
