import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/enums/room_status.dart';

part 'room_model.freezed.dart';
part 'room_model.g.dart';

@freezed
abstract class RoomModel with _$RoomModel {
  const factory RoomModel({
    @JsonKey(name: 'id') required String roomId,
    required String name,
    required RoomStatus status,
    @Default(0) int memberCount,
    @Default('') String createdBy,
    DateTime? createdAt,
    required String getstreamCallId,
    String? description,
    String? hostId,
  }) = _RoomModel;

  factory RoomModel.fromJson(Map<String, dynamic> json) => _$RoomModelFromJson(json);
}
