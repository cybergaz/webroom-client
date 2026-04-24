class ManagedUser {
  final String id;
  final String? requestId;
  final String name;
  final String? phone;
  final String? email;
  final String status;
  final String? deviceName;
  final String? lockedDeviceId;
  final String? lockedDeviceName;
  final bool allowDeviceChange;
  final String? appVersion;
  final DateTime createdAt;
  final DateTime? lastSeenAt;

  const ManagedUser({
    required this.id,
    required this.requestId,
    required this.name,
    required this.phone,
    required this.email,
    required this.status,
    required this.deviceName,
    required this.lockedDeviceId,
    required this.lockedDeviceName,
    required this.allowDeviceChange,
    required this.appVersion,
    required this.createdAt,
    required this.lastSeenAt,
  });

  bool get isActive => status == 'approved';

  factory ManagedUser.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(Object? v) {
      if (v is String && v.isNotEmpty) return DateTime.tryParse(v);
      return null;
    }

    return ManagedUser(
      id: json['id'] as String,
      requestId: json['requestId'] as String?,
      name: (json['name'] as String?) ?? '',
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      status: (json['status'] as String?) ?? 'approved',
      deviceName: json['deviceName'] as String?,
      lockedDeviceId: json['lockedDeviceId'] as String?,
      lockedDeviceName: json['lockedDeviceName'] as String?,
      allowDeviceChange: (json['allowDeviceChange'] as bool?) ?? false,
      appVersion: json['appVersion'] as String?,
      createdAt: parseDate(json['createdAt']) ?? DateTime.now(),
      lastSeenAt: parseDate(json['lastSeenAt']),
    );
  }

  ManagedUser copyWith({
    String? name,
    String? status,
    String? deviceName,
    String? lockedDeviceId,
    String? lockedDeviceName,
    bool? allowDeviceChange,
  }) {
    return ManagedUser(
      id: id,
      requestId: requestId,
      name: name ?? this.name,
      phone: phone,
      email: email,
      status: status ?? this.status,
      deviceName: deviceName ?? this.deviceName,
      lockedDeviceId: lockedDeviceId ?? this.lockedDeviceId,
      lockedDeviceName: lockedDeviceName ?? this.lockedDeviceName,
      allowDeviceChange: allowDeviceChange ?? this.allowDeviceChange,
      appVersion: appVersion,
      createdAt: createdAt,
      lastSeenAt: lastSeenAt,
    );
  }
}
