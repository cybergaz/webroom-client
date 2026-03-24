import 'package:drift/drift.dart';

class CachedRooms extends Table {
  TextColumn get roomId => text()();
  TextColumn get name => text()();
  TextColumn get status => text()();
  IntColumn get memberCount => integer().withDefault(const Constant(0))();
  TextColumn get createdBy => text()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get getstreamCallId => text()();
  TextColumn get description => text().nullable()();

  @override
  Set<Column> get primaryKey => {roomId};
}

class CachedUsers extends Table {
  TextColumn get userId => text()();
  TextColumn get name => text()();
  TextColumn get phone => text()();
  TextColumn get email => text().nullable()();
  TextColumn get role => text().withDefault(const Constant('user'))();
  TextColumn get status => text()();
  DateTimeColumn get requestedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {userId};
}
