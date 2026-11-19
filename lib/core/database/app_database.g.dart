// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $FeedbackEntriesTable extends FeedbackEntries
    with TableInfo<$FeedbackEntriesTable, FeedbackEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FeedbackEntriesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _eventIdMeta = const VerificationMeta(
    'eventId',
  );
  @override
  late final GeneratedColumn<String> eventId = GeneratedColumn<String>(
    'event_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
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
  static const VerificationMeta _sentimentMeta = const VerificationMeta(
    'sentiment',
  );
  @override
  late final GeneratedColumn<String> sentiment = GeneratedColumn<String>(
    'sentiment',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
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
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<bool> synced = GeneratedColumn<bool>(
    'synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    eventId,
    deviceId,
    sentiment,
    note,
    createdAt,
    synced,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'feedback_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<FeedbackEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('event_id')) {
      context.handle(
        _eventIdMeta,
        eventId.isAcceptableOrUnknown(data['event_id']!, _eventIdMeta),
      );
    } else if (isInserting) {
      context.missing(_eventIdMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('sentiment')) {
      context.handle(
        _sentimentMeta,
        sentiment.isAcceptableOrUnknown(data['sentiment']!, _sentimentMeta),
      );
    } else if (isInserting) {
      context.missing(_sentimentMeta);
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
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('synced')) {
      context.handle(
        _syncedMeta,
        synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FeedbackEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FeedbackEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      eventId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_id'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      sentiment: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sentiment'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      synced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}synced'],
      )!,
    );
  }

  @override
  $FeedbackEntriesTable createAlias(String alias) {
    return $FeedbackEntriesTable(attachedDatabase, alias);
  }
}

