import 'dart:convert';

import 'package:flutter/material.dart';

import 'db.dart';
import 'settings.dart';

/// A spending category, such as Food or Travel.
class Cat {
  const Cat(this.id, this.label, this.color);
  final String id, label;
  final Color color;

  Map<String, Object> toJson() => {'id': id, 'label': label, 'color': color.toARGB32()};
  static Cat fromJson(Map<String, dynamic> j) => Cat(j['id'] as String, j['label'] as String, Color((j['color'] as num).toInt()));
}

const builtInCats = [
  Cat('food', 'Food', Color(0xFFE8590C)),
  Cat('groceries', 'Groceries', Color(0xFF2F9E44)),
  Cat('travel', 'Travel', Color(0xFF1C7ED6)),
  Cat('shopping', 'Shopping', Color(0xFFAE3EC9)),
  Cat('fuel', 'Fuel', Color(0xFF8D6E63)),
  Cat('bills', 'Bills', Color(0xFF5C6370)),
  Cat('health', 'Health', Color(0xFFD6336C)),
  Cat('other', 'Other', Color(0xFF94A3B8)),
];

/// Colours offered for categories you make yourself.
const customCatColors = [
  Color(0xFF0CA678), Color(0xFF7048E8), Color(0xFFF08C00), Color(0xFF1098AD), Color(0xFFE64980), Color(0xFF74B816),
];

/// Untagged spending, e.g. lumps added by hand.
const untaggedColor = Color(0xFFC9CDD6);

List<Cat> allCats(Settings s) => [
      ...builtInCats.where((c) => c.id != 'other'),
      ...((jsonDecode(s.customCatsJson) as List).cast<Map<String, dynamic>>().map(Cat.fromJson)),
      builtInCats.last,
    ];

Cat? catById(Settings s, String? id) {
  if (id == null) return null;
  for (final c in allCats(s)) {
    if (c.id == id) return c;
  }
  return null;
}

Future<Cat> addCustomCat(Settings s, String label) async {
  final list = (jsonDecode(s.customCatsJson) as List).cast<Map<String, dynamic>>().map(Cat.fromJson).toList();
  final c = Cat('c${DateTime.now().millisecondsSinceEpoch}', label.trim(), customCatColors[list.length % customCatColors.length]);
  await s.setCustomCatsJson(jsonEncode([...list, c].map((x) => x.toJson()).toList()));
  return c;
}

/// Shop names Tally knows, matched at the start of a word in the payee or message.
const _keywords = <String, List<String>>{
  'food': ['swiggy', 'zomato', 'domino', 'mcdonald', 'kfc', 'pizza', 'cafe', 'restaurant', 'starbucks', 'eatsure', 'burger', 'biryani', 'chai', 'bakery', 'haldiram', 'barbeque'],
  'groceries': ['zepto', 'blinkit', 'bigbasket', 'instamart', 'dmart', 'jiomart', 'grofers', 'reliance fresh', 'supermarket', 'more retail', 'spencer', 'kirana', 'milkbasket', 'country delight'],
  'travel': ['uber', 'ola', 'rapido', 'irctc', 'redbus', 'makemytrip', 'indigo', 'air india', 'akasa', 'metro', 'yatra', 'goibibo', 'fastag', 'cleartrip', 'ixigo', 'parking'],
  'shopping': ['amazon', 'flipkart', 'myntra', 'ajio', 'meesho', 'nykaa', 'croma', 'decathlon', 'reliance digital', 'tata cliq', 'lenskart', 'ikea', 'westside', 'zara', 'h&m'],
  'fuel': ['indian oil', 'iocl', 'hpcl', 'hindustan petroleum', 'bharat petroleum', 'bpcl', 'shell', 'petrol', 'fuel', 'nayara'],
  'bills': ['netflix', 'spotify', 'hotstar', 'prime video', 'airtel', 'jio', 'vodafone', 'bescom', 'electricity', 'broadband', 'fibernet', 'youtube', 'recharge', 'insurance', 'lic', 'tata play', 'gas', 'water', 'rent', 'emi', 'loan'],
  'health': ['apollo', 'pharmeasy', '1mg', 'netmeds', 'medplus', 'hospital', 'clinic', 'pharmacy', 'practo', 'diagnostic', 'lab', 'dental', 'cult.fit', 'cultfit', 'gym'],
};

String merchantKey(String? name) => (name ?? '').toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();

Map<String, String> catRules(Settings s) => (jsonDecode(s.catRulesJson) as Map).cast<String, String>();

/// Remembers that money to [merchant] always goes to [catId].
Future<void> learnCat(Settings s, String? merchant, String catId) async {
  final k = merchantKey(merchant);
  if (k.isEmpty) return;
  await s.setCatRulesJson(jsonEncode({...catRules(s), k: catId}));
}

/// Best guess for a payee: your own rules first, then known shop names.
String? guessCat(String? counterparty, String? text, Map<String, String> rules) {
  final k = merchantKey(counterparty);
  if (k.isNotEmpty && rules[k] != null) return rules[k];
  final hay = ' ${merchantKey(counterparty)} ${merchantKey(text)} ';
  for (final e in _keywords.entries) {
    for (final w in e.value) {
      if (hay.contains(' $w')) return e.key; // matches at the start of a word
    }
  }
  return null;
}

/// A bank message's category: the one you picked, or Tally's guess.
({String? id, bool auto}) smsCat(BankMessage m, Map<String, String> rules) {
  if (m.tag != null) return (id: m.tag, auto: false);
  final g = guessCat(m.counterparty, m.rawText, rules);
  return (id: g, auto: g != null);
}

/// An entry's category: the one picked, or a guess from its label (Rent counts as Bills).
String? entryCat(Entry e, Map<String, String> rules) => e.tag ?? guessCat(e.title, null, rules);
