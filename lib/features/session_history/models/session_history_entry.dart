class SessionHistoryEntry {
  final String id;
  final String roomId;
  final String roomName;
  final DateTime joinedAt;
  final DateTime? leftAt;

  const SessionHistoryEntry({
    required this.id,
    required this.roomId,
    required this.roomName,
    required this.joinedAt,
    this.leftAt,
  });

  Duration? get duration => leftAt?.difference(joinedAt);

  SessionHistoryEntry copyWith({DateTime? leftAt}) => SessionHistoryEntry(
    id: id,
    roomId: roomId,
    roomName: roomName,
    joinedAt: joinedAt,
    leftAt: leftAt ?? this.leftAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'roomId': roomId,
    'roomName': roomName,
    'joinedAt': joinedAt.toIso8601String(),
    'leftAt': leftAt?.toIso8601String(),
  };

  factory SessionHistoryEntry.fromJson(Map<String, dynamic> json) =>
      SessionHistoryEntry(
        id: json['id'] as String,
        roomId: json['roomId'] as String,
        roomName: json['roomName'] as String,
        joinedAt: DateTime.parse(json['joinedAt'] as String),
        leftAt: json['leftAt'] == null
            ? null
            : DateTime.parse(json['leftAt'] as String),
      );
}
