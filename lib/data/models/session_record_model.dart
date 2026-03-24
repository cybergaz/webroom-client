import 'package:freezed_annotation/freezed_annotation.dart';

part 'session_record_model.freezed.dart';
part 'session_record_model.g.dart';

@freezed
abstract class SessionRecord with _$SessionRecord {
  const factory SessionRecord({
    required String id,
    required String roomId,
    required DateTime startedAt,
    DateTime? endedAt,
    @Default([]) List<SessionParticipant> participants,
  }) = _SessionRecord;

  factory SessionRecord.fromJson(Map<String, dynamic> json) =>
      _$SessionRecordFromJson(json);
}

@freezed
abstract class SessionParticipant with _$SessionParticipant {
  const factory SessionParticipant({
    required String id,
    required String sessionId,
    required String userId,
    required DateTime joinedAt,
    DateTime? leftAt,
    @JsonKey(name: 'user') SessionParticipantUser? userInfo,
  }) = _SessionParticipant;

  factory SessionParticipant.fromJson(Map<String, dynamic> json) =>
      _$SessionParticipantFromJson(json);
}

@freezed
abstract class SessionParticipantUser with _$SessionParticipantUser {
  const factory SessionParticipantUser({
    required String id,
    required String name,
    String? phone,
    String? email,
  }) = _SessionParticipantUser;

  factory SessionParticipantUser.fromJson(Map<String, dynamic> json) =>
      _$SessionParticipantUserFromJson(json);
}
