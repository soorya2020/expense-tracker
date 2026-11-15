import 'package:flutter_test/flutter_test.dart';
import 'package:tally/features/sms/sms_parser.dart';

void main() {
  final at = DateTime(2026, 11, 14, 10, 42);

  test('HDFC UPI credit', () {
    final p = parseBankSms(
      sender: 'AX-HDFCBK',
      body: 'Rs.1,000.00 credited to a/c XX1234 on 14-11-26 by a/c linked to VPA rahul.s@okhdfcbank (UPI Ref No 431876543210).',
      at: at,
    )!;
    expect(p.direction, 'credit');
    expect(p.amount, 100000);
    expect(p.account, '••1234');
    expect(p.refNo, '431876543210');
    expect(p.bank, 'HDFC');
    expect(p.counterparty, 'Rahul S');
  });

  test('SBI debit by UPI', () {
    final p = parseBankSms(
      sender: 'VM-SBIUPI',
      body: 'Dear UPI user A/C X8890 debited by 389.0 on date 14Nov26 trf to SWIGGY Refno 431899887766. If not u? call 1800111109. -SBI',
      at: at,
    )!;
    expect(p.direction, 'debit');
    expect(p.amount, 38900);
    expect(p.account, '••8890');
    expect(p.counterparty, 'Swiggy');
    expect(p.refNo, '431899887766');
  });

  test('card spend', () {
    final p = parseBankSms(
      sender: 'JD-ICICIB-S',
      body: 'INR 1,200.00 spent on ICICI Bank Card XX4410 on 14-Nov-26 at INDIAN OIL. Avl Lmt: INR 45,000.00.',
      at: at,
    )!;
    expect(p.direction, 'debit');
    expect(p.amount, 120000);
    expect(p.account, '••4410');
    expect(p.counterparty, 'Indian Oil');
  });

  test('OTP and reminders are ignored', () {
    expect(parseBankSms(sender: 'AX-HDFCBK', body: 'OTP for txn of Rs 500 is 123456', at: at), isNull);
    expect(parseBankSms(sender: 'AX-HDFCBK', body: 'Your EMI of Rs 5,000 will be debited on 5th', at: at), isNull);
  });

  test('non-bank senders are ignored', () {
    expect(parseBankSms(sender: '+919876543210', body: 'Rs 500 credited', at: at), isNull);
    expect(parseBankSms(sender: 'AX-SWIGGY', body: 'Rs 500 credited to your wallet', at: at), isNull);
  });
}
