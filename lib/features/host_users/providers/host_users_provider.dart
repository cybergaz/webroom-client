import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../data/host_user_datasource.dart';
import '../models/managed_user.dart';

final hostUserDatasourceProvider = Provider<HostUserDatasource>((ref) {
  return HostUserDatasource(ref.watch(dioClientProvider));
});

class HostUsersNotifier extends AsyncNotifier<List<ManagedUser>> {
  late HostUserDatasource _ds;

  @override
  Future<List<ManagedUser>> build() async {
    _ds = ref.read(hostUserDatasourceProvider);
    return _ds.listUsers();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _ds.listUsers());
  }

  void _patch(String userId, ManagedUser Function(ManagedUser) update) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(
      current.map((u) => u.id == userId ? update(u) : u).toList(),
    );
  }

  Future<void> updateUser(
    String userId, {
    String? name,
    String? password,
  }) async {
    await _ds.updateUser(userId, name: name, password: password);
    if (name != null) _patch(userId, (u) => u.copyWith(name: name));
  }

  Future<void> setStatus(String userId, {required bool active}) async {
    if (active) {
      await _ds.activateUser(userId);
      _patch(userId, (u) => u.copyWith(status: 'approved'));
    } else {
      await _ds.deactivateUser(userId);
      _patch(userId, (u) => u.copyWith(status: 'rejected'));
    }
  }

  Future<void> forceLogout(String userId) => _ds.forceLogout(userId);

  Future<void> allowDeviceChange(String userId) async {
    await _ds.allowDeviceChange(userId);
    _patch(userId, (u) => u.copyWith(allowDeviceChange: true));
  }

  Future<void> resetDeviceLock(String userId) async {
    await _ds.resetDeviceLock(userId);
    _patch(
      userId,
      (u) => ManagedUser(
        id: u.id,
        requestId: u.requestId,
        name: u.name,
        phone: u.phone,
        email: u.email,
        status: u.status,
        deviceName: u.deviceName,
        lockedDeviceId: null,
        lockedDeviceName: null,
        allowDeviceChange: false,
        appVersion: u.appVersion,
        createdAt: u.createdAt,
        lastSeenAt: u.lastSeenAt,
      ),
    );
  }

  Future<void> deleteUser(String userId) async {
    await _ds.deleteUser(userId);
    final current = state.value;
    if (current != null) {
      state = AsyncData(current.where((u) => u.id != userId).toList());
    }
  }
}

final hostUsersProvider =
    AsyncNotifierProvider<HostUsersNotifier, List<ManagedUser>>(
  HostUsersNotifier.new,
);
