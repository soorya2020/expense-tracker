/// Turns a bank SMS into a credit or debit. Pure Dart so it can be tested.
library;

class ParsedSms {
  ParsedSms({
    required this.direction,
    required this.amount,
    required this.refNo,
    required this.bank,
    this.account,
    this.counterparty,
  });
  final String direction; // credit | debit
  final int amount; // paise
  final String refNo;
  final String bank;
  final String? account; // "••1234"
  final String? counterparty;
}

const _banks = {
  'HDFC': 'HDFC', 'SBI': 'SBI', 'ICICI': 'ICICI', 'AXIS': 'Axis', 'KOTAK': 'Kotak', 'YES': 'Yes Bank',
  'IDFC': 'IDFC First', 'INDUS': 'IndusInd', 'PNB': 'PNB', 'BOB': 'Bank of Baroda', 'BARODA': 'Bank of Baroda',
  'CANARA': 'Canara', 'CNRB': 'Canara', 'UNION': 'Union Bank', 'UBOI': 'Union Bank', 'FEDERAL': 'Federal',
  'FED': 'Federal', 'IDBI': 'IDBI', 'BOI': 'Bank of India', 'CENTRAL': 'Central Bank', 'CBOI': 'Central Bank',
  'INDIAN': 'Indian Bank', 'IOB': 'IOB', 'RBL': 'RBL', 'AU': 'AU Bank', 'KVB': 'KVB', 'SIB': 'South Indian Bank',
  'CSB': 'CSB', 'DBS': 'DBS', 'HSBC': 'HSBC', 'SCB': 'Standard Chartered', 'PAYTM': 'Paytm Bank', 'AIRTEL': 'Airtel Bank',
  'JIO': 'Jio Bank', 'EQUITAS': 'Equitas', 'UJJIVAN': 'Ujjivan', 'SLICE': 'Slice', 'FINO': 'Fino',
};

/// Indian business SMS headers look like "AX-HDFCBK" or "VM-SBIUPI-S".
final _header = RegExp(r'^[A-Z]{2}-([A-Z0-9]{3,9})(?:-[A-Z])?$');

/// The bank's short name if [sender] looks like a bank, else null.
String? bankFromSender(String sender) {
  final m = _header.firstMatch(sender.toUpperCase().trim());
  if (m == null) return null;
  final id = m.group(1)!;
  for (final k in _banks.keys) {
    if (id.startsWith(k) || id.contains(k)) return _banks[k];
  }
  if (id.endsWith('BK') || id.endsWith('BNK') || id.contains('BANK')) return id.replaceAll(RegExp(r'BA?NK$|BK$'), '');
  return null;
}

final _amount = RegExp(r'(?:rs\.?|inr|₹)\s*([\d,]+(?:\.\d{1,2})?)', caseSensitive: false);
final _amountAfterVerb = RegExp(r'(?:debited|credited)\s+(?:by|with|for)?\s*(?:rs\.?|inr|₹)?\s*([\d,]+(?:\.\d{1,2})?)', caseSensitive: false);
final _account = RegExp(r'(?:a/c|ac|acct|account|card)\s*(?:no\.?)?\s*(?:ending\s*(?:with)?\s*)?[x*]*\s*(\d{3,6})', caseSensitive: false);
final _ref = RegExp(
  r'(?:upi\s*ref(?:\s*no)?|ref(?:erence)?\s*(?:no|number|#)?|txn\s*(?:id|no)?|imps\s*ref|neft\s*ref|utr)\s*[.:#-]?\s*([A-Za-z0-9]{6,})',
  caseSensitive: false,
);
final _skip = RegExp(
  r'\botp\b|one time password|will be (?:debited|credited)|is due|due (?:on|date)|requested|request to|reminder|declined|failed|reversed|minimum amount|statement|e-?mandate|autopay setup|cashback offer|pre-?approved|loan offer',
  caseSensitive: false,
);
final _creditWord = RegExp(r'\b(?:credited|received|deposited|added to)\b', caseSensitive: false);
final _debitWord = RegExp(r'\b(?:debited|spent|withdrawn|paid|sent|purchase|dr\b)', caseSensitive: false);

String? _name(String body, bool credit) {
  final vpa = RegExp(r'(?:vpa|upi id)\s*:?\s*([a-z0-9._-]+)@[a-z]+', caseSensitive: false).firstMatch(body);
  final pattern = credit
      ? RegExp(r'\b(?:from|by)\s+(?:vpa\s+)?([A-Za-z][A-Za-z .&]{1,40}?)(?=\s+(?:on|ref|refno|upi|via|a/c|ac|to|in)\b|[.(,]|\s*-|$)', caseSensitive: false)
      : RegExp(r'\b(?:to|at|towards|for)\s+(?:vpa\s+)?([A-Za-z][A-Za-z0-9 .&@_-]{1,40}?)(?=\s+(?:on|ref|refno|upi|via|from|using|thru|through)\b|[.(,]|\s*-|$)', caseSensitive: false);
  var n = pattern.firstMatch(body)?.group(1)?.trim();
  if (n != null) {
    final lower = n.toLowerCase();
    if (RegExp(r'^(your|a/c|ac|account|the|upi|card|vpa)\b').hasMatch(lower) || lower.length < 2) n = null;
  }
  n ??= vpa?.group(1);
  if (n == null) return null;
  if (n.contains('@')) n = n.split('@').first;
  n = n.replaceAll(RegExp(r'[._-]+'), ' ').trim();
  // Title-case shouty names: "RAHUL S" -> "Rahul S".
  return n.split(RegExp(r'\s+')).map((w) => w.length <= 1 ? w.toUpperCase() : w[0].toUpperCase() + w.substring(1).toLowerCase()).join(' ');
}

/// Returns null for anything that is not a completed credit or debit.
ParsedSms? parseBankSms({required String sender, required String body, required DateTime at}) {
  final bank = bankFromSender(sender);
  if (bank == null) return null;
  if (_skip.hasMatch(body)) return null;
  final c = _creditWord.firstMatch(body);
  final d = _debitWord.firstMatch(body);
  if (c == null && d == null) return null;
  final credit = c != null && (d == null || c.start < d.start);
  final a = _amount.firstMatch(body) ?? _amountAfterVerb.firstMatch(body);
  if (a == null) return null;
  final rupees = double.tryParse(a.group(1)!.replaceAll(',', ''));
  if (rupees == null || rupees <= 0) return null;
  final amount = (rupees * 100).round();
  final acct = _account.firstMatch(body)?.group(1);
  final ref = _ref.firstMatch(body)?.group(1) ?? '${sender.toUpperCase()}-${at.millisecondsSinceEpoch ~/ 60000}-$amount';
  return ParsedSms(
    direction: credit ? 'credit' : 'debit',
    amount: amount,
    refNo: ref,
    bank: bank,
    account: acct == null ? null : '••${acct.length > 4 ? acct.substring(acct.length - 4) : acct}',
    counterparty: _name(body, credit),
  );
}
