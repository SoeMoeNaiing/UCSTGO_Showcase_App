// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $PendingFeedbackTable extends PendingFeedback
    with TableInfo<$PendingFeedbackTable, PendingFeedbackData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingFeedbackTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _clientIdMeta = const VerificationMeta(
    'clientId',
  );
  @override
  late final GeneratedColumn<String> clientId = GeneratedColumn<String>(
    'client_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emojiChoiceMeta = const VerificationMeta(
    'emojiChoice',
  );
  @override
  late final GeneratedColumn<String> emojiChoice = GeneratedColumn<String>(
    'emoji_choice',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastAttemptAtMeta = const VerificationMeta(
    'lastAttemptAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastAttemptAt =
      GeneratedColumn<DateTime>(
        'last_attempt_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _nextRetryAtMeta = const VerificationMeta(
    'nextRetryAt',
  );
  @override
  late final GeneratedColumn<DateTime> nextRetryAt = GeneratedColumn<DateTime>(
    'next_retry_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    clientId,
    deviceId,
    emojiChoice,
    createdAt,
    syncStatus,
    attempts,
    lastAttemptAt,
    nextRetryAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_feedback';
  @override
  VerificationContext validateIntegrity(
    Insertable<PendingFeedbackData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('client_id')) {
      context.handle(
        _clientIdMeta,
        clientId.isAcceptableOrUnknown(data['client_id']!, _clientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_clientIdMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('emoji_choice')) {
      context.handle(
        _emojiChoiceMeta,
        emojiChoice.isAcceptableOrUnknown(
          data['emoji_choice']!,
          _emojiChoiceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_emojiChoiceMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('last_attempt_at')) {
      context.handle(
        _lastAttemptAtMeta,
        lastAttemptAt.isAcceptableOrUnknown(
          data['last_attempt_at']!,
          _lastAttemptAtMeta,
        ),
      );
    }
    if (data.containsKey('next_retry_at')) {
      context.handle(
        _nextRetryAtMeta,
        nextRetryAt.isAcceptableOrUnknown(
          data['next_retry_at']!,
          _nextRetryAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {clientId};
  @override
  PendingFeedbackData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingFeedbackData(
      clientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_id'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      emojiChoice: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}emoji_choice'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      lastAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_attempt_at'],
      ),
      nextRetryAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_retry_at'],
      ),
    );
  }

  @override
  $PendingFeedbackTable createAlias(String alias) {
    return $PendingFeedbackTable(attachedDatabase, alias);
  }
}

class PendingFeedbackData extends DataClass
    implements Insertable<PendingFeedbackData> {
  /// Client-generated UUID — the idempotency key (§6.5). Used as the
  /// primary key so a replay can never insert the same submission twice.
  final String clientId;

  /// Anonymous persistent device identifier (no PII, §2.4).
  final String deviceId;

  /// `EmojiChoice.wireValue` — `'satisfied'` / `'neutral'` / `'dissatisfied'`.
  final String emojiChoice;

  /// Submission time in UTC (the entity enforces this, §6.5).
  final DateTime createdAt;

  /// `SyncStatus.wireValue`; `'pending'` until the sync engine decides.
  final String syncStatus;

  /// Number of upload attempts so far (§6.6 backoff, capped at 6).
  final int attempts;

  /// Last upload attempt, UTC — diagnostics only.
  final DateTime? lastAttemptAt;

  /// Backoff deadline: do not retry before this instant (null = eligible).
  final DateTime? nextRetryAt;
  const PendingFeedbackData({
    required this.clientId,
    required this.deviceId,
    required this.emojiChoice,
    required this.createdAt,
    required this.syncStatus,
    required this.attempts,
    this.lastAttemptAt,
    this.nextRetryAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['client_id'] = Variable<String>(clientId);
    map['device_id'] = Variable<String>(deviceId);
    map['emoji_choice'] = Variable<String>(emojiChoice);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['sync_status'] = Variable<String>(syncStatus);
    map['attempts'] = Variable<int>(attempts);
    if (!nullToAbsent || lastAttemptAt != null) {
      map['last_attempt_at'] = Variable<DateTime>(lastAttemptAt);
    }
    if (!nullToAbsent || nextRetryAt != null) {
      map['next_retry_at'] = Variable<DateTime>(nextRetryAt);
    }
    return map;
  }

  PendingFeedbackCompanion toCompanion(bool nullToAbsent) {
    return PendingFeedbackCompanion(
      clientId: Value(clientId),
      deviceId: Value(deviceId),
      emojiChoice: Value(emojiChoice),
      createdAt: Value(createdAt),
      syncStatus: Value(syncStatus),
      attempts: Value(attempts),
      lastAttemptAt: lastAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAttemptAt),
      nextRetryAt: nextRetryAt == null && nullToAbsent
          ? const Value.absent()
          : Value(nextRetryAt),
    );
  }

  factory PendingFeedbackData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingFeedbackData(
      clientId: serializer.fromJson<String>(json['clientId']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      emojiChoice: serializer.fromJson<String>(json['emojiChoice']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      attempts: serializer.fromJson<int>(json['attempts']),
      lastAttemptAt: serializer.fromJson<DateTime?>(json['lastAttemptAt']),
      nextRetryAt: serializer.fromJson<DateTime?>(json['nextRetryAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'clientId': serializer.toJson<String>(clientId),
      'deviceId': serializer.toJson<String>(deviceId),
      'emojiChoice': serializer.toJson<String>(emojiChoice),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'attempts': serializer.toJson<int>(attempts),
      'lastAttemptAt': serializer.toJson<DateTime?>(lastAttemptAt),
      'nextRetryAt': serializer.toJson<DateTime?>(nextRetryAt),
    };
  }

  PendingFeedbackData copyWith({
    String? clientId,
    String? deviceId,
    String? emojiChoice,
    DateTime? createdAt,
    String? syncStatus,
    int? attempts,
    Value<DateTime?> lastAttemptAt = const Value.absent(),
    Value<DateTime?> nextRetryAt = const Value.absent(),
  }) => PendingFeedbackData(
    clientId: clientId ?? this.clientId,
    deviceId: deviceId ?? this.deviceId,
    emojiChoice: emojiChoice ?? this.emojiChoice,
    createdAt: createdAt ?? this.createdAt,
    syncStatus: syncStatus ?? this.syncStatus,
    attempts: attempts ?? this.attempts,
    lastAttemptAt: lastAttemptAt.present
        ? lastAttemptAt.value
        : this.lastAttemptAt,
    nextRetryAt: nextRetryAt.present ? nextRetryAt.value : this.nextRetryAt,
  );
  PendingFeedbackData copyWithCompanion(PendingFeedbackCompanion data) {
    return PendingFeedbackData(
      clientId: data.clientId.present ? data.clientId.value : this.clientId,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      emojiChoice: data.emojiChoice.present
          ? data.emojiChoice.value
          : this.emojiChoice,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      lastAttemptAt: data.lastAttemptAt.present
          ? data.lastAttemptAt.value
          : this.lastAttemptAt,
      nextRetryAt: data.nextRetryAt.present
          ? data.nextRetryAt.value
          : this.nextRetryAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingFeedbackData(')
          ..write('clientId: $clientId, ')
          ..write('deviceId: $deviceId, ')
          ..write('emojiChoice: $emojiChoice, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('attempts: $attempts, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('nextRetryAt: $nextRetryAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    clientId,
    deviceId,
    emojiChoice,
    createdAt,
    syncStatus,
    attempts,
    lastAttemptAt,
    nextRetryAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingFeedbackData &&
          other.clientId == this.clientId &&
          other.deviceId == this.deviceId &&
          other.emojiChoice == this.emojiChoice &&
          other.createdAt == this.createdAt &&
          other.syncStatus == this.syncStatus &&
          other.attempts == this.attempts &&
          other.lastAttemptAt == this.lastAttemptAt &&
          other.nextRetryAt == this.nextRetryAt);
}

class PendingFeedbackCompanion extends UpdateCompanion<PendingFeedbackData> {
  final Value<String> clientId;
  final Value<String> deviceId;
  final Value<String> emojiChoice;
  final Value<DateTime> createdAt;
  final Value<String> syncStatus;
  final Value<int> attempts;
  final Value<DateTime?> lastAttemptAt;
  final Value<DateTime?> nextRetryAt;
  final Value<int> rowid;
  const PendingFeedbackCompanion({
    this.clientId = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.emojiChoice = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.attempts = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
    this.nextRetryAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PendingFeedbackCompanion.insert({
    required String clientId,
    required String deviceId,
    required String emojiChoice,
    required DateTime createdAt,
    this.syncStatus = const Value.absent(),
    this.attempts = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
    this.nextRetryAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : clientId = Value(clientId),
       deviceId = Value(deviceId),
       emojiChoice = Value(emojiChoice),
       createdAt = Value(createdAt);
  static Insertable<PendingFeedbackData> custom({
    Expression<String>? clientId,
    Expression<String>? deviceId,
    Expression<String>? emojiChoice,
    Expression<DateTime>? createdAt,
    Expression<String>? syncStatus,
    Expression<int>? attempts,
    Expression<DateTime>? lastAttemptAt,
    Expression<DateTime>? nextRetryAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (clientId != null) 'client_id': clientId,
      if (deviceId != null) 'device_id': deviceId,
      if (emojiChoice != null) 'emoji_choice': emojiChoice,
      if (createdAt != null) 'created_at': createdAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (attempts != null) 'attempts': attempts,
      if (lastAttemptAt != null) 'last_attempt_at': lastAttemptAt,
      if (nextRetryAt != null) 'next_retry_at': nextRetryAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PendingFeedbackCompanion copyWith({
    Value<String>? clientId,
    Value<String>? deviceId,
    Value<String>? emojiChoice,
    Value<DateTime>? createdAt,
    Value<String>? syncStatus,
    Value<int>? attempts,
    Value<DateTime?>? lastAttemptAt,
    Value<DateTime?>? nextRetryAt,
    Value<int>? rowid,
  }) {
    return PendingFeedbackCompanion(
      clientId: clientId ?? this.clientId,
      deviceId: deviceId ?? this.deviceId,
      emojiChoice: emojiChoice ?? this.emojiChoice,
      createdAt: createdAt ?? this.createdAt,
      syncStatus: syncStatus ?? this.syncStatus,
      attempts: attempts ?? this.attempts,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      nextRetryAt: nextRetryAt ?? this.nextRetryAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (clientId.present) {
      map['client_id'] = Variable<String>(clientId.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (emojiChoice.present) {
      map['emoji_choice'] = Variable<String>(emojiChoice.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (lastAttemptAt.present) {
      map['last_attempt_at'] = Variable<DateTime>(lastAttemptAt.value);
    }
    if (nextRetryAt.present) {
      map['next_retry_at'] = Variable<DateTime>(nextRetryAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingFeedbackCompanion(')
          ..write('clientId: $clientId, ')
          ..write('deviceId: $deviceId, ')
          ..write('emojiChoice: $emojiChoice, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('attempts: $attempts, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('nextRetryAt: $nextRetryAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PendingRatingsTable extends PendingRatings
    with TableInfo<$PendingRatingsTable, PendingRating> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingRatingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _clientIdMeta = const VerificationMeta(
    'clientId',
  );
  @override
  late final GeneratedColumn<String> clientId = GeneratedColumn<String>(
    'client_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _projectIdMeta = const VerificationMeta(
    'projectId',
  );
  @override
  late final GeneratedColumn<String> projectId = GeneratedColumn<String>(
    'project_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scoreMeta = const VerificationMeta('score');
  @override
  late final GeneratedColumn<int> score = GeneratedColumn<int>(
    'score',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
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
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastAttemptAtMeta = const VerificationMeta(
    'lastAttemptAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastAttemptAt =
      GeneratedColumn<DateTime>(
        'last_attempt_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _nextRetryAtMeta = const VerificationMeta(
    'nextRetryAt',
  );
  @override
  late final GeneratedColumn<DateTime> nextRetryAt = GeneratedColumn<DateTime>(
    'next_retry_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    clientId,
    deviceId,
    projectId,
    score,
    createdAt,
    syncStatus,
    attempts,
    lastAttemptAt,
    nextRetryAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_ratings';
  @override
  VerificationContext validateIntegrity(
    Insertable<PendingRating> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('client_id')) {
      context.handle(
        _clientIdMeta,
        clientId.isAcceptableOrUnknown(data['client_id']!, _clientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_clientIdMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('project_id')) {
      context.handle(
        _projectIdMeta,
        projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta),
      );
    } else if (isInserting) {
      context.missing(_projectIdMeta);
    }
    if (data.containsKey('score')) {
      context.handle(
        _scoreMeta,
        score.isAcceptableOrUnknown(data['score']!, _scoreMeta),
      );
    } else if (isInserting) {
      context.missing(_scoreMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('last_attempt_at')) {
      context.handle(
        _lastAttemptAtMeta,
        lastAttemptAt.isAcceptableOrUnknown(
          data['last_attempt_at']!,
          _lastAttemptAtMeta,
        ),
      );
    }
    if (data.containsKey('next_retry_at')) {
      context.handle(
        _nextRetryAtMeta,
        nextRetryAt.isAcceptableOrUnknown(
          data['next_retry_at']!,
          _nextRetryAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {clientId};
  @override
  PendingRating map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingRating(
      clientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_id'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      projectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project_id'],
      )!,
      score: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}score'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      lastAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_attempt_at'],
      ),
      nextRetryAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_retry_at'],
      ),
    );
  }

  @override
  $PendingRatingsTable createAlias(String alias) {
    return $PendingRatingsTable(attachedDatabase, alias);
  }
}

class PendingRating extends DataClass implements Insertable<PendingRating> {
  /// Client-generated UUID — the idempotency key (§6.5).
  final String clientId;

  /// Anonymous persistent device identifier (no PII, §2.4).
  final String deviceId;

  /// Showcase project identifier (matches the fixture list).
  final String projectId;

  /// Star score, 1–5 inclusive (§6.1).
  final int score;

  /// Rating time in UTC.
  final DateTime createdAt;

  /// `SyncStatus.wireValue`; `'pending'` until the sync engine decides.
  final String syncStatus;

  /// Number of upload attempts so far (§6.6 backoff, capped at 6).
  final int attempts;

  /// Last upload attempt, UTC — diagnostics only.
  final DateTime? lastAttemptAt;

  /// Backoff deadline: do not retry before this instant (null = eligible).
  final DateTime? nextRetryAt;
  const PendingRating({
    required this.clientId,
    required this.deviceId,
    required this.projectId,
    required this.score,
    required this.createdAt,
    required this.syncStatus,
    required this.attempts,
    this.lastAttemptAt,
    this.nextRetryAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['client_id'] = Variable<String>(clientId);
    map['device_id'] = Variable<String>(deviceId);
    map['project_id'] = Variable<String>(projectId);
    map['score'] = Variable<int>(score);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['sync_status'] = Variable<String>(syncStatus);
    map['attempts'] = Variable<int>(attempts);
    if (!nullToAbsent || lastAttemptAt != null) {
      map['last_attempt_at'] = Variable<DateTime>(lastAttemptAt);
    }
    if (!nullToAbsent || nextRetryAt != null) {
      map['next_retry_at'] = Variable<DateTime>(nextRetryAt);
    }
    return map;
  }

  PendingRatingsCompanion toCompanion(bool nullToAbsent) {
    return PendingRatingsCompanion(
      clientId: Value(clientId),
      deviceId: Value(deviceId),
      projectId: Value(projectId),
      score: Value(score),
      createdAt: Value(createdAt),
      syncStatus: Value(syncStatus),
      attempts: Value(attempts),
      lastAttemptAt: lastAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAttemptAt),
      nextRetryAt: nextRetryAt == null && nullToAbsent
          ? const Value.absent()
          : Value(nextRetryAt),
    );
  }

  factory PendingRating.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingRating(
      clientId: serializer.fromJson<String>(json['clientId']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      projectId: serializer.fromJson<String>(json['projectId']),
      score: serializer.fromJson<int>(json['score']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      attempts: serializer.fromJson<int>(json['attempts']),
      lastAttemptAt: serializer.fromJson<DateTime?>(json['lastAttemptAt']),
      nextRetryAt: serializer.fromJson<DateTime?>(json['nextRetryAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'clientId': serializer.toJson<String>(clientId),
      'deviceId': serializer.toJson<String>(deviceId),
      'projectId': serializer.toJson<String>(projectId),
      'score': serializer.toJson<int>(score),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'attempts': serializer.toJson<int>(attempts),
      'lastAttemptAt': serializer.toJson<DateTime?>(lastAttemptAt),
      'nextRetryAt': serializer.toJson<DateTime?>(nextRetryAt),
    };
  }

  PendingRating copyWith({
    String? clientId,
    String? deviceId,
    String? projectId,
    int? score,
    DateTime? createdAt,
    String? syncStatus,
    int? attempts,
    Value<DateTime?> lastAttemptAt = const Value.absent(),
    Value<DateTime?> nextRetryAt = const Value.absent(),
  }) => PendingRating(
    clientId: clientId ?? this.clientId,
    deviceId: deviceId ?? this.deviceId,
    projectId: projectId ?? this.projectId,
    score: score ?? this.score,
    createdAt: createdAt ?? this.createdAt,
    syncStatus: syncStatus ?? this.syncStatus,
    attempts: attempts ?? this.attempts,
    lastAttemptAt: lastAttemptAt.present
        ? lastAttemptAt.value
        : this.lastAttemptAt,
    nextRetryAt: nextRetryAt.present ? nextRetryAt.value : this.nextRetryAt,
  );
  PendingRating copyWithCompanion(PendingRatingsCompanion data) {
    return PendingRating(
      clientId: data.clientId.present ? data.clientId.value : this.clientId,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      score: data.score.present ? data.score.value : this.score,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      lastAttemptAt: data.lastAttemptAt.present
          ? data.lastAttemptAt.value
          : this.lastAttemptAt,
      nextRetryAt: data.nextRetryAt.present
          ? data.nextRetryAt.value
          : this.nextRetryAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingRating(')
          ..write('clientId: $clientId, ')
          ..write('deviceId: $deviceId, ')
          ..write('projectId: $projectId, ')
          ..write('score: $score, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('attempts: $attempts, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('nextRetryAt: $nextRetryAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    clientId,
    deviceId,
    projectId,
    score,
    createdAt,
    syncStatus,
    attempts,
    lastAttemptAt,
    nextRetryAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingRating &&
          other.clientId == this.clientId &&
          other.deviceId == this.deviceId &&
          other.projectId == this.projectId &&
          other.score == this.score &&
          other.createdAt == this.createdAt &&
          other.syncStatus == this.syncStatus &&
          other.attempts == this.attempts &&
          other.lastAttemptAt == this.lastAttemptAt &&
          other.nextRetryAt == this.nextRetryAt);
}

class PendingRatingsCompanion extends UpdateCompanion<PendingRating> {
  final Value<String> clientId;
  final Value<String> deviceId;
  final Value<String> projectId;
  final Value<int> score;
  final Value<DateTime> createdAt;
  final Value<String> syncStatus;
  final Value<int> attempts;
  final Value<DateTime?> lastAttemptAt;
  final Value<DateTime?> nextRetryAt;
  final Value<int> rowid;
  const PendingRatingsCompanion({
    this.clientId = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.projectId = const Value.absent(),
    this.score = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.attempts = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
    this.nextRetryAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PendingRatingsCompanion.insert({
    required String clientId,
    required String deviceId,
    required String projectId,
    required int score,
    required DateTime createdAt,
    this.syncStatus = const Value.absent(),
    this.attempts = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
    this.nextRetryAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : clientId = Value(clientId),
       deviceId = Value(deviceId),
       projectId = Value(projectId),
       score = Value(score),
       createdAt = Value(createdAt);
  static Insertable<PendingRating> custom({
    Expression<String>? clientId,
    Expression<String>? deviceId,
    Expression<String>? projectId,
    Expression<int>? score,
    Expression<DateTime>? createdAt,
    Expression<String>? syncStatus,
    Expression<int>? attempts,
    Expression<DateTime>? lastAttemptAt,
    Expression<DateTime>? nextRetryAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (clientId != null) 'client_id': clientId,
      if (deviceId != null) 'device_id': deviceId,
      if (projectId != null) 'project_id': projectId,
      if (score != null) 'score': score,
      if (createdAt != null) 'created_at': createdAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (attempts != null) 'attempts': attempts,
      if (lastAttemptAt != null) 'last_attempt_at': lastAttemptAt,
      if (nextRetryAt != null) 'next_retry_at': nextRetryAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PendingRatingsCompanion copyWith({
    Value<String>? clientId,
    Value<String>? deviceId,
    Value<String>? projectId,
    Value<int>? score,
    Value<DateTime>? createdAt,
    Value<String>? syncStatus,
    Value<int>? attempts,
    Value<DateTime?>? lastAttemptAt,
    Value<DateTime?>? nextRetryAt,
    Value<int>? rowid,
  }) {
    return PendingRatingsCompanion(
      clientId: clientId ?? this.clientId,
      deviceId: deviceId ?? this.deviceId,
      projectId: projectId ?? this.projectId,
      score: score ?? this.score,
      createdAt: createdAt ?? this.createdAt,
      syncStatus: syncStatus ?? this.syncStatus,
      attempts: attempts ?? this.attempts,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      nextRetryAt: nextRetryAt ?? this.nextRetryAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (clientId.present) {
      map['client_id'] = Variable<String>(clientId.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<String>(projectId.value);
    }
    if (score.present) {
      map['score'] = Variable<int>(score.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (lastAttemptAt.present) {
      map['last_attempt_at'] = Variable<DateTime>(lastAttemptAt.value);
    }
    if (nextRetryAt.present) {
      map['next_retry_at'] = Variable<DateTime>(nextRetryAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingRatingsCompanion(')
          ..write('clientId: $clientId, ')
          ..write('deviceId: $deviceId, ')
          ..write('projectId: $projectId, ')
          ..write('score: $score, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('attempts: $attempts, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('nextRetryAt: $nextRetryAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $PendingFeedbackTable pendingFeedback = $PendingFeedbackTable(
    this,
  );
  late final $PendingRatingsTable pendingRatings = $PendingRatingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    pendingFeedback,
    pendingRatings,
  ];
}

typedef $$PendingFeedbackTableCreateCompanionBuilder =
    PendingFeedbackCompanion Function({
      required String clientId,
      required String deviceId,
      required String emojiChoice,
      required DateTime createdAt,
      Value<String> syncStatus,
      Value<int> attempts,
      Value<DateTime?> lastAttemptAt,
      Value<DateTime?> nextRetryAt,
      Value<int> rowid,
    });
typedef $$PendingFeedbackTableUpdateCompanionBuilder =
    PendingFeedbackCompanion Function({
      Value<String> clientId,
      Value<String> deviceId,
      Value<String> emojiChoice,
      Value<DateTime> createdAt,
      Value<String> syncStatus,
      Value<int> attempts,
      Value<DateTime?> lastAttemptAt,
      Value<DateTime?> nextRetryAt,
      Value<int> rowid,
    });

class $$PendingFeedbackTableFilterComposer
    extends Composer<_$AppDatabase, $PendingFeedbackTable> {
  $$PendingFeedbackTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get emojiChoice => $composableBuilder(
    column: $table.emojiChoice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextRetryAt => $composableBuilder(
    column: $table.nextRetryAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PendingFeedbackTableOrderingComposer
    extends Composer<_$AppDatabase, $PendingFeedbackTable> {
  $$PendingFeedbackTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get emojiChoice => $composableBuilder(
    column: $table.emojiChoice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextRetryAt => $composableBuilder(
    column: $table.nextRetryAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PendingFeedbackTableAnnotationComposer
    extends Composer<_$AppDatabase, $PendingFeedbackTable> {
  $$PendingFeedbackTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get clientId =>
      $composableBuilder(column: $table.clientId, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<String> get emojiChoice => $composableBuilder(
    column: $table.emojiChoice,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get nextRetryAt => $composableBuilder(
    column: $table.nextRetryAt,
    builder: (column) => column,
  );
}

class $$PendingFeedbackTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PendingFeedbackTable,
          PendingFeedbackData,
          $$PendingFeedbackTableFilterComposer,
          $$PendingFeedbackTableOrderingComposer,
          $$PendingFeedbackTableAnnotationComposer,
          $$PendingFeedbackTableCreateCompanionBuilder,
          $$PendingFeedbackTableUpdateCompanionBuilder,
          (
            PendingFeedbackData,
            BaseReferences<
              _$AppDatabase,
              $PendingFeedbackTable,
              PendingFeedbackData
            >,
          ),
          PendingFeedbackData,
          PrefetchHooks Function()
        > {
  $$PendingFeedbackTableTableManager(
    _$AppDatabase db,
    $PendingFeedbackTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingFeedbackTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PendingFeedbackTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PendingFeedbackTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> clientId = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<String> emojiChoice = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<DateTime?> lastAttemptAt = const Value.absent(),
                Value<DateTime?> nextRetryAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PendingFeedbackCompanion(
                clientId: clientId,
                deviceId: deviceId,
                emojiChoice: emojiChoice,
                createdAt: createdAt,
                syncStatus: syncStatus,
                attempts: attempts,
                lastAttemptAt: lastAttemptAt,
                nextRetryAt: nextRetryAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String clientId,
                required String deviceId,
                required String emojiChoice,
                required DateTime createdAt,
                Value<String> syncStatus = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<DateTime?> lastAttemptAt = const Value.absent(),
                Value<DateTime?> nextRetryAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PendingFeedbackCompanion.insert(
                clientId: clientId,
                deviceId: deviceId,
                emojiChoice: emojiChoice,
                createdAt: createdAt,
                syncStatus: syncStatus,
                attempts: attempts,
                lastAttemptAt: lastAttemptAt,
                nextRetryAt: nextRetryAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PendingFeedbackTable, PendingFeedbackData>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $PendingFeedbackTable,
                    PendingFeedbackData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PendingFeedbackTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PendingFeedbackTable,
      PendingFeedbackData,
      $$PendingFeedbackTableFilterComposer,
      $$PendingFeedbackTableOrderingComposer,
      $$PendingFeedbackTableAnnotationComposer,
      $$PendingFeedbackTableCreateCompanionBuilder,
      $$PendingFeedbackTableUpdateCompanionBuilder,
      (
        PendingFeedbackData,
        BaseReferences<
          _$AppDatabase,
          $PendingFeedbackTable,
          PendingFeedbackData
        >,
      ),
      PendingFeedbackData,
      PrefetchHooks Function()
    >;
typedef $$PendingRatingsTableCreateCompanionBuilder =
    PendingRatingsCompanion Function({
      required String clientId,
      required String deviceId,
      required String projectId,
      required int score,
      required DateTime createdAt,
      Value<String> syncStatus,
      Value<int> attempts,
      Value<DateTime?> lastAttemptAt,
      Value<DateTime?> nextRetryAt,
      Value<int> rowid,
    });
typedef $$PendingRatingsTableUpdateCompanionBuilder =
    PendingRatingsCompanion Function({
      Value<String> clientId,
      Value<String> deviceId,
      Value<String> projectId,
      Value<int> score,
      Value<DateTime> createdAt,
      Value<String> syncStatus,
      Value<int> attempts,
      Value<DateTime?> lastAttemptAt,
      Value<DateTime?> nextRetryAt,
      Value<int> rowid,
    });

class $$PendingRatingsTableFilterComposer
    extends Composer<_$AppDatabase, $PendingRatingsTable> {
  $$PendingRatingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get projectId => $composableBuilder(
    column: $table.projectId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextRetryAt => $composableBuilder(
    column: $table.nextRetryAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PendingRatingsTableOrderingComposer
    extends Composer<_$AppDatabase, $PendingRatingsTable> {
  $$PendingRatingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get projectId => $composableBuilder(
    column: $table.projectId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextRetryAt => $composableBuilder(
    column: $table.nextRetryAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PendingRatingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PendingRatingsTable> {
  $$PendingRatingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get clientId =>
      $composableBuilder(column: $table.clientId, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<String> get projectId =>
      $composableBuilder(column: $table.projectId, builder: (column) => column);

  GeneratedColumn<int> get score =>
      $composableBuilder(column: $table.score, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get nextRetryAt => $composableBuilder(
    column: $table.nextRetryAt,
    builder: (column) => column,
  );
}

class $$PendingRatingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PendingRatingsTable,
          PendingRating,
          $$PendingRatingsTableFilterComposer,
          $$PendingRatingsTableOrderingComposer,
          $$PendingRatingsTableAnnotationComposer,
          $$PendingRatingsTableCreateCompanionBuilder,
          $$PendingRatingsTableUpdateCompanionBuilder,
          (
            PendingRating,
            BaseReferences<_$AppDatabase, $PendingRatingsTable, PendingRating>,
          ),
          PendingRating,
          PrefetchHooks Function()
        > {
  $$PendingRatingsTableTableManager(
    _$AppDatabase db,
    $PendingRatingsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingRatingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PendingRatingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PendingRatingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> clientId = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<String> projectId = const Value.absent(),
                Value<int> score = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<DateTime?> lastAttemptAt = const Value.absent(),
                Value<DateTime?> nextRetryAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PendingRatingsCompanion(
                clientId: clientId,
                deviceId: deviceId,
                projectId: projectId,
                score: score,
                createdAt: createdAt,
                syncStatus: syncStatus,
                attempts: attempts,
                lastAttemptAt: lastAttemptAt,
                nextRetryAt: nextRetryAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String clientId,
                required String deviceId,
                required String projectId,
                required int score,
                required DateTime createdAt,
                Value<String> syncStatus = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<DateTime?> lastAttemptAt = const Value.absent(),
                Value<DateTime?> nextRetryAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PendingRatingsCompanion.insert(
                clientId: clientId,
                deviceId: deviceId,
                projectId: projectId,
                score: score,
                createdAt: createdAt,
                syncStatus: syncStatus,
                attempts: attempts,
                lastAttemptAt: lastAttemptAt,
                nextRetryAt: nextRetryAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PendingRatingsTable, PendingRating>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $PendingRatingsTable,
                    PendingRating
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PendingRatingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PendingRatingsTable,
      PendingRating,
      $$PendingRatingsTableFilterComposer,
      $$PendingRatingsTableOrderingComposer,
      $$PendingRatingsTableAnnotationComposer,
      $$PendingRatingsTableCreateCompanionBuilder,
      $$PendingRatingsTableUpdateCompanionBuilder,
      (
        PendingRating,
        BaseReferences<_$AppDatabase, $PendingRatingsTable, PendingRating>,
      ),
      PendingRating,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$PendingFeedbackTableTableManager get pendingFeedback =>
      $$PendingFeedbackTableTableManager(_db, _db.pendingFeedback);
  $$PendingRatingsTableTableManager get pendingRatings =>
      $$PendingRatingsTableTableManager(_db, _db.pendingRatings);
}
