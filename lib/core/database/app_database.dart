import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [CachedRooms, CachedUsers])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'webroom');
  }

  // --- Rooms ---
  Future<List<CachedRoom>> getAllRooms() => select(cachedRooms).get();
  Stream<List<CachedRoom>> watchAllRooms() => select(cachedRooms).watch();

  Future<void> upsertRoom(CachedRoomsCompanion room) {
    return into(cachedRooms).insertOnConflictUpdate(room);
  }

  Future<void> upsertRooms(List<CachedRoomsCompanion> rooms) async {
    await batch((b) {
      for (final room in rooms) {
        b.insert(cachedRooms, room, onConflict: DoUpdate((_) => room));
      }
    });
  }

  Future<int> deleteRoom(String roomId) {
    return (delete(cachedRooms)..where((r) => r.roomId.equals(roomId))).go();
  }

  Future<int> clearRooms() => delete(cachedRooms).go();

  // --- Users ---
  Future<List<CachedUser>> getAllUsers() => select(cachedUsers).get();

  Future<void> upsertUsers(List<CachedUsersCompanion> users) async {
    await batch((b) {
      for (final user in users) {
        b.insert(cachedUsers, user, onConflict: DoUpdate((_) => user));
      }
    });
  }

  Future<int> clearUsers() => delete(cachedUsers).go();
}

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
