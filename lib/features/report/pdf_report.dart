import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../app/providers.dart';
import '../../core/money.dart';
import '../../data/db.dart';
import '../../data/repo.dart';
import '../../data/stats.dart';
import 'insights.dart';

const _ink = PdfColor.fromInt(0xFF0F1115);
const _muted = PdfColor.fromInt(0xFF7B8090);
const _line = PdfColor.fromInt(0xFFECEEF2);
const _surface = PdfColor.fromInt(0xFFF5F6F8);
const _salary = PdfColor.fromInt(0xFF2B4CFF);
const _salarySoft = PdfColor.fromInt(0xFFE8ECFF);
const _extra = PdfColor.fromInt(0xFFF29F05);
const _extraText = PdfColor.fromInt(0xFFA86A10);
const _extraSoft = PdfColor.fromInt(0xFFFFF3DC);
const _help = PdfColor.fromInt(0xFF12A594);
const _helpSoft = PdfColor.fromInt(0xFFDDF5F1);
const _over = PdfColor.fromInt(0xFFE5484D);

PdfColor _kindColor(String? k) => switch (k) {
      IncomeKind.salary => _salary,
      IncomeKind.extra => _extra,
      IncomeKind.help => _help,
      _ => _muted,
    };

/// Builds the report PDF and opens the share sheet (save to Files, WhatsApp, Drive...).
Future<void> shareReportPdf(CycleView v, List<CycleView> older, List<Entry> all, int startingBalance, DateTime startingDate) async {
  final bytes = await buildReportPdf(v, older, all, startingBalance, startingDate);
  final dir = await getTemporaryDirectory();
  final name = 'Tally-report-${DateFormat('MMM-yyyy').format(v.start)}.pdf';
  final f = File('${dir.path}/$name');
  await f.writeAsBytes(bytes, flush: true);
  await SharePlus.instance.share(ShareParams(files: [XFile(f.path, mimeType: 'application/pdf')], subject: name));
}

