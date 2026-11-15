import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tally/app/theme.dart';
import 'package:tally/features/sms/bank_sms_screen.dart';
import 'package:tally/shared/widgets.dart';

/// Bottom bars get the whole screen height to grow into. These make sure
/// they stay short on a real phone-sized screen.
void main() {
  Future<void> pumpBar(WidgetTester t, Widget bar) async {
    t.view.physicalSize = const Size(1080, 2400);
    t.view.devicePixelRatio = 2.625;
    addTearDown(t.view.reset);
    await t.pumpWidget(MaterialApp(
      theme: buildTheme(Brightness.light),
      home: Scaffold(body: const SizedBox(), bottomNavigationBar: SafeArea(child: Padding(padding: const EdgeInsets.all(12), child: bar))),
    ));
  }

  testWidgets('BigButton in a bottom bar stays short', (t) async {
    await pumpBar(t, BigButton('Go', onTap: () {}));
    expect(t.getSize(find.byType(BigButton)).height, lessThan(80));
  });

  testWidgets('Credits / Debits tabs in a bottom bar stay short', (t) async {
    await pumpBar(t, SmsTabs(debits: false, credits: 'Credits', debitsLabel: 'Debits · 56', onChanged: (_) {}));
    expect(t.getSize(find.byType(SmsTabs)).height, lessThan(80));
  });
}
