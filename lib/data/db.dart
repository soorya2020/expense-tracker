import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'db.g.dart';

/// Kinds of entry.
abstract final class EntryKind {
  static const income = 'income';
  static const spending = 'spending';
}

/// Kinds of income. Everything except salary is money from outside your pay.
abstract final class IncomeKind {
  static const salary = 'salary';
  static const extra = 'extra';
  static const help = 'help';
  static const borrowed = 'borrowed';
  static const all = [salary, extra, help, borrowed];
  static String label(String k) => switch (k) {
        salary => 'Salary',
        extra => 'Extra',
        help => 'Help',
        borrowed => 'Borrowed',
        _ => k,
      };
}

abstract final class Reasons {
  static const all = ['medical', 'vehicle', 'insurance', 'family', 'other'];
  static String label(String r) => r[0].toUpperCase() + r.substring(1);
}

/// Every income and every lump of spending.
class Entries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get kind => text()();
  IntColumn get amount => integer()(); // paise
  TextColumn get incomeKind => text().nullable()();
  TextColumn get source => text().nullable()();
  TextColumn get title => text().nullable()();
  DateTimeColumn get date => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();
  TextColumn get category => text().nullable()();
  BoolColumn get unexpected => boolean().withDefault(const Constant(false))();
  TextColumn get reason => text().nullable()();
  BoolColumn get yearly => boolean().withDefault(const Constant(false))();
  IntColumn get helpedEntryId => integer().nullable()();
  DateTimeColumn get repaidAt => dateTime().nullable()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// One row per pay cycle. Real dates are stored so changing the start day
/// never rewrites the past.
class Cycles extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime()();
  DateTimeColumn get closedAt => dateTime().nullable()();
  BoolColumn get supported => boolean().nullable()(); // null = automatic
  TextColumn get note => text().nullable()();
  TextColumn get summary => text().nullable()(); // JSON saved at close
}

/// Bank messages read from SMS (Android).
@DataClassName('BankMessage')
class BankSms extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get refNo => text().unique()();
  TextColumn get direction => text()(); // credit | debit
  IntColumn get amount => integer()(); // paise
  TextColumn get account => text().nullable()();
  TextColumn get counterparty => text().nullable()();
  TextColumn get sender => text()();
  DateTimeColumn get receivedAt => dateTime()();
  TextColumn get status => text().withDefault(const Constant('new'))();
  IntColumn get entryId => integer().nullable()();
  TextColumn get rawText => text()();
}

@DriftDatabase(tables: [Entries, Cycles, BankSms])
class AppDb extends _$AppDb {
  AppDb([QueryExecutor? e]) : super(e ?? driftDatabase(name: 'tally'));

  @override
  int get schemaVersion => 1;
}
