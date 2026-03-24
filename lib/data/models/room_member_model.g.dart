// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'room_member_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RoomMemberModel _$RoomMemberModelFromJson(Map<String, dynamic> json) =>
    _RoomMemberModel(
      userId: json['id'] as String,
      name: json['name'] as String,
      role: json['role'] as String,
      isMuted: json['isMuted'] as bool? ?? false,
      joinedAt: json['addedAt'] == null
          ? null
          : DateTime.parse(json['addedAt'] as String),
      phone: json['phone'] as String?,
      email: json['email'] as String?,
    );

Map<String, dynamic> _$RoomMemberModelToJson(_RoomMemberModel instance) =>
    <String, dynamic>{
      'id': instance.userId,
      'name': instance.name,
      'role': instance.role,
      'isMuted': instance.isMuted,
      'addedAt': instance.joinedAt?.toIso8601String(),
      'phone': instance.phone,
      'email': instance.email,
    };
