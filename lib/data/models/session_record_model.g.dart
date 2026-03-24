// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_record_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SessionRecord _$SessionRecordFromJson(Map<String, dynamic> json) =>
    _SessionRecord(
      id: json['id'] as String,
      roomId: json['roomId'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String),
      endedAt: json['endedAt'] == null
          ? null
          : DateTime.parse(json['endedAt'] as String),
      participants:
          (json['participants'] as List<dynamic>?)
              ?.map(
                (e) => SessionParticipant.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
    );

Map<String, dynamic> _$SessionRecordToJson(_SessionRecord instance) =>
    <String, dynamic>{
      'id': instance.id,
      'roomId': instance.roomId,
      'startedAt': instance.startedAt.toIso8601String(),
      'endedAt': instance.endedAt?.toIso8601String(),
      'participants': instance.participants,
    };

_SessionParticipant _$SessionParticipantFromJson(Map<String, dynamic> json) =>
    _SessionParticipant(
      id: json['id'] as String,
      sessionId: json['sessionId'] as String,
      userId: json['userId'] as String,
      joinedAt: DateTime.parse(json['joinedAt'] as String),
      leftAt: json['leftAt'] == null
          ? null
          : DateTime.parse(json['leftAt'] as String),
      userInfo: json['user'] == null
          ? null
          : SessionParticipantUser.fromJson(
              json['user'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$SessionParticipantToJson(_SessionParticipant instance) =>
    <String, dynamic>{
      'id': instance.id,
      'sessionId': instance.sessionId,
      'userId': instance.userId,
      'joinedAt': instance.joinedAt.toIso8601String(),
      'leftAt': instance.leftAt?.toIso8601String(),
      'user': instance.userInfo,
    };

_SessionParticipantUser _$SessionParticipantUserFromJson(
  Map<String, dynamic> json,
) => _SessionParticipantUser(
  id: json['id'] as String,
  name: json['name'] as String,
  phone: json['phone'] as String?,
  email: json['email'] as String?,
);

Map<String, dynamic> _$SessionParticipantUserToJson(
  _SessionParticipantUser instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'phone': instance.phone,
  'email': instance.email,
};