Future<List<int>> buildReportPdf(CycleView v, List<CycleView> older, List<Entry> all, int startingBalance, DateTime startingDate) async {
  Future<pw.Font> font(int w) async => pw.Font.ttf(await rootBundle.load('assets/fonts/InterTight-$w.ttf'));
  final f4 = await font(400), f6 = await font(600), f8 = await font(800), f9 = await font(900);
  final theme = pw.ThemeData.withFont(base: f4, bold: f8);

  final s = v.stats;
  final days = v.length;
  final range = rangeLabel(v.start, v.end);
  final upToEnd = all.where((e) => !effectiveDate(e).isAfter(v.end)).toList();
  final known = !v.end.isBefore(startingDate);
  final endBal = balance(upToEnd, startingBalance, startingDate);
  final startBal = endBal - s.net;

  pw.TextStyle st(pw.Font f, double size, [PdfColor c = _ink, double ls = 0]) =>
      pw.TextStyle(font: f, fontSize: size, color: c, letterSpacing: ls);
  final lab = st(f6, 8, _muted, .6);
  String r(int p) => rupees(p);
  String n(int p) => rupees(p, symbol: false);

  pw.Widget top(String right) => pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
        pw.Text('Tally', style: st(f9, 13, _ink, -.3)),
        pw.Text(right, style: st(f6, 9.5, _muted)),
      ]);
  pw.Widget foot(pw.Context c) => pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
        pw.Text('Made with Tally · everything stays on your phone', style: st(f4, 7.5, _muted)),
        pw.Text('Page ${c.pageNumber} of ${c.pagesCount}', style: st(f4, 7.5, _muted)),
      ]);

  // ----- Story sentence -----
  final story = <pw.TextSpan>[
    const pw.TextSpan(text: 'You spent '),
    pw.TextSpan(text: r(s.spent), style: const pw.TextStyle(color: _salary)),
  ];
  if (s.hasSalary) {
    if (s.overSalary > 0) {
      story.add(const pw.TextSpan(text: ', that’s '));
      story.add(pw.TextSpan(text: '${r(s.overSalary)} more than your salary', style: const pw.TextStyle(color: _over)));
      story.add(const pw.TextSpan(text: '. '));
      if (s.outside > 0) {
        final who = s.help > 0 ? (s.topSource(IncomeKind.help)?.name ?? 'Help') : (s.topSource(IncomeKind.extra)?.name ?? 'Extra money');
        story.add(pw.TextSpan(text: s.help > 0 ? 'Help from $who' : 'Extra money from $who', style: pw.TextStyle(color: s.help > 0 ? _help : _extra)));
        story.add(pw.TextSpan(text: s.net >= 0 ? ' filled the gap, so you still ended up ahead.' : ' covered part of the gap.'));
      }
    } else {
      story.add(pw.TextSpan(text: ', ${r(-s.overSalary)} less than your salary.'));
    }
  } else {
    story.add(const pw.TextSpan(text: '. No salary was logged this cycle.'));
  }

  pw.Widget tile(String l, String val) => pw.Expanded(
        child: pw.Container(
          margin: const pw.EdgeInsets.only(right: 8),
          padding: const pw.EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: pw.BoxDecoration(color: _surface, borderRadius: pw.BorderRadius.circular(12)),
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text(l, style: st(f6, 8, _muted)),
            pw.SizedBox(height: 3),
            pw.FittedBox(child: pw.Text(val, style: st(f8, 15, _ink, -.3))),
          ]),
        ),
      );

  // ----- Income bar -----
  final parts = [
    (s.salary, _salary, 'Salary'),
    (s.extra, _extra, 'Extra'),
    (s.help, _help, 'Help'),
    (s.borrowed, _muted, 'Borrowed'),
  ];
  int pct(int x) => s.income == 0 ? 0 : (x * 100 / s.income).round();

  // ----- Insights -----
  final cards = buildReport(v, older);
  const accents = [_over, _extra, _salary, _ink, _help];

  // ----- Chart -----
  final chartViews = [v, ...older.take(5)].reversed.toList();
  final maxV = chartViews.map((c) => c.stats.spent > c.stats.salary ? c.stats.spent : c.stats.salary).fold(1, (a, b) => a > b ? a : b);
  const ch = 120.0;
  final avgSalary = () {
    final sal = chartViews.where((c) => c.stats.salary > 0).toList();
    return sal.isEmpty ? 0 : sal.fold(0, (a, c) => a + c.stats.salary) ~/ sal.length;
  }();

  final doc = pw.Document(title: 'Tally report $range', author: 'Tally', theme: theme);

  doc.addPage(pw.Page(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.fromLTRB(50, 50, 50, 36),
    build: (c) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      top('Cycle report · $range · $days days'),
      pw.SizedBox(height: 26),
      pw.Text(s.net >= 0 ? 'YOU SAVED' : 'YOU OVERSPENT', style: lab),
      pw.SizedBox(height: 6),
      pw.Text(r(s.net.abs()), style: st(f9, 54, s.net >= 0 ? _ink : _over, -2.2)),
      pw.SizedBox(height: 14),
      pw.SizedBox(
        width: 420,
        child: pw.RichText(text: pw.TextSpan(style: st(f6, 14, _ink), children: story)),
      ),
      pw.SizedBox(height: 18),
      pw.Row(children: [
        tile('Came in', r(s.income)),
        tile('Went out', r(s.spent)),
        tile('Per day', r(s.spent ~/ days)),
        tile(known ? 'Balance on ${shortDate(v.end)}' : 'Result', known ? r(endBal) : resultLine(v)),
      ]),
      pw.SizedBox(height: 18),
      if (s.income > 0) ...[
        pw.Text('WHERE THE MONEY CAME FROM', style: lab),
        pw.SizedBox(height: 7),
        pw.Row(children: [
          for (final x in parts.where((x) => x.$1 > 0))
            pw.Expanded(
              flex: (x.$1 ~/ 100).clamp(1, 1 << 30),
              child: pw.Container(
                height: 9,
                margin: const pw.EdgeInsets.only(right: 2),
                decoration: pw.BoxDecoration(color: x.$2, borderRadius: pw.BorderRadius.circular(4)),
              ),
            ),
        ]),
        pw.SizedBox(height: 6),
        pw.Wrap(spacing: 14, children: [
          for (final x in parts.where((x) => x.$1 > 0 || x.$3 != 'Borrowed'))
            pw.Row(mainAxisSize: pw.MainAxisSize.min, children: [
              pw.Container(width: 6, height: 6, decoration: pw.BoxDecoration(color: x.$2, shape: pw.BoxShape.circle)),
              pw.SizedBox(width: 4),
              pw.Text('${x.$3} ${r(x.$1)}${x.$1 > 0 ? ' · ${pct(x.$1)}%' : ''}', style: st(f6, 8.5, _muted)),
            ]),
        ]),
        pw.SizedBox(height: 18),
      ],
      pw.Text('INSIGHTS', style: lab),
      pw.SizedBox(height: 7),
      pw.Wrap(spacing: 10, runSpacing: 10, children: [
        for (var k = 0; k < cards.length && k < 4; k++)
          pw.Container(
            width: 242,
            height: 64,
            padding: const pw.EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: pw.BoxDecoration(border: pw.Border.all(color: _line), borderRadius: pw.BorderRadius.circular(12)),
            child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Container(width: 3, height: 42, decoration: pw.BoxDecoration(color: accents[k % accents.length], borderRadius: pw.BorderRadius.circular(2))),
              pw.SizedBox(width: 9),
              pw.Expanded(
                child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Text(cards[k].headline.replaceAll('\n', ' '), style: st(f8, 10, _ink), maxLines: 1),
                  pw.SizedBox(height: 3),
                  pw.Text(cards[k].body, style: st(f4, 8.5, _muted).copyWith(lineSpacing: 1.5), maxLines: 3),
                ]),
              ),
            ]),
          ),
      ]),
      pw.SizedBox(height: 18),
      if (chartViews.length > 1) ...[
        pw.Text('LAST ${chartViews.length} CYCLES', style: lab),
        pw.SizedBox(height: 10),
        pw.SizedBox(
          height: ch,
          child: pw.Stack(children: [
            pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
              for (var k = 0; k < chartViews.length; k++)
                pw.Expanded(
                  child: pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 6),
                    child: pw.Column(mainAxisAlignment: pw.MainAxisAlignment.end, children: [
                      if (chartViews[k].stats.help > 0)
                        pw.Container(
                          height: ch * chartViews[k].stats.help.clamp(0, chartViews[k].stats.spent) / maxV,
                          decoration: const pw.BoxDecoration(color: _help, borderRadius: pw.BorderRadius.vertical(top: pw.Radius.circular(4))),
                        ),
                      pw.Container(
                        height: ch * (chartViews[k].stats.spent - chartViews[k].stats.help).clamp(0, 1 << 40) / maxV,
                        decoration: pw.BoxDecoration(
                          color: k == chartViews.length - 1 ? _salary : _ink,
                          borderRadius: chartViews[k].stats.help > 0 ? null : const pw.BorderRadius.vertical(top: pw.Radius.circular(4)),
                        ),
                      ),
                    ]),
                  ),
                ),
            ]),
            if (avgSalary > 0)
              pw.Positioned(
                left: 0,
                right: 0,
                bottom: ch * avgSalary / maxV,
                child: pw.Row(children: [
                  for (var k = 0; k < 60; k++)
                    pw.Expanded(child: pw.Container(height: 1.2, color: k.isEven ? _over : PdfColors.white)),
                ]),
              ),
            if (avgSalary > 0)
              pw.Positioned(
                right: 0,
                bottom: ch * avgSalary / maxV + 3,
                child: pw.Text('Salary ${r(avgSalary)}', style: st(f8, 7.5, _over)),
              ),
          ]),
        ),
        pw.Container(height: .8, color: _line),
        pw.SizedBox(height: 5),
        pw.Row(children: [
          for (var k = 0; k < chartViews.length; k++)
            pw.Expanded(
              child: pw.Center(
                child: pw.Text(DateFormat('MMM').format(chartViews[k].start),
                    style: st(f6, 8, k == chartViews.length - 1 ? _salary : _muted)),
              ),
            ),
        ]),
      ],
      pw.Spacer(),
      foot(c),
    ]),
  ));

  // ----- Page 2+: details -----
  final income = v.entries.where(isIncome).toList()..sort((a, b) => a.date.compareTo(b.date));
  final spending = v.entries.where((e) => !isIncome(e)).toList()..sort((a, b) => a.date.compareTo(b.date));
  final th = st(f8, 7.5, _muted, .8);
  final td = st(f4, 9.5);
  final tdb = st(f8, 9.5);

  pw.Widget cell(String t, pw.TextStyle style, {bool right = false}) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 7),
        child: pw.Text(t, style: style, textAlign: right ? pw.TextAlign.right : pw.TextAlign.left),
      );
  pw.Widget chip(String t, PdfColor bg, PdfColor fg) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 6),
        child: pw.Row(children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
            decoration: pw.BoxDecoration(color: bg, borderRadius: pw.BorderRadius.circular(20)),
            child: pw.Text(t, style: st(f8, 7.5, fg)),
          ),
        ]),
      );
  const rowLine = pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: _line, width: .8)));
  const headLine = pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: _ink, width: 1.2)));
  pw.Widget h2(String t) => pw.Padding(padding: const pw.EdgeInsets.only(top: 6, bottom: 10), child: pw.Text(t, style: st(f9, 19, _ink, -.6)));
  pw.TableRow total(List<String> cols) => pw.TableRow(children: [
        for (var k = 0; k < cols.length; k++) cell(cols[k], st(f9, 10.5), right: k == cols.length - 1),
      ]);

  pw.Widget sums(String title, List<(String, String, PdfColor)> rows, (String, String, PdfColor) last) => pw.Expanded(
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          h2(title),
          pw.Table(columnWidths: const {0: pw.FlexColumnWidth(), 1: pw.IntrinsicColumnWidth()}, children: [
            for (final x in rows)
              pw.TableRow(decoration: rowLine, children: [cell(x.$1, td), cell(x.$2, tdb.copyWith(color: x.$3), right: true)]),
            pw.TableRow(children: [cell(last.$1, st(f9, 10.5)), cell(last.$2, st(f9, 10.5, last.$3), right: true)]),
          ]),
        ]),
      );

  final yearly = all.where((e) => !isIncome(e) && e.yearly && !e.date.isAfter(v.end) && e.date.isAfter(v.end.subtract(const Duration(days: 365)))).toList();

  doc.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.fromLTRB(50, 50, 50, 36),
    header: (_) => pw.Padding(padding: const pw.EdgeInsets.only(bottom: 18), child: top('Cycle report · $range')),
    footer: foot,
    build: (c) => [
      h2('Money in'),
      if (income.isEmpty)
        pw.Text('Nothing came in this cycle.', style: st(f4, 10, _muted))
      else
        pw.Table(
          columnWidths: const {0: pw.FixedColumnWidth(70), 1: pw.FlexColumnWidth(2), 2: pw.FlexColumnWidth(1.4), 3: pw.FixedColumnWidth(80)},
          children: [
            pw.TableRow(decoration: headLine, children: [cell('DATE', th), cell('FROM', th), cell('KIND', th), cell('AMOUNT', th, right: true)]),
            for (final e in income)
              pw.TableRow(decoration: rowLine, children: [
                cell(shortDate(e.date), td),
                cell(e.source ?? e.title ?? IncomeKind.label(e.incomeKind ?? 'extra'), td),
                chip(
                  '${IncomeKind.label(e.incomeKind ?? 'extra')}${e.incomeKind == IncomeKind.borrowed && e.repaidAt != null ? ' · repaid' : ''}',
                  switch (e.incomeKind) { IncomeKind.salary => _salarySoft, IncomeKind.help => _helpSoft, IncomeKind.extra => _extraSoft, _ => _surface },
                  e.incomeKind == IncomeKind.extra ? _extraText : _kindColor(e.incomeKind),
                ),
                cell('+${n(e.amount)}', tdb.copyWith(color: e.incomeKind == IncomeKind.extra ? _extraText : _kindColor(e.incomeKind)), right: true),
              ]),
            total(['', 'Total', '', r(s.income)]),
          ],
        ),
      pw.SizedBox(height: 18),
      h2('Spending'),
      if (spending.isEmpty)
        pw.Text('No spending logged this cycle.', style: st(f4, 10, _muted))
      else
        pw.Table(
          columnWidths: const {0: pw.FixedColumnWidth(95), 1: pw.FlexColumnWidth(2), 2: pw.FlexColumnWidth(1.4), 3: pw.FixedColumnWidth(80)},
          children: [
            pw.TableRow(decoration: headLine, children: [cell('DATES', th), cell('WHAT', th), cell('TYPE', th), cell('AMOUNT', th, right: true)]),
            for (final e in spending)
              pw.TableRow(decoration: rowLine, children: [
                cell(e.endDate != null ? rangeLabel(e.date, e.endDate!) : shortDate(e.date), td),
                cell(e.title ?? 'Spending', td),
                e.unexpected
                    ? chip('Unexpected · ${Reasons.label(e.reason ?? 'other')}${e.yearly ? ' · yearly' : ''}', const PdfColor.fromInt(0xFFFDE8E8), _over)
                    : cell('Regular', td),
                cell('−${n(e.amount)}', tdb.copyWith(color: e.unexpected ? _over : _ink), right: true),
              ]),
            total(['', 'Total', '', r(s.spent)]),
          ],
        ),
      pw.SizedBox(height: 22),
      pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        sums(
          'The sums',
          [
            if (known) ('Balance on ${shortDate(v.start)}', r(startBal), _ink),
            ('+ Came in', r(s.income), _salary),
            ('− Went out', r(s.spent), _ink),
          ],
          known ? ('Balance on ${shortDate(v.end)}', r(endBal), _ink) : (s.net >= 0 ? 'Saved' : 'Overspent', r(s.net.abs()), s.net >= 0 ? _ink : _over),
        ),
        pw.SizedBox(width: 24),
        sums(
          'Against salary',
          [
            ('Salary', r(s.salary), _ink),
            ('Regular spending', r(s.regular), _ink),
            ('Unexpected costs', r(s.unexpected), s.unexpected > 0 ? _over : _ink),
          ],
          s.overSalary > 0 ? ('Past salary', r(s.overSalary), _over) : ('Left from salary', r(-s.overSalary), _salary),
        ),
      ]),
      if (yearly.isNotEmpty) ...[
        pw.SizedBox(height: 22),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: pw.BoxDecoration(color: _extraSoft, borderRadius: pw.BorderRadius.circular(12)),
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('Looking ahead', style: st(f8, 11.5)),
            pw.SizedBox(height: 4),
            pw.Text(
              '${yearly.map((e) => '${e.title ?? Reasons.label(e.reason ?? 'other')} (${r(e.amount)}) is due again around ${DateFormat('MMMM').format(e.date)}').join('. ')}. '
              'Setting aside ${r(yearly.fold(0, (a, e) => a + e.amount) ~/ 12)} a cycle from now means it won’t need help next time.',
              style: st(f4, 9.5).copyWith(lineSpacing: 2),
            ),
          ]),
        ),
      ],
    ],
  ));

  return doc.save();
}