class FeedbackEntry extends DataClass implements Insertable<FeedbackEntry> {
  final int id;
  final String eventId;
  final String deviceId;
  final String sentiment;
  final String note;
  final DateTime createdAt;
  final bool synced;
  const FeedbackEntry({
    required this.id,
    required this.eventId,
    required this.deviceId,
    required this.sentiment,
    required this.note,
    required this.createdAt,
    required this.synced,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['event_id'] = Variable<String>(eventId);
    map['device_id'] = Variable<String>(deviceId);
    map['sentiment'] = Variable<String>(sentiment);
    map['note'] = Variable<String>(note);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['synced'] = Variable<bool>(synced);
    return map;
  }

  FeedbackEntriesCompanion toCompanion(bool nullToAbsent) {
    return FeedbackEntriesCompanion(
      id: Value(id),
      eventId: Value(eventId),
      deviceId: Value(deviceId),
      sentiment: Value(sentiment),
      note: Value(note),
      createdAt: Value(createdAt),
      synced: Value(synced),
    );
  }

  factory FeedbackEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FeedbackEntry(
      id: serializer.fromJson<int>(json['id']),
      eventId: serializer.fromJson<String>(json['eventId']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      sentiment: serializer.fromJson<String>(json['sentiment']),
      note: serializer.fromJson<String>(json['note']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      synced: serializer.fromJson<bool>(json['synced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'eventId': serializer.toJson<String>(eventId),
      'deviceId': serializer.toJson<String>(deviceId),
      'sentiment': serializer.toJson<String>(sentiment),
      'note': serializer.toJson<String>(note),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'synced': serializer.toJson<bool>(synced),
    };
  }

  FeedbackEntry copyWith({
    int? id,
    String? eventId,
    String? deviceId,
    String? sentiment,
    String? note,
    DateTime? createdAt,
    bool? synced,
  }) => FeedbackEntry(
    id: id ?? this.id,
    eventId: eventId ?? this.eventId,
    deviceId: deviceId ?? this.deviceId,
    sentiment: sentiment ?? this.sentiment,
    note: note ?? this.note,
    createdAt: createdAt ?? this.createdAt,
    synced: synced ?? this.synced,
  );
  FeedbackEntry copyWithCompanion(FeedbackEntriesCompanion data) {
    return FeedbackEntry(
      id: data.id.present ? data.id.value : this.id,
      eventId: data.eventId.present ? data.eventId.value : this.eventId,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      sentiment: data.sentiment.present ? data.sentiment.value : this.sentiment,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      synced: data.synced.present ? data.synced.value : this.synced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FeedbackEntry(')
          ..write('id: $id, ')
          ..write('eventId: $eventId, ')
          ..write('deviceId: $deviceId, ')
          ..write('sentiment: $sentiment, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, eventId, deviceId, sentiment, note, createdAt, synced);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FeedbackEntry &&
          other.id == this.id &&
          other.eventId == this.eventId &&
          other.deviceId == this.deviceId &&
          other.sentiment == this.sentiment &&
          other.note == this.note &&
          other.createdAt == this.createdAt &&
          other.synced == this.synced);
}

class FeedbackEntriesCompanion extends UpdateCompanion<FeedbackEntry> {
  final Value<int> id;
  final Value<String> eventId;
  final Value<String> deviceId;
  final Value<String> sentiment;
  final Value<String> note;
  final Value<DateTime> createdAt;
  final Value<bool> synced;
  const FeedbackEntriesCompanion({
    this.id = const Value.absent(),
    this.eventId = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.sentiment = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.synced = const Value.absent(),
  });
  FeedbackEntriesCompanion.insert({
    this.id = const Value.absent(),
    required String eventId,
    required String deviceId,
    required String sentiment,
    this.note = const Value.absent(),
    required DateTime createdAt,
    this.synced = const Value.absent(),
  }) : eventId = Value(eventId),
       deviceId = Value(deviceId),
       sentiment = Value(sentiment),
       createdAt = Value(createdAt);
  static Insertable<FeedbackEntry> custom({
    Expression<int>? id,
    Expression<String>? eventId,
    Expression<String>? deviceId,
    Expression<String>? sentiment,
    Expression<String>? note,
    Expression<DateTime>? createdAt,
    Expression<bool>? synced,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (eventId != null) 'event_id': eventId,
      if (deviceId != null) 'device_id': deviceId,
      if (sentiment != null) 'sentiment': sentiment,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
      if (synced != null) 'synced': synced,
    });
  }

  FeedbackEntriesCompanion copyWith({
    Value<int>? id,
    Value<String>? eventId,
    Value<String>? deviceId,
    Value<String>? sentiment,
    Value<String>? note,
    Value<DateTime>? createdAt,
    Value<bool>? synced,
  }) {
    return FeedbackEntriesCompanion(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      deviceId: deviceId ?? this.deviceId,
      sentiment: sentiment ?? this.sentiment,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      synced: synced ?? this.synced,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (eventId.present) {
      map['event_id'] = Variable<String>(eventId.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (sentiment.present) {
      map['sentiment'] = Variable<String>(sentiment.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (synced.present) {
      map['synced'] = Variable<bool>(synced.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FeedbackEntriesCompanion(')
          ..write('id: $id, ')
          ..write('eventId: $eventId, ')
          ..write('deviceId: $deviceId, ')
          ..write('sentiment: $sentiment, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }
}

class $ProjectRatingsTable extends ProjectRatings
    with TableInfo<$ProjectRatingsTable, ProjectRating> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProjectRatingsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _eventIdMeta = const VerificationMeta(
    'eventId',
  );
  @override
  late final GeneratedColumn<String> eventId = GeneratedColumn<String>(
    'event_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
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
  static const VerificationMeta _projectTitleMeta = const VerificationMeta(
    'projectTitle',
  );
  @override
  late final GeneratedColumn<String> projectTitle = GeneratedColumn<String>(
    'project_title',
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
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<bool> synced = GeneratedColumn<bool>(
    'synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    eventId,
    deviceId,
    projectId,
    projectTitle,
    score,
    createdAt,
    synced,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'project_ratings';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProjectRating> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('event_id')) {
      context.handle(
        _eventIdMeta,
        eventId.isAcceptableOrUnknown(data['event_id']!, _eventIdMeta),
      );
    } else if (isInserting) {
      context.missing(_eventIdMeta);
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
    if (data.containsKey('project_title')) {
      context.handle(
        _projectTitleMeta,
        projectTitle.isAcceptableOrUnknown(
          data['project_title']!,
          _projectTitleMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_projectTitleMeta);
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
    if (data.containsKey('synced')) {
      context.handle(
        _syncedMeta,
        synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProjectRating map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProjectRating(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      eventId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_id'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      projectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project_id'],
      )!,
      projectTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project_title'],
      )!,
      score: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}score'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      synced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}synced'],
      )!,
    );
  }

  @override
  $ProjectRatingsTable createAlias(String alias) {
    return $ProjectRatingsTable(attachedDatabase, alias);
  }
}

class ProjectRating extends DataClass implements Insertable<ProjectRating> {
  final int id;
  final String eventId;
  final String deviceId;
  final String projectId;
  final String projectTitle;
  final int score;
  final DateTime createdAt;
  final bool synced;
  const ProjectRating({
    required this.id,
    required this.eventId,
    required this.deviceId,
    required this.projectId,
    required this.projectTitle,
    required this.score,
    required this.createdAt,
    required this.synced,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['event_id'] = Variable<String>(eventId);
    map['device_id'] = Variable<String>(deviceId);
    map['project_id'] = Variable<String>(projectId);
    map['project_title'] = Variable<String>(projectTitle);
    map['score'] = Variable<int>(score);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['synced'] = Variable<bool>(synced);
    return map;
  }

  ProjectRatingsCompanion toCompanion(bool nullToAbsent) {
    return ProjectRatingsCompanion(
      id: Value(id),
      eventId: Value(eventId),
      deviceId: Value(deviceId),
      projectId: Value(projectId),
      projectTitle: Value(projectTitle),
      score: Value(score),
      createdAt: Value(createdAt),
      synced: Value(synced),
    );
  }

  factory ProjectRating.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProjectRating(
      id: serializer.fromJson<int>(json['id']),
      eventId: serializer.fromJson<String>(json['eventId']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      projectId: serializer.fromJson<String>(json['projectId']),
      projectTitle: serializer.fromJson<String>(json['projectTitle']),
      score: serializer.fromJson<int>(json['score']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      synced: serializer.fromJson<bool>(json['synced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'eventId': serializer.toJson<String>(eventId),
      'deviceId': serializer.toJson<String>(deviceId),
      'projectId': serializer.toJson<String>(projectId),
      'projectTitle': serializer.toJson<String>(projectTitle),
      'score': serializer.toJson<int>(score),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'synced': serializer.toJson<bool>(synced),
    };
  }

  ProjectRating copyWith({
    int? id,
    String? eventId,
    String? deviceId,
    String? projectId,
    String? projectTitle,
    int? score,
    DateTime? createdAt,
    bool? synced,
  }) => ProjectRating(
    id: id ?? this.id,
    eventId: eventId ?? this.eventId,
    deviceId: deviceId ?? this.deviceId,
    projectId: projectId ?? this.projectId,
    projectTitle: projectTitle ?? this.projectTitle,
    score: score ?? this.score,
    createdAt: createdAt ?? this.createdAt,
    synced: synced ?? this.synced,
  );
  ProjectRating copyWithCompanion(ProjectRatingsCompanion data) {
    return ProjectRating(
      id: data.id.present ? data.id.value : this.id,
      eventId: data.eventId.present ? data.eventId.value : this.eventId,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      projectTitle: data.projectTitle.present
          ? data.projectTitle.value
          : this.projectTitle,
      score: data.score.present ? data.score.value : this.score,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      synced: data.synced.present ? data.synced.value : this.synced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProjectRating(')
          ..write('id: $id, ')
          ..write('eventId: $eventId, ')
          ..write('deviceId: $deviceId, ')
          ..write('projectId: $projectId, ')
          ..write('projectTitle: $projectTitle, ')
          ..write('score: $score, ')
          ..write('createdAt: $createdAt, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    eventId,
    deviceId,
    projectId,
    projectTitle,
    score,
    createdAt,
    synced,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProjectRating &&
          other.id == this.id &&
          other.eventId == this.eventId &&
          other.deviceId == this.deviceId &&
          other.projectId == this.projectId &&
          other.projectTitle == this.projectTitle &&
          other.score == this.score &&
          other.createdAt == this.createdAt &&
          other.synced == this.synced);
}

class ProjectRatingsCompanion extends UpdateCompanion<ProjectRating> {
  final Value<int> id;
  final Value<String> eventId;
  final Value<String> deviceId;
  final Value<String> projectId;
  final Value<String> projectTitle;
  final Value<int> score;
  final Value<DateTime> createdAt;
  final Value<bool> synced;
  const ProjectRatingsCompanion({
    this.id = const Value.absent(),
    this.eventId = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.projectId = const Value.absent(),
    this.projectTitle = const Value.absent(),
    this.score = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.synced = const Value.absent(),
  });
  ProjectRatingsCompanion.insert({
    this.id = const Value.absent(),
    required String eventId,
    required String deviceId,
    required String projectId,
    required String projectTitle,
    required int score,
    required DateTime createdAt,
    this.synced = const Value.absent(),
  }) : eventId = Value(eventId),
       deviceId = Value(deviceId),
       projectId = Value(projectId),
       projectTitle = Value(projectTitle),
       score = Value(score),
       createdAt = Value(createdAt);
  static Insertable<ProjectRating> custom({
    Expression<int>? id,
    Expression<String>? eventId,
    Expression<String>? deviceId,
    Expression<String>? projectId,
    Expression<String>? projectTitle,
    Expression<int>? score,
    Expression<DateTime>? createdAt,
    Expression<bool>? synced,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (eventId != null) 'event_id': eventId,
      if (deviceId != null) 'device_id': deviceId,
      if (projectId != null) 'project_id': projectId,
      if (projectTitle != null) 'project_title': projectTitle,
      if (score != null) 'score': score,
      if (createdAt != null) 'created_at': createdAt,
      if (synced != null) 'synced': synced,
    });
  }

  ProjectRatingsCompanion copyWith({
    Value<int>? id,
    Value<String>? eventId,
    Value<String>? deviceId,
    Value<String>? projectId,
    Value<String>? projectTitle,
    Value<int>? score,
    Value<DateTime>? createdAt,
    Value<bool>? synced,
  }) {
    return ProjectRatingsCompanion(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      deviceId: deviceId ?? this.deviceId,
      projectId: projectId ?? this.projectId,
      projectTitle: projectTitle ?? this.projectTitle,
      score: score ?? this.score,
      createdAt: createdAt ?? this.createdAt,
      synced: synced ?? this.synced,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (eventId.present) {
      map['event_id'] = Variable<String>(eventId.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<String>(projectId.value);
    }
    if (projectTitle.present) {
      map['project_title'] = Variable<String>(projectTitle.value);
    }
    if (score.present) {
      map['score'] = Variable<int>(score.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (synced.present) {
      map['synced'] = Variable<bool>(synced.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProjectRatingsCompanion(')
          ..write('id: $id, ')
          ..write('eventId: $eventId, ')
          ..write('deviceId: $deviceId, ')
          ..write('projectId: $projectId, ')
          ..write('projectTitle: $projectTitle, ')
          ..write('score: $score, ')
          ..write('createdAt: $createdAt, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $FeedbackEntriesTable feedbackEntries = $FeedbackEntriesTable(
    this,
  );
  late final $ProjectRatingsTable projectRatings = $ProjectRatingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    feedbackEntries,
    projectRatings,
  ];
}

typedef $$FeedbackEntriesTableCreateCompanionBuilder =
    FeedbackEntriesCompanion Function({
      Value<int> id,
      required String eventId,
      required String deviceId,
      required String sentiment,
      Value<String> note,
      required DateTime createdAt,
      Value<bool> synced,
    });
typedef $$FeedbackEntriesTableUpdateCompanionBuilder =
    FeedbackEntriesCompanion Function({
      Value<int> id,
      Value<String> eventId,
      Value<String> deviceId,
      Value<String> sentiment,
      Value<String> note,
      Value<DateTime> createdAt,
      Value<bool> synced,
    });

class $$FeedbackEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $FeedbackEntriesTable> {
  $$FeedbackEntriesTableFilterComposer({
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

  ColumnFilters<String> get eventId => $composableBuilder(
    column: $table.eventId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sentiment => $composableBuilder(
    column: $table.sentiment,
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

  ColumnFilters<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FeedbackEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $FeedbackEntriesTable> {
  $$FeedbackEntriesTableOrderingComposer({
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

  ColumnOrderings<String> get eventId => $composableBuilder(
    column: $table.eventId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sentiment => $composableBuilder(
    column: $table.sentiment,
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

  ColumnOrderings<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FeedbackEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $FeedbackEntriesTable> {
  $$FeedbackEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get eventId =>
      $composableBuilder(column: $table.eventId, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<String> get sentiment =>
      $composableBuilder(column: $table.sentiment, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);
}

class $$FeedbackEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FeedbackEntriesTable,
          FeedbackEntry,
          $$FeedbackEntriesTableFilterComposer,
          $$FeedbackEntriesTableOrderingComposer,
          $$FeedbackEntriesTableAnnotationComposer,
          $$FeedbackEntriesTableCreateCompanionBuilder,
          $$FeedbackEntriesTableUpdateCompanionBuilder,
          (
            FeedbackEntry,
            BaseReferences<_$AppDatabase, $FeedbackEntriesTable, FeedbackEntry>,
          ),
          FeedbackEntry,
          PrefetchHooks Function()
        > {
  $$FeedbackEntriesTableTableManager(
    _$AppDatabase db,
    $FeedbackEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FeedbackEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FeedbackEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FeedbackEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> eventId = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<String> sentiment = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<bool> synced = const Value.absent(),
              }) => FeedbackEntriesCompanion(
                id: id,
                eventId: eventId,
                deviceId: deviceId,
                sentiment: sentiment,
                note: note,
                createdAt: createdAt,
                synced: synced,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String eventId,
                required String deviceId,
                required String sentiment,
                Value<String> note = const Value.absent(),
                required DateTime createdAt,
                Value<bool> synced = const Value.absent(),
              }) => FeedbackEntriesCompanion.insert(
                id: id,
                eventId: eventId,
                deviceId: deviceId,
                sentiment: sentiment,
                note: note,
                createdAt: createdAt,
                synced: synced,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FeedbackEntriesTable, FeedbackEntry>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $FeedbackEntriesTable,
                    FeedbackEntry
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FeedbackEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FeedbackEntriesTable,
      FeedbackEntry,
      $$FeedbackEntriesTableFilterComposer,
      $$FeedbackEntriesTableOrderingComposer,
      $$FeedbackEntriesTableAnnotationComposer,
      $$FeedbackEntriesTableCreateCompanionBuilder,
      $$FeedbackEntriesTableUpdateCompanionBuilder,
      (
        FeedbackEntry,
        BaseReferences<_$AppDatabase, $FeedbackEntriesTable, FeedbackEntry>,
      ),
      FeedbackEntry,
      PrefetchHooks Function()
    >;
typedef $$ProjectRatingsTableCreateCompanionBuilder =
    ProjectRatingsCompanion Function({
      Value<int> id,
      required String eventId,
      required String deviceId,
      required String projectId,
      required String projectTitle,
      required int score,
      required DateTime createdAt,
      Value<bool> synced,
    });
typedef $$ProjectRatingsTableUpdateCompanionBuilder =
    ProjectRatingsCompanion Function({
      Value<int> id,
      Value<String> eventId,
      Value<String> deviceId,
      Value<String> projectId,
      Value<String> projectTitle,
      Value<int> score,
      Value<DateTime> createdAt,
      Value<bool> synced,
    });

class $$ProjectRatingsTableFilterComposer
    extends Composer<_$AppDatabase, $ProjectRatingsTable> {
  $$ProjectRatingsTableFilterComposer({
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

  ColumnFilters<String> get eventId => $composableBuilder(
    column: $table.eventId,
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

  ColumnFilters<String> get projectTitle => $composableBuilder(
    column: $table.projectTitle,
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

  ColumnFilters<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProjectRatingsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProjectRatingsTable> {
  $$ProjectRatingsTableOrderingComposer({
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

  ColumnOrderings<String> get eventId => $composableBuilder(
    column: $table.eventId,
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

  ColumnOrderings<String> get projectTitle => $composableBuilder(
    column: $table.projectTitle,
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

  ColumnOrderings<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProjectRatingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProjectRatingsTable> {
  $$ProjectRatingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get eventId =>
      $composableBuilder(column: $table.eventId, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<String> get projectId =>
      $composableBuilder(column: $table.projectId, builder: (column) => column);

  GeneratedColumn<String> get projectTitle => $composableBuilder(
    column: $table.projectTitle,
    builder: (column) => column,
  );

  GeneratedColumn<int> get score =>
      $composableBuilder(column: $table.score, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);
}

class $$ProjectRatingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProjectRatingsTable,
          ProjectRating,
          $$ProjectRatingsTableFilterComposer,
          $$ProjectRatingsTableOrderingComposer,
          $$ProjectRatingsTableAnnotationComposer,
          $$ProjectRatingsTableCreateCompanionBuilder,
          $$ProjectRatingsTableUpdateCompanionBuilder,
          (
            ProjectRating,
            BaseReferences<_$AppDatabase, $ProjectRatingsTable, ProjectRating>,
          ),
          ProjectRating,
          PrefetchHooks Function()
        > {
  $$ProjectRatingsTableTableManager(
    _$AppDatabase db,
    $ProjectRatingsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProjectRatingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProjectRatingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProjectRatingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> eventId = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<String> projectId = const Value.absent(),
                Value<String> projectTitle = const Value.absent(),
                Value<int> score = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<bool> synced = const Value.absent(),
              }) => ProjectRatingsCompanion(
                id: id,
                eventId: eventId,
                deviceId: deviceId,
                projectId: projectId,
                projectTitle: projectTitle,
                score: score,
                createdAt: createdAt,
                synced: synced,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String eventId,
                required String deviceId,
                required String projectId,
                required String projectTitle,
                required int score,
                required DateTime createdAt,
                Value<bool> synced = const Value.absent(),
              }) => ProjectRatingsCompanion.insert(
                id: id,
                eventId: eventId,
                deviceId: deviceId,
                projectId: projectId,
                projectTitle: projectTitle,
                score: score,
                createdAt: createdAt,
                synced: synced,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ProjectRatingsTable, ProjectRating>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ProjectRatingsTable,
                    ProjectRating
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProjectRatingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProjectRatingsTable,
      ProjectRating,
      $$ProjectRatingsTableFilterComposer,
      $$ProjectRatingsTableOrderingComposer,
      $$ProjectRatingsTableAnnotationComposer,
      $$ProjectRatingsTableCreateCompanionBuilder,
      $$ProjectRatingsTableUpdateCompanionBuilder,
      (
        ProjectRating,
        BaseReferences<_$AppDatabase, $ProjectRatingsTable, ProjectRating>,
      ),
      ProjectRating,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$FeedbackEntriesTableTableManager get feedbackEntries =>
      $$FeedbackEntriesTableTableManager(_db, _db.feedbackEntries);
  $$ProjectRatingsTableTableManager get projectRatings =>
      $$ProjectRatingsTableTableManager(_db, _db.projectRatings);
}
