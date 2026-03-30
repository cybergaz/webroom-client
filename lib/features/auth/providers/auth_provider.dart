import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/auth_repository_impl.dart';
import '../../../data/datasources/auth_remote_datasource.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/constants/storage_keys.dart';
import '../../../domain/enums/user_role.dart';
import '../../room/providers/getstream_provider.dart';

part 'auth_provider.freezed.dart';

@freezed
sealed class AuthState with _$AuthState {
  const factory AuthState.initial() = AuthStateInitial;
  const factory AuthState.loading() = AuthStateLoading;
  const factory AuthState.authenticated({required UserModel user}) =
      AuthStateAuthenticated;
  const factory AuthState.unauthenticated() = AuthStateUnauthenticated;
  const factory AuthState.pendingApproval({String? requestId}) =
      AuthStatePendingApproval;
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    _initialize();
    return const AuthState.initial();
  }

  Future<void> _initialize() async {
    state = const AuthState.loading();
    final storage = ref.read(secureStorageProvider);
    final token = await storage.read(StorageKeys.accessToken);
    final userStatus = await storage.read(StorageKeys.userStatus);
    final roleStr = await storage.read(StorageKeys.userRole);

    if (token == null) {
      state = const AuthState.unauthenticated();
      return;
    }

    if (userStatus == 'pending_approval') {
      final requestId = await storage.read(StorageKeys.requestId);
      state = AuthState.pendingApproval(requestId: requestId);
      return;
    }

    final userId = await storage.read(StorageKeys.userId);
    final userName = await storage.read(StorageKeys.userName) ?? '';
    final userPhone = await storage.read(StorageKeys.userPhone);
    final userEmail = await storage.read(StorageKeys.userEmail);
    final userRequestId = await storage.read(StorageKeys.requestId);
    final getstreamToken = await storage.read(StorageKeys.getstreamToken);

    if (userId != null && roleStr != null) {
      final role = UserRole.values.firstWhere(
        (r) => r.name == roleStr,
        orElse: () => UserRole.user,
      );
      final user = UserModel(
        userId: userId,
        name: userName,
        phone: userPhone,
        email: userEmail,
        role: role,
        status: userStatus ?? 'approved',
        requestId: userRequestId,
      );
      // Re-initialize StreamVideo for this user session.
      // Wrapped in try/catch so a GetStream failure doesn't block auth.
      if (getstreamToken != null) {
        try {
          await ref.read(getstreamStateProvider.notifier).init(
            userId: userId,
            userName: userName,
            getstreamToken: getstreamToken,
            role: role,
          );
        } catch (e) {
          print('StreamVideo init failed on restore, will retry on room entry: $e');
        }
      }
      state = AuthState.authenticated(user: user);
    } else {
      state = const AuthState.unauthenticated();
    }
  }

  Future<String> signup({
    required String name,
    required String password,
    String? phone,
    String? email,
  }) async {
    final repo = AuthRepositoryImpl(
      AuthRemoteDatasource(ref.read(dioClientProvider)),
      ref.read(secureStorageProvider),
    );
    final requestId = await repo.signup(
      name: name,
      password: password,
      phone: phone,
      email: email,
    );
    final storage = ref.read(secureStorageProvider);
    await storage.write(StorageKeys.userStatus, 'pending_approval');
    await storage.write(StorageKeys.requestId, requestId);
    state = AuthState.pendingApproval(requestId: requestId);
    return requestId;
  }

  Future<void> login({String? phone, String? email, required String password}) async {
    state = const AuthState.loading();
    final repo = AuthRepositoryImpl(
      AuthRemoteDatasource(ref.read(dioClientProvider)),
      ref.read(secureStorageProvider),
    );
    final result = await repo.login(phone: phone, email: email, password: password);

    // Persist user name for StreamVideo re-init on next app launch
    await ref
        .read(secureStorageProvider)
        .write(StorageKeys.userName, result.user.name);

    // Initialize GetStream SDK for this user
    await ref.read(getstreamStateProvider.notifier).init(
      userId: result.user.userId,
      userName: result.user.name,
      getstreamToken: result.getstreamToken,
      role: result.user.role,
    );

    state = AuthState.authenticated(user: result.user);
  }

  void forceLogout() {
    state = const AuthState.unauthenticated();
  }

  Future<void> logout() async {
    await ref.read(getstreamStateProvider.notifier).dispose();
    final repo = AuthRepositoryImpl(
      AuthRemoteDatasource(ref.read(dioClientProvider)),
      ref.read(secureStorageProvider),
    );
    await repo.logout();
    state = const AuthState.unauthenticated();
  }
}

final authStateProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
