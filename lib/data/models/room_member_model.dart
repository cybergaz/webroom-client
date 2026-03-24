import 'package:freezed_annotation/freezed_annotation.dart';

part 'room_member_model.freezed.dart';
part 'room_member_model.g.dart';

@freezed
abstract class RoomMemberModel with _$RoomMemberModel {
  const factory RoomMemberModel({
    @JsonKey(name: 'id') required String userId,
    required String name,
    required String role,
    @Default(false) bool isMuted,
    @JsonKey(name: 'addedAt') DateTime? joinedAt,
    String? phone,
    String? email,
  }) = _RoomMemberModel;

  factory RoomMemberModel.fromJson(Map<String, dynamic> json) =>
      _$RoomMemberModelFromJson(json);
}
