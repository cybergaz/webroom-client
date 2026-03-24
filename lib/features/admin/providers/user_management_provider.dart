import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/user_repository_impl.dart';
import '../../../data/datasources/user_remote_datasource.dart';
import '../../../core/network/dio_client.dart';

class PendingUsersNotifier extends AsyncNotifier<List<Map<String, dynamic>>> {
  @override
  Future<List<Map<String, dynamic>>> build() async {
    final repo = UserRepositoryImpl(UserRemoteDatasource(ref.read(dioClientProvider)));
    return repo.getPendingUsers();
  }

  Future<void> approveUser(String userId) async {
    final repo = UserRepositoryImpl(UserRemoteDatasource(ref.read(dioClientProvider)));
    await repo.approveUser(userId);
    state = AsyncData(
      state.value?.where((u) => (u['userId'] ?? u['id']) != userId).toList() ?? [],
    );
  }

  Future<void> rejectUser(String userId) async {
    final repo = UserRepositoryImpl(UserRemoteDatasource(ref.read(dioClientProvider)));
    await repo.rejectUser(userId);
    state = AsyncData(
      state.value?.where((u) => (u['userId'] ?? u['id']) != userId).toList() ?? [],
    );
  }
}

final pendingUsersProvider =
    AsyncNotifierProvider<PendingUsersNotifier, List<Map<String, dynamic>>>(PendingUsersNotifier.new);
