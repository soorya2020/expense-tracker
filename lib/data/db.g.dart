// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'db.dart';

// ignore_for_file: type=lint
class $EntriesTable extends Entries with TableInfo<$EntriesTable, Entry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _incomeKindMeta = const VerificationMeta(
    'incomeKind',
  );
  @override
  late final GeneratedColumn<String> incomeKind = GeneratedColumn<String>(
    'income_kind',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endDateMeta = const VerificationMeta(
    'endDate',
  );
  @override
  late final GeneratedColumn<DateTime> endDate = GeneratedColumn<DateTime>(
    'end_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unexpectedMeta = const VerificationMeta(
    'unexpected',
  );
  @override
  late final GeneratedColumn<bool> unexpected = GeneratedColumn<bool>(
    'unexpected',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("unexpected" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _yearlyMeta = const VerificationMeta('yearly');
  @override
  late final GeneratedColumn<bool> yearly = GeneratedColumn<bool>(
    'yearly',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("yearly" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _helpedEntryIdMeta = const VerificationMeta(
    'helpedEntryId',
  );
  @override
  late final GeneratedColumn<int> helpedEntryId = GeneratedColumn<int>(
    'helped_entry_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _repaidAtMeta = const VerificationMeta(
    'repaidAt',
  );
  @override
  late final GeneratedColumn<DateTime> repaidAt = GeneratedColumn<DateTime>(
    'repaid_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _tagMeta = const VerificationMeta('tag');
  @override
  late final GeneratedColumn<String> tag = GeneratedColumn<String>(
    'tag',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    kind,
    amount,
    incomeKind,
    source,
    title,
    date,
    endDate,
    category,
    unexpected,
    reason,
    yearly,
    helpedEntryId,
    repaidAt,
    note,
    createdAt,
    tag,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<Entry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('income_kind')) {
      context.handle(
        _incomeKindMeta,
        incomeKind.isAcceptableOrUnknown(data['income_kind']!, _incomeKindMeta),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('end_date')) {
      context.handle(
        _endDateMeta,
        endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta),
      );
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('unexpected')) {
      context.handle(
        _unexpectedMeta,
        unexpected.isAcceptableOrUnknown(data['unexpected']!, _unexpectedMeta),
      );
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    }
    if (data.containsKey('yearly')) {
      context.handle(
        _yearlyMeta,
        yearly.isAcceptableOrUnknown(data['yearly']!, _yearlyMeta),
      );
    }
    if (data.containsKey('helped_entry_id')) {
      context.handle(
        _helpedEntryIdMeta,
        helpedEntryId.isAcceptableOrUnknown(
          data['helped_entry_id']!,
          _helpedEntryIdMeta,
        ),
      );
    }
    if (data.containsKey('repaid_at')) {
      context.handle(
        _repaidAtMeta,
        repaidAt.isAcceptableOrUnknown(data['repaid_at']!, _repaidAtMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('tag')) {
      context.handle(
        _tagMeta,
        tag.isAcceptableOrUnknown(data['tag']!, _tagMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Entry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Entry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount'],
      )!,
      incomeKind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}income_kind'],
      ),
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      ),
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      endDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}end_date'],
      ),
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      ),
      unexpected: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}unexpected'],
      )!,
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      ),
      yearly: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}yearly'],
      )!,
      helpedEntryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}helped_entry_id'],
      ),
      repaidAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}repaid_at'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      tag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tag'],
      ),
    );
  }

  @override
  $EntriesTable createAlias(String alias) {
    return $EntriesTable(attachedDatabase, alias);
  }
}

