import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../data/datasources/room_remote_datasource.dart';
import '../../../data/models/room_member_model.dart';
import '../../../data/models/session_record_model.dart';

class RoomParticipantsData {
  final List<RoomMemberModel> allMembers;
  final Set<String> onlineUserIds;

  const RoomParticipantsData({
    required this.allMembers,
    required this.onlineUserIds,
  });

  int get totalCount => allMembers.length;
  int get onlineCount => onlineUserIds.length;
  bool isOnline(String userId) => onlineUserIds.contains(userId);
}

final roomParticipantsProvider =
    FutureProvider.family<RoomParticipantsData, String>((ref, roomId) async {
      final datasource = RoomRemoteDatasource(ref.read(dioClientProvider));

      final membersData = await datasource.getMembers(roomId);
      final allMembers = (membersData['members'] as List<dynamic>? ?? [])
          .map((m) => RoomMemberModel.fromJson(m as Map<String, dynamic>))
          .toList();

      Set<String> onlineUserIds = {};
      try {
        final sessionsList = await datasource.getSessionHistory(roomId);
        final sessions = sessionsList
            .map((s) => SessionRecord.fromJson(s as Map<String, dynamic>))
            .toList();

        // Most recent session is first. Find the active one (endedAt == null).
        final activeSession = sessions
            .where((s) => s.endedAt == null)
            .firstOrNull;
        if (activeSession != null) {
          onlineUserIds = activeSession.participants
              .where((p) => p.leftAt == null)
              .map((p) => p.userId)
              .toSet();
        }
      } catch (_) {
        // Sessions endpoint returns 403 for non-hosts — silently ignore.
      }

      return RoomParticipantsData(
        allMembers: allMembers,
        onlineUserIds: onlineUserIds,
      );
    });
