import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tally/app/theme.dart';
import 'package:tally/shared/widgets.dart';

void main() {
  testWidgets('BigButton in a bottom bar stays short', (t) async {
    await t.pumpWidget(MaterialApp(
      theme: buildTheme(Brightness.light),
      home: Scaffold(
        body: const SizedBox(),
        bottomNavigationBar: SafeArea(child: BigButton('Go', onTap: () {})),
      ),
    ));
    expect(t.getSize(find.byType(BigButton)).height, lessThan(80));
  });
}
