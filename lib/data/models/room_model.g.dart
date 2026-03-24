// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'room_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RoomModel _$RoomModelFromJson(Map<String, dynamic> json) => _RoomModel(
  roomId: json['id'] as String,
  name: json['name'] as String,
  status: $enumDecode(_$RoomStatusEnumMap, json['status']),
  memberCount: (json['memberCount'] as num?)?.toInt() ?? 0,
  createdBy: json['createdBy'] as String? ?? '',
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  getstreamCallId: json['getstreamCallId'] as String,
  description: json['description'] as String?,
  hostId: json['hostId'] as String?,
);

Map<String, dynamic> _$RoomModelToJson(_RoomModel instance) =>
    <String, dynamic>{
      'id': instance.roomId,
      'name': instance.name,
      'status': _$RoomStatusEnumMap[instance.status]!,
      'memberCount': instance.memberCount,
      'createdBy': instance.createdBy,
      'createdAt': instance.createdAt?.toIso8601String(),
      'getstreamCallId': instance.getstreamCallId,
      'description': instance.description,
      'hostId': instance.hostId,
    };

const _$RoomStatusEnumMap = {
  RoomStatus.active: 'active',
  RoomStatus.inactive: 'inactive',
  RoomStatus.live: 'live',
  RoomStatus.ended: 'ended',
};
