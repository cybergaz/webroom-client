class MyRecording {
  final String id;
  final String roomId;
  final String roomName;
  final String sessionId;
  final int durationMs;
  final int fileSizeBytes;
  final DateTime createdAt;

  const MyRecording({
    required this.id,
    required this.roomId,
    required this.roomName,
    required this.sessionId,
    required this.durationMs,
    required this.fileSizeBytes,
    required this.createdAt,
  });

  factory MyRecording.fromJson(Map<String, dynamic> json) => MyRecording(
        id: json['id'] as String,
        roomId: json['roomId'] as String,
        roomName: json['roomName'] as String,
        sessionId: json['sessionId'] as String,
        durationMs: json['durationMs'] as int,
        fileSizeBytes: json['fileSizeBytes'] as int,
        createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
      );
}