class Entry extends DataClass implements Insertable<Entry> {
  final int id;
  final String kind;
  final int amount;
  final String? incomeKind;
  final String? source;
  final String? title;
  final DateTime date;
  final DateTime? endDate;
  final String? category;
  final bool unexpected;
  final String? reason;
  final bool yearly;
  final int? helpedEntryId;
  final DateTime? repaidAt;
  final String? note;
  final DateTime createdAt;
  final String? tag;
  const Entry({
    required this.id,
    required this.kind,
    required this.amount,
    this.incomeKind,
    this.source,
    this.title,
    required this.date,
    this.endDate,
    this.category,
    required this.unexpected,
    this.reason,
    required this.yearly,
    this.helpedEntryId,
    this.repaidAt,
    this.note,
    required this.createdAt,
    this.tag,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['kind'] = Variable<String>(kind);
    map['amount'] = Variable<int>(amount);
    if (!nullToAbsent || incomeKind != null) {
      map['income_kind'] = Variable<String>(incomeKind);
    }
    if (!nullToAbsent || source != null) {
      map['source'] = Variable<String>(source);
    }
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    map['date'] = Variable<DateTime>(date);
    if (!nullToAbsent || endDate != null) {
      map['end_date'] = Variable<DateTime>(endDate);
    }
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    map['unexpected'] = Variable<bool>(unexpected);
    if (!nullToAbsent || reason != null) {
      map['reason'] = Variable<String>(reason);
    }
    map['yearly'] = Variable<bool>(yearly);
    if (!nullToAbsent || helpedEntryId != null) {
      map['helped_entry_id'] = Variable<int>(helpedEntryId);
    }
    if (!nullToAbsent || repaidAt != null) {
      map['repaid_at'] = Variable<DateTime>(repaidAt);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || tag != null) {
      map['tag'] = Variable<String>(tag);
    }
    return map;
  }

  EntriesCompanion toCompanion(bool nullToAbsent) {
    return EntriesCompanion(
      id: Value(id),
      kind: Value(kind),
      amount: Value(amount),
      incomeKind: incomeKind == null && nullToAbsent
          ? const Value.absent()
          : Value(incomeKind),
      source: source == null && nullToAbsent
          ? const Value.absent()
          : Value(source),
      title: title == null && nullToAbsent
          ? const Value.absent()
          : Value(title),
      date: Value(date),
      endDate: endDate == null && nullToAbsent
          ? const Value.absent()
          : Value(endDate),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      unexpected: Value(unexpected),
      reason: reason == null && nullToAbsent
          ? const Value.absent()
          : Value(reason),
      yearly: Value(yearly),
      helpedEntryId: helpedEntryId == null && nullToAbsent
          ? const Value.absent()
          : Value(helpedEntryId),
      repaidAt: repaidAt == null && nullToAbsent
          ? const Value.absent()
          : Value(repaidAt),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAt: Value(createdAt),
      tag: tag == null && nullToAbsent ? const Value.absent() : Value(tag),
    );
  }

  factory Entry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Entry(
      id: serializer.fromJson<int>(json['id']),
      kind: serializer.fromJson<String>(json['kind']),
      amount: serializer.fromJson<int>(json['amount']),
      incomeKind: serializer.fromJson<String?>(json['incomeKind']),
      source: serializer.fromJson<String?>(json['source']),
      title: serializer.fromJson<String?>(json['title']),
      date: serializer.fromJson<DateTime>(json['date']),
      endDate: serializer.fromJson<DateTime?>(json['endDate']),
      category: serializer.fromJson<String?>(json['category']),
      unexpected: serializer.fromJson<bool>(json['unexpected']),
      reason: serializer.fromJson<String?>(json['reason']),
      yearly: serializer.fromJson<bool>(json['yearly']),
      helpedEntryId: serializer.fromJson<int?>(json['helpedEntryId']),
      repaidAt: serializer.fromJson<DateTime?>(json['repaidAt']),
      note: serializer.fromJson<String?>(json['note']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      tag: serializer.fromJson<String?>(json['tag']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'kind': serializer.toJson<String>(kind),
      'amount': serializer.toJson<int>(amount),
      'incomeKind': serializer.toJson<String?>(incomeKind),
      'source': serializer.toJson<String?>(source),
      'title': serializer.toJson<String?>(title),
      'date': serializer.toJson<DateTime>(date),
      'endDate': serializer.toJson<DateTime?>(endDate),
      'category': serializer.toJson<String?>(category),
      'unexpected': serializer.toJson<bool>(unexpected),
      'reason': serializer.toJson<String?>(reason),
      'yearly': serializer.toJson<bool>(yearly),
      'helpedEntryId': serializer.toJson<int?>(helpedEntryId),
      'repaidAt': serializer.toJson<DateTime?>(repaidAt),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'tag': serializer.toJson<String?>(tag),
    };
  }

  Entry copyWith({
    int? id,
    String? kind,
    int? amount,
    Value<String?> incomeKind = const Value.absent(),
    Value<String?> source = const Value.absent(),
    Value<String?> title = const Value.absent(),
    DateTime? date,
    Value<DateTime?> endDate = const Value.absent(),
    Value<String?> category = const Value.absent(),
    bool? unexpected,
    Value<String?> reason = const Value.absent(),
    bool? yearly,
    Value<int?> helpedEntryId = const Value.absent(),
    Value<DateTime?> repaidAt = const Value.absent(),
    Value<String?> note = const Value.absent(),
    DateTime? createdAt,
    Value<String?> tag = const Value.absent(),
  }) => Entry(
    id: id ?? this.id,
    kind: kind ?? this.kind,
    amount: amount ?? this.amount,
    incomeKind: incomeKind.present ? incomeKind.value : this.incomeKind,
    source: source.present ? source.value : this.source,
    title: title.present ? title.value : this.title,
    date: date ?? this.date,
    endDate: endDate.present ? endDate.value : this.endDate,
    category: category.present ? category.value : this.category,
    unexpected: unexpected ?? this.unexpected,
    reason: reason.present ? reason.value : this.reason,
    yearly: yearly ?? this.yearly,
    helpedEntryId: helpedEntryId.present
        ? helpedEntryId.value
        : this.helpedEntryId,
    repaidAt: repaidAt.present ? repaidAt.value : this.repaidAt,
    note: note.present ? note.value : this.note,
    createdAt: createdAt ?? this.createdAt,
    tag: tag.present ? tag.value : this.tag,
  );
  Entry copyWithCompanion(EntriesCompanion data) {
    return Entry(
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      amount: data.amount.present ? data.amount.value : this.amount,
      incomeKind: data.incomeKind.present
          ? data.incomeKind.value
          : this.incomeKind,
      source: data.source.present ? data.source.value : this.source,
      title: data.title.present ? data.title.value : this.title,
      date: data.date.present ? data.date.value : this.date,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      category: data.category.present ? data.category.value : this.category,
      unexpected: data.unexpected.present
          ? data.unexpected.value
          : this.unexpected,
      reason: data.reason.present ? data.reason.value : this.reason,
      yearly: data.yearly.present ? data.yearly.value : this.yearly,
      helpedEntryId: data.helpedEntryId.present
          ? data.helpedEntryId.value
          : this.helpedEntryId,
      repaidAt: data.repaidAt.present ? data.repaidAt.value : this.repaidAt,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      tag: data.tag.present ? data.tag.value : this.tag,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Entry(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('amount: $amount, ')
          ..write('incomeKind: $incomeKind, ')
          ..write('source: $source, ')
          ..write('title: $title, ')
          ..write('date: $date, ')
          ..write('endDate: $endDate, ')
          ..write('category: $category, ')
          ..write('unexpected: $unexpected, ')
          ..write('reason: $reason, ')
          ..write('yearly: $yearly, ')
          ..write('helpedEntryId: $helpedEntryId, ')
          ..write('repaidAt: $repaidAt, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('tag: $tag')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    kind,
    amount,
    incomeKind,
    source,
    title,
    date,
    endDate,
    category,
    unexpected,
    reason,
    yearly,
    helpedEntryId,
    repaidAt,
    note,
    createdAt,
    tag,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Entry &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.amount == this.amount &&
          other.incomeKind == this.incomeKind &&
          other.source == this.source &&
          other.title == this.title &&
          other.date == this.date &&
          other.endDate == this.endDate &&
          other.category == this.category &&
          other.unexpected == this.unexpected &&
          other.reason == this.reason &&
          other.yearly == this.yearly &&
          other.helpedEntryId == this.helpedEntryId &&
          other.repaidAt == this.repaidAt &&
          other.note == this.note &&
          other.createdAt == this.createdAt &&
          other.tag == this.tag);
}

class EntriesCompanion extends UpdateCompanion<Entry> {
  final Value<int> id;
  final Value<String> kind;
  final Value<int> amount;
  final Value<String?> incomeKind;
  final Value<String?> source;
  final Value<String?> title;
  final Value<DateTime> date;
  final Value<DateTime?> endDate;
  final Value<String?> category;
  final Value<bool> unexpected;
  final Value<String?> reason;
  final Value<bool> yearly;
  final Value<int?> helpedEntryId;
  final Value<DateTime?> repaidAt;
  final Value<String?> note;
  final Value<DateTime> createdAt;
  final Value<String?> tag;
  const EntriesCompanion({
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.amount = const Value.absent(),
    this.incomeKind = const Value.absent(),
    this.source = const Value.absent(),
    this.title = const Value.absent(),
    this.date = const Value.absent(),
    this.endDate = const Value.absent(),
    this.category = const Value.absent(),
    this.unexpected = const Value.absent(),
    this.reason = const Value.absent(),
    this.yearly = const Value.absent(),
    this.helpedEntryId = const Value.absent(),
    this.repaidAt = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.tag = const Value.absent(),
  });
  EntriesCompanion.insert({
    this.id = const Value.absent(),
    required String kind,
    required int amount,
    this.incomeKind = const Value.absent(),
    this.source = const Value.absent(),
    this.title = const Value.absent(),
    required DateTime date,
    this.endDate = const Value.absent(),
    this.category = const Value.absent(),
    this.unexpected = const Value.absent(),
    this.reason = const Value.absent(),
    this.yearly = const Value.absent(),
    this.helpedEntryId = const Value.absent(),
    this.repaidAt = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.tag = const Value.absent(),
  }) : kind = Value(kind),
       amount = Value(amount),
       date = Value(date);
  static Insertable<Entry> custom({
    Expression<int>? id,
    Expression<String>? kind,
    Expression<int>? amount,
    Expression<String>? incomeKind,
    Expression<String>? source,
    Expression<String>? title,
    Expression<DateTime>? date,
    Expression<DateTime>? endDate,
    Expression<String>? category,
    Expression<bool>? unexpected,
    Expression<String>? reason,
    Expression<bool>? yearly,
    Expression<int>? helpedEntryId,
    Expression<DateTime>? repaidAt,
    Expression<String>? note,
    Expression<DateTime>? createdAt,
    Expression<String>? tag,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (amount != null) 'amount': amount,
      if (incomeKind != null) 'income_kind': incomeKind,
      if (source != null) 'source': source,
      if (title != null) 'title': title,
      if (date != null) 'date': date,
      if (endDate != null) 'end_date': endDate,
      if (category != null) 'category': category,
      if (unexpected != null) 'unexpected': unexpected,
      if (reason != null) 'reason': reason,
      if (yearly != null) 'yearly': yearly,
      if (helpedEntryId != null) 'helped_entry_id': helpedEntryId,
      if (repaidAt != null) 'repaid_at': repaidAt,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
      if (tag != null) 'tag': tag,
    });
  }

  EntriesCompanion copyWith({
    Value<int>? id,
    Value<String>? kind,
    Value<int>? amount,
    Value<String?>? incomeKind,
    Value<String?>? source,
    Value<String?>? title,
    Value<DateTime>? date,
    Value<DateTime?>? endDate,
    Value<String?>? category,
    Value<bool>? unexpected,
    Value<String?>? reason,
    Value<bool>? yearly,
    Value<int?>? helpedEntryId,
    Value<DateTime?>? repaidAt,
    Value<String?>? note,
    Value<DateTime>? createdAt,
    Value<String?>? tag,
  }) {
    return EntriesCompanion(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      amount: amount ?? this.amount,
      incomeKind: incomeKind ?? this.incomeKind,
      source: source ?? this.source,
      title: title ?? this.title,
      date: date ?? this.date,
      endDate: endDate ?? this.endDate,
      category: category ?? this.category,
      unexpected: unexpected ?? this.unexpected,
      reason: reason ?? this.reason,
      yearly: yearly ?? this.yearly,
      helpedEntryId: helpedEntryId ?? this.helpedEntryId,
      repaidAt: repaidAt ?? this.repaidAt,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      tag: tag ?? this.tag,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (incomeKind.present) {
      map['income_kind'] = Variable<String>(incomeKind.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<DateTime>(endDate.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (unexpected.present) {
      map['unexpected'] = Variable<bool>(unexpected.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (yearly.present) {
      map['yearly'] = Variable<bool>(yearly.value);
    }
    if (helpedEntryId.present) {
      map['helped_entry_id'] = Variable<int>(helpedEntryId.value);
    }
    if (repaidAt.present) {
      map['repaid_at'] = Variable<DateTime>(repaidAt.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (tag.present) {
      map['tag'] = Variable<String>(tag.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EntriesCompanion(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('amount: $amount, ')
          ..write('incomeKind: $incomeKind, ')
          ..write('source: $source, ')
          ..write('title: $title, ')
          ..write('date: $date, ')
          ..write('endDate: $endDate, ')
          ..write('category: $category, ')
          ..write('unexpected: $unexpected, ')
          ..write('reason: $reason, ')
          ..write('yearly: $yearly, ')
          ..write('helpedEntryId: $helpedEntryId, ')
          ..write('repaidAt: $repaidAt, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('tag: $tag')
          ..write(')'))
        .toString();
  }
}

class $CyclesTable extends Cycles with TableInfo<$CyclesTable, Cycle> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CyclesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<DateTime> startDate = GeneratedColumn<DateTime>(
    'start_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endDateMeta = const VerificationMeta(
    'endDate',
  );
  @override
  late final GeneratedColumn<DateTime> endDate = GeneratedColumn<DateTime>(
    'end_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _closedAtMeta = const VerificationMeta(
    'closedAt',
  );
  @override
  late final GeneratedColumn<DateTime> closedAt = GeneratedColumn<DateTime>(
    'closed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _supportedMeta = const VerificationMeta(
    'supported',
  );
  @override
  late final GeneratedColumn<bool> supported = GeneratedColumn<bool>(
    'supported',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("supported" IN (0, 1))',
    ),
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _summaryMeta = const VerificationMeta(
    'summary',
  );
  @override
  late final GeneratedColumn<String> summary = GeneratedColumn<String>(
    'summary',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    startDate,
    endDate,
    closedAt,
    supported,
    note,
    summary,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cycles';
  @override
  VerificationContext validateIntegrity(
    Insertable<Cycle> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('end_date')) {
      context.handle(
        _endDateMeta,
        endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta),
      );
    } else if (isInserting) {
      context.missing(_endDateMeta);
    }
    if (data.containsKey('closed_at')) {
      context.handle(
        _closedAtMeta,
        closedAt.isAcceptableOrUnknown(data['closed_at']!, _closedAtMeta),
      );
    }
    if (data.containsKey('supported')) {
      context.handle(
        _supportedMeta,
        supported.isAcceptableOrUnknown(data['supported']!, _supportedMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('summary')) {
      context.handle(
        _summaryMeta,
        summary.isAcceptableOrUnknown(data['summary']!, _summaryMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Cycle map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Cycle(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_date'],
      )!,
      endDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}end_date'],
      )!,
      closedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}closed_at'],
      ),
      supported: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}supported'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      summary: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}summary'],
      ),
    );
  }

  @override
  $CyclesTable createAlias(String alias) {
    return $CyclesTable(attachedDatabase, alias);
  }
}

class Cycle extends DataClass implements Insertable<Cycle> {
  final int id;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime? closedAt;
  final bool? supported;
  final String? note;
  final String? summary;
  const Cycle({
    required this.id,
    required this.startDate,
    required this.endDate,
    this.closedAt,
    this.supported,
    this.note,
    this.summary,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['start_date'] = Variable<DateTime>(startDate);
    map['end_date'] = Variable<DateTime>(endDate);
    if (!nullToAbsent || closedAt != null) {
      map['closed_at'] = Variable<DateTime>(closedAt);
    }
    if (!nullToAbsent || supported != null) {
      map['supported'] = Variable<bool>(supported);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || summary != null) {
      map['summary'] = Variable<String>(summary);
    }
    return map;
  }

  CyclesCompanion toCompanion(bool nullToAbsent) {
    return CyclesCompanion(
      id: Value(id),
      startDate: Value(startDate),
      endDate: Value(endDate),
      closedAt: closedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(closedAt),
      supported: supported == null && nullToAbsent
          ? const Value.absent()
          : Value(supported),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      summary: summary == null && nullToAbsent
          ? const Value.absent()
          : Value(summary),
    );
  }

  factory Cycle.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Cycle(
      id: serializer.fromJson<int>(json['id']),
      startDate: serializer.fromJson<DateTime>(json['startDate']),
      endDate: serializer.fromJson<DateTime>(json['endDate']),
      closedAt: serializer.fromJson<DateTime?>(json['closedAt']),
      supported: serializer.fromJson<bool?>(json['supported']),
      note: serializer.fromJson<String?>(json['note']),
      summary: serializer.fromJson<String?>(json['summary']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'startDate': serializer.toJson<DateTime>(startDate),
      'endDate': serializer.toJson<DateTime>(endDate),
      'closedAt': serializer.toJson<DateTime?>(closedAt),
      'supported': serializer.toJson<bool?>(supported),
      'note': serializer.toJson<String?>(note),
      'summary': serializer.toJson<String?>(summary),
    };
  }

  Cycle copyWith({
    int? id,
    DateTime? startDate,
    DateTime? endDate,
    Value<DateTime?> closedAt = const Value.absent(),
    Value<bool?> supported = const Value.absent(),
    Value<String?> note = const Value.absent(),
    Value<String?> summary = const Value.absent(),
  }) => Cycle(
    id: id ?? this.id,
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    closedAt: closedAt.present ? closedAt.value : this.closedAt,
    supported: supported.present ? supported.value : this.supported,
    note: note.present ? note.value : this.note,
    summary: summary.present ? summary.value : this.summary,
  );
  Cycle copyWithCompanion(CyclesCompanion data) {
    return Cycle(
      id: data.id.present ? data.id.value : this.id,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      closedAt: data.closedAt.present ? data.closedAt.value : this.closedAt,
      supported: data.supported.present ? data.supported.value : this.supported,
      note: data.note.present ? data.note.value : this.note,
      summary: data.summary.present ? data.summary.value : this.summary,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Cycle(')
          ..write('id: $id, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('closedAt: $closedAt, ')
          ..write('supported: $supported, ')
          ..write('note: $note, ')
          ..write('summary: $summary')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, startDate, endDate, closedAt, supported, note, summary);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Cycle &&
          other.id == this.id &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate &&
          other.closedAt == this.closedAt &&
          other.supported == this.supported &&
          other.note == this.note &&
          other.summary == this.summary);
}

class CyclesCompanion extends UpdateCompanion<Cycle> {
  final Value<int> id;
  final Value<DateTime> startDate;
  final Value<DateTime> endDate;
  final Value<DateTime?> closedAt;
  final Value<bool?> supported;
  final Value<String?> note;
  final Value<String?> summary;
  const CyclesCompanion({
    this.id = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.closedAt = const Value.absent(),
    this.supported = const Value.absent(),
    this.note = const Value.absent(),
    this.summary = const Value.absent(),
  });
  CyclesCompanion.insert({
    this.id = const Value.absent(),
    required DateTime startDate,
    required DateTime endDate,
    this.closedAt = const Value.absent(),
    this.supported = const Value.absent(),
    this.note = const Value.absent(),
    this.summary = const Value.absent(),
  }) : startDate = Value(startDate),
       endDate = Value(endDate);
  static Insertable<Cycle> custom({
    Expression<int>? id,
    Expression<DateTime>? startDate,
    Expression<DateTime>? endDate,
    Expression<DateTime>? closedAt,
    Expression<bool>? supported,
    Expression<String>? note,
    Expression<String>? summary,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (closedAt != null) 'closed_at': closedAt,
      if (supported != null) 'supported': supported,
      if (note != null) 'note': note,
      if (summary != null) 'summary': summary,
    });
  }

  CyclesCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? startDate,
    Value<DateTime>? endDate,
    Value<DateTime?>? closedAt,
    Value<bool?>? supported,
    Value<String?>? note,
    Value<String?>? summary,
  }) {
    return CyclesCompanion(
      id: id ?? this.id,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      closedAt: closedAt ?? this.closedAt,
      supported: supported ?? this.supported,
      note: note ?? this.note,
      summary: summary ?? this.summary,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<DateTime>(startDate.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<DateTime>(endDate.value);
    }
    if (closedAt.present) {
      map['closed_at'] = Variable<DateTime>(closedAt.value);
    }
    if (supported.present) {
      map['supported'] = Variable<bool>(supported.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (summary.present) {
      map['summary'] = Variable<String>(summary.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CyclesCompanion(')
          ..write('id: $id, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('closedAt: $closedAt, ')
          ..write('supported: $supported, ')
          ..write('note: $note, ')
          ..write('summary: $summary')
          ..write(')'))
        .toString();
  }
}

class $BankSmsTable extends BankSms with TableInfo<$BankSmsTable, BankMessage> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BankSmsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _refNoMeta = const VerificationMeta('refNo');
  @override
  late final GeneratedColumn<String> refNo = GeneratedColumn<String>(
    'ref_no',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _directionMeta = const VerificationMeta(
    'direction',
  );
  @override
  late final GeneratedColumn<String> direction = GeneratedColumn<String>(
    'direction',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accountMeta = const VerificationMeta(
    'account',
  );
  @override
  late final GeneratedColumn<String> account = GeneratedColumn<String>(
    'account',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _counterpartyMeta = const VerificationMeta(
    'counterparty',
  );
  @override
  late final GeneratedColumn<String> counterparty = GeneratedColumn<String>(
    'counterparty',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _senderMeta = const VerificationMeta('sender');
  @override
  late final GeneratedColumn<String> sender = GeneratedColumn<String>(
    'sender',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _receivedAtMeta = const VerificationMeta(
    'receivedAt',
  );
  @override
  late final GeneratedColumn<DateTime> receivedAt = GeneratedColumn<DateTime>(
    'received_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('new'),
  );
  static const VerificationMeta _entryIdMeta = const VerificationMeta(
    'entryId',
  );
  @override
  late final GeneratedColumn<int> entryId = GeneratedColumn<int>(
    'entry_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rawTextMeta = const VerificationMeta(
    'rawText',
  );
  @override
  late final GeneratedColumn<String> rawText = GeneratedColumn<String>(
    'raw_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tagMeta = const VerificationMeta('tag');
  @override
  late final GeneratedColumn<String> tag = GeneratedColumn<String>(
    'tag',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    refNo,
    direction,
    amount,
    account,
    counterparty,
    sender,
    receivedAt,
    status,
    entryId,
    rawText,
    tag,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bank_sms';
  @override
  VerificationContext validateIntegrity(
    Insertable<BankMessage> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('ref_no')) {
      context.handle(
        _refNoMeta,
        refNo.isAcceptableOrUnknown(data['ref_no']!, _refNoMeta),
      );
    } else if (isInserting) {
      context.missing(_refNoMeta);
    }
    if (data.containsKey('direction')) {
      context.handle(
        _directionMeta,
        direction.isAcceptableOrUnknown(data['direction']!, _directionMeta),
      );
    } else if (isInserting) {
      context.missing(_directionMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('account')) {
      context.handle(
        _accountMeta,
        account.isAcceptableOrUnknown(data['account']!, _accountMeta),
      );
    }
    if (data.containsKey('counterparty')) {
      context.handle(
        _counterpartyMeta,
        counterparty.isAcceptableOrUnknown(
          data['counterparty']!,
          _counterpartyMeta,
        ),
      );
    }
    if (data.containsKey('sender')) {
      context.handle(
        _senderMeta,
        sender.isAcceptableOrUnknown(data['sender']!, _senderMeta),
      );
    } else if (isInserting) {
      context.missing(_senderMeta);
    }
    if (data.containsKey('received_at')) {
      context.handle(
        _receivedAtMeta,
        receivedAt.isAcceptableOrUnknown(data['received_at']!, _receivedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_receivedAtMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('entry_id')) {
      context.handle(
        _entryIdMeta,
        entryId.isAcceptableOrUnknown(data['entry_id']!, _entryIdMeta),
      );
    }
    if (data.containsKey('raw_text')) {
      context.handle(
        _rawTextMeta,
        rawText.isAcceptableOrUnknown(data['raw_text']!, _rawTextMeta),
      );
    } else if (isInserting) {
      context.missing(_rawTextMeta);
    }
    if (data.containsKey('tag')) {
      context.handle(
        _tagMeta,
        tag.isAcceptableOrUnknown(data['tag']!, _tagMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BankMessage map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BankMessage(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      refNo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ref_no'],
      )!,
      direction: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}direction'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount'],
      )!,
      account: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account'],
      ),
      counterparty: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}counterparty'],
      ),
      sender: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sender'],
      )!,
      receivedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}received_at'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      entryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}entry_id'],
      ),
      rawText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_text'],
      )!,
      tag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tag'],
      ),
    );
  }

  @override
  $BankSmsTable createAlias(String alias) {
    return $BankSmsTable(attachedDatabase, alias);
  }
}

class BankMessage extends DataClass implements Insertable<BankMessage> {
  final int id;
  final String refNo;
  final String direction;
  final int amount;
  final String? account;
  final String? counterparty;
  final String sender;
  final DateTime receivedAt;
  final String status;
  final int? entryId;
  final String rawText;
  final String? tag;
  const BankMessage({
    required this.id,
    required this.refNo,
    required this.direction,
    required this.amount,
    this.account,
    this.counterparty,
    required this.sender,
    required this.receivedAt,
    required this.status,
    this.entryId,
    required this.rawText,
    this.tag,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['ref_no'] = Variable<String>(refNo);
    map['direction'] = Variable<String>(direction);
    map['amount'] = Variable<int>(amount);
    if (!nullToAbsent || account != null) {
      map['account'] = Variable<String>(account);
    }
    if (!nullToAbsent || counterparty != null) {
      map['counterparty'] = Variable<String>(counterparty);
    }
    map['sender'] = Variable<String>(sender);
    map['received_at'] = Variable<DateTime>(receivedAt);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || entryId != null) {
      map['entry_id'] = Variable<int>(entryId);
    }
    map['raw_text'] = Variable<String>(rawText);
    if (!nullToAbsent || tag != null) {
      map['tag'] = Variable<String>(tag);
    }
    return map;
  }

  BankSmsCompanion toCompanion(bool nullToAbsent) {
    return BankSmsCompanion(
      id: Value(id),
      refNo: Value(refNo),
      direction: Value(direction),
      amount: Value(amount),
      account: account == null && nullToAbsent
          ? const Value.absent()
          : Value(account),
      counterparty: counterparty == null && nullToAbsent
          ? const Value.absent()
          : Value(counterparty),
      sender: Value(sender),
      receivedAt: Value(receivedAt),
      status: Value(status),
      entryId: entryId == null && nullToAbsent
          ? const Value.absent()
          : Value(entryId),
      rawText: Value(rawText),
      tag: tag == null && nullToAbsent ? const Value.absent() : Value(tag),
    );
  }

  factory BankMessage.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BankMessage(
      id: serializer.fromJson<int>(json['id']),
      refNo: serializer.fromJson<String>(json['refNo']),
      direction: serializer.fromJson<String>(json['direction']),
      amount: serializer.fromJson<int>(json['amount']),
      account: serializer.fromJson<String?>(json['account']),
      counterparty: serializer.fromJson<String?>(json['counterparty']),
      sender: serializer.fromJson<String>(json['sender']),
      receivedAt: serializer.fromJson<DateTime>(json['receivedAt']),
      status: serializer.fromJson<String>(json['status']),
      entryId: serializer.fromJson<int?>(json['entryId']),
      rawText: serializer.fromJson<String>(json['rawText']),
      tag: serializer.fromJson<String?>(json['tag']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'refNo': serializer.toJson<String>(refNo),
      'direction': serializer.toJson<String>(direction),
      'amount': serializer.toJson<int>(amount),
      'account': serializer.toJson<String?>(account),
      'counterparty': serializer.toJson<String?>(counterparty),
      'sender': serializer.toJson<String>(sender),
      'receivedAt': serializer.toJson<DateTime>(receivedAt),
      'status': serializer.toJson<String>(status),
      'entryId': serializer.toJson<int?>(entryId),
      'rawText': serializer.toJson<String>(rawText),
      'tag': serializer.toJson<String?>(tag),
    };
  }

  BankMessage copyWith({
    int? id,
    String? refNo,
    String? direction,
    int? amount,
    Value<String?> account = const Value.absent(),
    Value<String?> counterparty = const Value.absent(),
    String? sender,
    DateTime? receivedAt,
    String? status,
    Value<int?> entryId = const Value.absent(),
    String? rawText,
    Value<String?> tag = const Value.absent(),
  }) => BankMessage(
    id: id ?? this.id,
    refNo: refNo ?? this.refNo,
    direction: direction ?? this.direction,
    amount: amount ?? this.amount,
    account: account.present ? account.value : this.account,
    counterparty: counterparty.present ? counterparty.value : this.counterparty,
    sender: sender ?? this.sender,
    receivedAt: receivedAt ?? this.receivedAt,
    status: status ?? this.status,
    entryId: entryId.present ? entryId.value : this.entryId,
    rawText: rawText ?? this.rawText,
    tag: tag.present ? tag.value : this.tag,
  );
  BankMessage copyWithCompanion(BankSmsCompanion data) {
    return BankMessage(
      id: data.id.present ? data.id.value : this.id,
      refNo: data.refNo.present ? data.refNo.value : this.refNo,
      direction: data.direction.present ? data.direction.value : this.direction,
      amount: data.amount.present ? data.amount.value : this.amount,
      account: data.account.present ? data.account.value : this.account,
      counterparty: data.counterparty.present
          ? data.counterparty.value
          : this.counterparty,
      sender: data.sender.present ? data.sender.value : this.sender,
      receivedAt: data.receivedAt.present
          ? data.receivedAt.value
          : this.receivedAt,
      status: data.status.present ? data.status.value : this.status,
      entryId: data.entryId.present ? data.entryId.value : this.entryId,
      rawText: data.rawText.present ? data.rawText.value : this.rawText,
      tag: data.tag.present ? data.tag.value : this.tag,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BankMessage(')
          ..write('id: $id, ')
          ..write('refNo: $refNo, ')
          ..write('direction: $direction, ')
          ..write('amount: $amount, ')
          ..write('account: $account, ')
          ..write('counterparty: $counterparty, ')
          ..write('sender: $sender, ')
          ..write('receivedAt: $receivedAt, ')
          ..write('status: $status, ')
          ..write('entryId: $entryId, ')
          ..write('rawText: $rawText, ')
          ..write('tag: $tag')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    refNo,
    direction,
    amount,
    account,
    counterparty,
    sender,
    receivedAt,
    status,
    entryId,
    rawText,
    tag,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BankMessage &&
          other.id == this.id &&
          other.refNo == this.refNo &&
          other.direction == this.direction &&
          other.amount == this.amount &&
          other.account == this.account &&
          other.counterparty == this.counterparty &&
          other.sender == this.sender &&
          other.receivedAt == this.receivedAt &&
          other.status == this.status &&
          other.entryId == this.entryId &&
          other.rawText == this.rawText &&
          other.tag == this.tag);
}

class BankSmsCompanion extends UpdateCompanion<BankMessage> {
  final Value<int> id;
  final Value<String> refNo;
  final Value<String> direction;
  final Value<int> amount;
  final Value<String?> account;
  final Value<String?> counterparty;
  final Value<String> sender;
  final Value<DateTime> receivedAt;
  final Value<String> status;
  final Value<int?> entryId;
  final Value<String> rawText;
  final Value<String?> tag;
  const BankSmsCompanion({
    this.id = const Value.absent(),
    this.refNo = const Value.absent(),
    this.direction = const Value.absent(),
    this.amount = const Value.absent(),
    this.account = const Value.absent(),
    this.counterparty = const Value.absent(),
    this.sender = const Value.absent(),
    this.receivedAt = const Value.absent(),
    this.status = const Value.absent(),
    this.entryId = const Value.absent(),
    this.rawText = const Value.absent(),
    this.tag = const Value.absent(),
  });
  BankSmsCompanion.insert({
    this.id = const Value.absent(),
    required String refNo,
    required String direction,
    required int amount,
    this.account = const Value.absent(),
    this.counterparty = const Value.absent(),
    required String sender,
    required DateTime receivedAt,
    this.status = const Value.absent(),
    this.entryId = const Value.absent(),
    required String rawText,
    this.tag = const Value.absent(),
  }) : refNo = Value(refNo),
       direction = Value(direction),
       amount = Value(amount),
       sender = Value(sender),
       receivedAt = Value(receivedAt),
       rawText = Value(rawText);
  static Insertable<BankMessage> custom({
    Expression<int>? id,
    Expression<String>? refNo,
    Expression<String>? direction,
    Expression<int>? amount,
    Expression<String>? account,
    Expression<String>? counterparty,
    Expression<String>? sender,
    Expression<DateTime>? receivedAt,
    Expression<String>? status,
    Expression<int>? entryId,
    Expression<String>? rawText,
    Expression<String>? tag,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (refNo != null) 'ref_no': refNo,
      if (direction != null) 'direction': direction,
      if (amount != null) 'amount': amount,
      if (account != null) 'account': account,
      if (counterparty != null) 'counterparty': counterparty,
      if (sender != null) 'sender': sender,
      if (receivedAt != null) 'received_at': receivedAt,
      if (status != null) 'status': status,
      if (entryId != null) 'entry_id': entryId,
      if (rawText != null) 'raw_text': rawText,
      if (tag != null) 'tag': tag,
    });
  }

  BankSmsCompanion copyWith({
    Value<int>? id,
    Value<String>? refNo,
    Value<String>? direction,
    Value<int>? amount,
    Value<String?>? account,
    Value<String?>? counterparty,
    Value<String>? sender,
    Value<DateTime>? receivedAt,
    Value<String>? status,
    Value<int?>? entryId,
    Value<String>? rawText,
    Value<String?>? tag,
  }) {
    return BankSmsCompanion(
      id: id ?? this.id,
      refNo: refNo ?? this.refNo,
      direction: direction ?? this.direction,
      amount: amount ?? this.amount,
      account: account ?? this.account,
      counterparty: counterparty ?? this.counterparty,
      sender: sender ?? this.sender,
      receivedAt: receivedAt ?? this.receivedAt,
      status: status ?? this.status,
      entryId: entryId ?? this.entryId,
      rawText: rawText ?? this.rawText,
      tag: tag ?? this.tag,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (refNo.present) {
      map['ref_no'] = Variable<String>(refNo.value);
    }
    if (direction.present) {
      map['direction'] = Variable<String>(direction.value);
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (account.present) {
      map['account'] = Variable<String>(account.value);
    }
    if (counterparty.present) {
      map['counterparty'] = Variable<String>(counterparty.value);
    }
    if (sender.present) {
      map['sender'] = Variable<String>(sender.value);
    }
    if (receivedAt.present) {
      map['received_at'] = Variable<DateTime>(receivedAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (entryId.present) {
      map['entry_id'] = Variable<int>(entryId.value);
    }
    if (rawText.present) {
      map['raw_text'] = Variable<String>(rawText.value);
    }
    if (tag.present) {
      map['tag'] = Variable<String>(tag.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BankSmsCompanion(')
          ..write('id: $id, ')
          ..write('refNo: $refNo, ')
          ..write('direction: $direction, ')
          ..write('amount: $amount, ')
          ..write('account: $account, ')
          ..write('counterparty: $counterparty, ')
          ..write('sender: $sender, ')
          ..write('receivedAt: $receivedAt, ')
          ..write('status: $status, ')
          ..write('entryId: $entryId, ')
          ..write('rawText: $rawText, ')
          ..write('tag: $tag')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDb extends GeneratedDatabase {
  _$AppDb(QueryExecutor e) : super(e);
  $AppDbManager get managers => $AppDbManager(this);
  late final $EntriesTable entries = $EntriesTable(this);
  late final $CyclesTable cycles = $CyclesTable(this);
  late final $BankSmsTable bankSms = $BankSmsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    entries,
    cycles,
    bankSms,
  ];
}

typedef $$EntriesTableCreateCompanionBuilder = EntriesCompanion Function({
  Value<int> id,
  required String kind,
  required int amount,
  Value<String?> incomeKind,
  Value<String?> source,
  Value<String?> title,
  required DateTime date,
  Value<DateTime?> endDate,
  Value<String?> category,
  Value<bool> unexpected,
  Value<String?> reason,
  Value<bool> yearly,
  Value<int?> helpedEntryId,
  Value<DateTime?> repaidAt,
  Value<String?> note,
  Value<DateTime> createdAt,
  Value<String?> tag,
});
typedef $$EntriesTableUpdateCompanionBuilder = EntriesCompanion Function({
  Value<int> id,
  Value<String> kind,
  Value<int> amount,
  Value<String?> incomeKind,
  Value<String?> source,
  Value<String?> title,
  Value<DateTime> date,
  Value<DateTime?> endDate,
  Value<String?> category,
  Value<bool> unexpected,
  Value<String?> reason,
  Value<bool> yearly,
  Value<int?> helpedEntryId,
  Value<DateTime?> repaidAt,
  Value<String?> note,
  Value<DateTime> createdAt,
  Value<String?> tag,
});

class $$EntriesTableFilterComposer extends Composer<_$AppDb, $EntriesTable> {
  $$EntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get incomeKind => $composableBuilder(
    column: $table.incomeKind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get unexpected => $composableBuilder(
    column: $table.unexpected,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get yearly => $composableBuilder(
    column: $table.yearly,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get helpedEntryId => $composableBuilder(
    column: $table.helpedEntryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get repaidAt => $composableBuilder(
    column: $table.repaidAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tag => $composableBuilder(
    column: $table.tag,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EntriesTableOrderingComposer extends Composer<_$AppDb, $EntriesTable> {
  $$EntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get incomeKind => $composableBuilder(
    column: $table.incomeKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get unexpected => $composableBuilder(
    column: $table.unexpected,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get yearly => $composableBuilder(
    column: $table.yearly,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get helpedEntryId => $composableBuilder(
    column: $table.helpedEntryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get repaidAt => $composableBuilder(
    column: $table.repaidAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tag => $composableBuilder(
    column: $table.tag,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EntriesTableAnnotationComposer
    extends Composer<_$AppDb, $EntriesTable> {
  $$EntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get incomeKind => $composableBuilder(
    column: $table.incomeKind,
    builder: (column) => column,
  );

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<DateTime> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<bool> get unexpected => $composableBuilder(
    column: $table.unexpected,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<bool> get yearly =>
      $composableBuilder(column: $table.yearly, builder: (column) => column);

  GeneratedColumn<int> get helpedEntryId => $composableBuilder(
    column: $table.helpedEntryId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get repaidAt =>
      $composableBuilder(column: $table.repaidAt, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get tag =>
      $composableBuilder(column: $table.tag, builder: (column) => column);
}

class $$EntriesTableTableManager
    extends
        RootTableManager<
          _$AppDb,
          $EntriesTable,
          Entry,
          $$EntriesTableFilterComposer,
          $$EntriesTableOrderingComposer,
          $$EntriesTableAnnotationComposer,
          $$EntriesTableCreateCompanionBuilder,
          $$EntriesTableUpdateCompanionBuilder,
          (Entry, BaseReferences<_$AppDb, $EntriesTable, Entry>),
          Entry,
          PrefetchHooks Function()
        > {
  $$EntriesTableTableManager(_$AppDb db, $EntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<int> amount = const Value.absent(),
                Value<String?> incomeKind = const Value.absent(),
                Value<String?> source = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<DateTime?> endDate = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<bool> unexpected = const Value.absent(),
                Value<String?> reason = const Value.absent(),
                Value<bool> yearly = const Value.absent(),
                Value<int?> helpedEntryId = const Value.absent(),
                Value<DateTime?> repaidAt = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String?> tag = const Value.absent(),
              }) => EntriesCompanion(
                id: id,
                kind: kind,
                amount: amount,
                incomeKind: incomeKind,
                source: source,
                title: title,
                date: date,
                endDate: endDate,
                category: category,
                unexpected: unexpected,
                reason: reason,
                yearly: yearly,
                helpedEntryId: helpedEntryId,
                repaidAt: repaidAt,
                note: note,
                createdAt: createdAt,
                tag: tag,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String kind,
                required int amount,
                Value<String?> incomeKind = const Value.absent(),
                Value<String?> source = const Value.absent(),
                Value<String?> title = const Value.absent(),
                required DateTime date,
                Value<DateTime?> endDate = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<bool> unexpected = const Value.absent(),
                Value<String?> reason = const Value.absent(),
                Value<bool> yearly = const Value.absent(),
                Value<int?> helpedEntryId = const Value.absent(),
                Value<DateTime?> repaidAt = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String?> tag = const Value.absent(),
              }) => EntriesCompanion.insert(
                id: id,
                kind: kind,
                amount: amount,
                incomeKind: incomeKind,
                source: source,
                title: title,
                date: date,
                endDate: endDate,
                category: category,
                unexpected: unexpected,
                reason: reason,
                yearly: yearly,
                helpedEntryId: helpedEntryId,
                repaidAt: repaidAt,
                note: note,
                createdAt: createdAt,
                tag: tag,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$EntriesTable, Entry>(table),
                  BaseReferences<_$AppDb, $EntriesTable, Entry>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDb,
      $EntriesTable,
      Entry,
      $$EntriesTableFilterComposer,
      $$EntriesTableOrderingComposer,
      $$EntriesTableAnnotationComposer,
      $$EntriesTableCreateCompanionBuilder,
      $$EntriesTableUpdateCompanionBuilder,
      (Entry, BaseReferences<_$AppDb, $EntriesTable, Entry>),
      Entry,
      PrefetchHooks Function()
    >;
typedef $$CyclesTableCreateCompanionBuilder = CyclesCompanion Function({
  Value<int> id,
  required DateTime startDate,
  required DateTime endDate,
  Value<DateTime?> closedAt,
  Value<bool?> supported,
  Value<String?> note,
  Value<String?> summary,
});
typedef $$CyclesTableUpdateCompanionBuilder = CyclesCompanion Function({
  Value<int> id,
  Value<DateTime> startDate,
  Value<DateTime> endDate,
  Value<DateTime?> closedAt,
  Value<bool?> supported,
  Value<String?> note,
  Value<String?> summary,
});

class $$CyclesTableFilterComposer extends Composer<_$AppDb, $CyclesTable> {
  $$CyclesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get closedAt => $composableBuilder(
    column: $table.closedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get supported => $composableBuilder(
    column: $table.supported,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CyclesTableOrderingComposer extends Composer<_$AppDb, $CyclesTable> {
  $$CyclesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get closedAt => $composableBuilder(
    column: $table.closedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get supported => $composableBuilder(
    column: $table.supported,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CyclesTableAnnotationComposer extends Composer<_$AppDb, $CyclesTable> {
  $$CyclesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<DateTime> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  GeneratedColumn<DateTime> get closedAt =>
      $composableBuilder(column: $table.closedAt, builder: (column) => column);

  GeneratedColumn<bool> get supported =>
      $composableBuilder(column: $table.supported, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get summary =>
      $composableBuilder(column: $table.summary, builder: (column) => column);
}

class $$CyclesTableTableManager
    extends
        RootTableManager<
          _$AppDb,
          $CyclesTable,
          Cycle,
          $$CyclesTableFilterComposer,
          $$CyclesTableOrderingComposer,
          $$CyclesTableAnnotationComposer,
          $$CyclesTableCreateCompanionBuilder,
          $$CyclesTableUpdateCompanionBuilder,
          (Cycle, BaseReferences<_$AppDb, $CyclesTable, Cycle>),
          Cycle,
          PrefetchHooks Function()
        > {
  $$CyclesTableTableManager(_$AppDb db, $CyclesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CyclesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CyclesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CyclesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> startDate = const Value.absent(),
                Value<DateTime> endDate = const Value.absent(),
                Value<DateTime?> closedAt = const Value.absent(),
                Value<bool?> supported = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String?> summary = const Value.absent(),
              }) => CyclesCompanion(
                id: id,
                startDate: startDate,
                endDate: endDate,
                closedAt: closedAt,
                supported: supported,
                note: note,
                summary: summary,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime startDate,
                required DateTime endDate,
                Value<DateTime?> closedAt = const Value.absent(),
                Value<bool?> supported = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String?> summary = const Value.absent(),
              }) => CyclesCompanion.insert(
                id: id,
                startDate: startDate,
                endDate: endDate,
                closedAt: closedAt,
                supported: supported,
                note: note,
                summary: summary,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CyclesTable, Cycle>(table),
                  BaseReferences<_$AppDb, $CyclesTable, Cycle>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CyclesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDb,
      $CyclesTable,
      Cycle,
      $$CyclesTableFilterComposer,
      $$CyclesTableOrderingComposer,
      $$CyclesTableAnnotationComposer,
      $$CyclesTableCreateCompanionBuilder,
      $$CyclesTableUpdateCompanionBuilder,
      (Cycle, BaseReferences<_$AppDb, $CyclesTable, Cycle>),
      Cycle,
      PrefetchHooks Function()
    >;
typedef $$BankSmsTableCreateCompanionBuilder = BankSmsCompanion Function({
  Value<int> id,
  required String refNo,
  required String direction,
  required int amount,
  Value<String?> account,
  Value<String?> counterparty,
  required String sender,
  required DateTime receivedAt,
  Value<String> status,
  Value<int?> entryId,
  required String rawText,
  Value<String?> tag,
});
typedef $$BankSmsTableUpdateCompanionBuilder = BankSmsCompanion Function({
  Value<int> id,
  Value<String> refNo,
  Value<String> direction,
  Value<int> amount,
  Value<String?> account,
  Value<String?> counterparty,
  Value<String> sender,
  Value<DateTime> receivedAt,
  Value<String> status,
  Value<int?> entryId,
  Value<String> rawText,
  Value<String?> tag,
});

class $$BankSmsTableFilterComposer extends Composer<_$AppDb, $BankSmsTable> {
  $$BankSmsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get refNo => $composableBuilder(
    column: $table.refNo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get account => $composableBuilder(
    column: $table.account,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get counterparty => $composableBuilder(
    column: $table.counterparty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sender => $composableBuilder(
    column: $table.sender,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get receivedAt => $composableBuilder(
    column: $table.receivedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get entryId => $composableBuilder(
    column: $table.entryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rawText => $composableBuilder(
    column: $table.rawText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tag => $composableBuilder(
    column: $table.tag,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BankSmsTableOrderingComposer extends Composer<_$AppDb, $BankSmsTable> {
  $$BankSmsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get refNo => $composableBuilder(
    column: $table.refNo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get account => $composableBuilder(
    column: $table.account,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get counterparty => $composableBuilder(
    column: $table.counterparty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sender => $composableBuilder(
    column: $table.sender,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get receivedAt => $composableBuilder(
    column: $table.receivedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get entryId => $composableBuilder(
    column: $table.entryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rawText => $composableBuilder(
    column: $table.rawText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tag => $composableBuilder(
    column: $table.tag,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BankSmsTableAnnotationComposer
    extends Composer<_$AppDb, $BankSmsTable> {
  $$BankSmsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get refNo =>
      $composableBuilder(column: $table.refNo, builder: (column) => column);

  GeneratedColumn<String> get direction =>
      $composableBuilder(column: $table.direction, builder: (column) => column);

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get account =>
      $composableBuilder(column: $table.account, builder: (column) => column);

  GeneratedColumn<String> get counterparty => $composableBuilder(
    column: $table.counterparty,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sender =>
      $composableBuilder(column: $table.sender, builder: (column) => column);

  GeneratedColumn<DateTime> get receivedAt => $composableBuilder(
    column: $table.receivedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get entryId =>
      $composableBuilder(column: $table.entryId, builder: (column) => column);

  GeneratedColumn<String> get rawText =>
      $composableBuilder(column: $table.rawText, builder: (column) => column);

  GeneratedColumn<String> get tag =>
      $composableBuilder(column: $table.tag, builder: (column) => column);
}

class $$BankSmsTableTableManager
    extends
        RootTableManager<
          _$AppDb,
          $BankSmsTable,
          BankMessage,
          $$BankSmsTableFilterComposer,
          $$BankSmsTableOrderingComposer,
          $$BankSmsTableAnnotationComposer,
          $$BankSmsTableCreateCompanionBuilder,
          $$BankSmsTableUpdateCompanionBuilder,
          (BankMessage, BaseReferences<_$AppDb, $BankSmsTable, BankMessage>),
          BankMessage,
          PrefetchHooks Function()
        > {
  $$BankSmsTableTableManager(_$AppDb db, $BankSmsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BankSmsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BankSmsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BankSmsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> refNo = const Value.absent(),
                Value<String> direction = const Value.absent(),
                Value<int> amount = const Value.absent(),
                Value<String?> account = const Value.absent(),
                Value<String?> counterparty = const Value.absent(),
                Value<String> sender = const Value.absent(),
                Value<DateTime> receivedAt = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int?> entryId = const Value.absent(),
                Value<String> rawText = const Value.absent(),
                Value<String?> tag = const Value.absent(),
              }) => BankSmsCompanion(
                id: id,
                refNo: refNo,
                direction: direction,
                amount: amount,
                account: account,
                counterparty: counterparty,
                sender: sender,
                receivedAt: receivedAt,
                status: status,
                entryId: entryId,
                rawText: rawText,
                tag: tag,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String refNo,
                required String direction,
                required int amount,
                Value<String?> account = const Value.absent(),
                Value<String?> counterparty = const Value.absent(),
                required String sender,
                required DateTime receivedAt,
                Value<String> status = const Value.absent(),
                Value<int?> entryId = const Value.absent(),
                required String rawText,
                Value<String?> tag = const Value.absent(),
              }) => BankSmsCompanion.insert(
                id: id,
                refNo: refNo,
                direction: direction,
                amount: amount,
                account: account,
                counterparty: counterparty,
                sender: sender,
                receivedAt: receivedAt,
                status: status,
                entryId: entryId,
                rawText: rawText,
                tag: tag,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BankSmsTable, BankMessage>(table),
                  BaseReferences<_$AppDb, $BankSmsTable, BankMessage>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BankSmsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDb,
      $BankSmsTable,
      BankMessage,
      $$BankSmsTableFilterComposer,
      $$BankSmsTableOrderingComposer,
      $$BankSmsTableAnnotationComposer,
      $$BankSmsTableCreateCompanionBuilder,
      $$BankSmsTableUpdateCompanionBuilder,
      (BankMessage, BaseReferences<_$AppDb, $BankSmsTable, BankMessage>),
      BankMessage,
      PrefetchHooks Function()
    >;

class $AppDbManager {
  final _$AppDb _db;
  $AppDbManager(this._db);
  $$EntriesTableTableManager get entries =>
      $$EntriesTableTableManager(_db, _db.entries);
  $$CyclesTableTableManager get cycles =>
      $$CyclesTableTableManager(_db, _db.cycles);
  $$BankSmsTableTableManager get bankSms =>
      $$BankSmsTableTableManager(_db, _db.bankSms);
}
