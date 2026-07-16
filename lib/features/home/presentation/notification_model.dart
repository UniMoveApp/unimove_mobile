class NotificationModel {
  final String id;
  final String userId;
  final String type;
  final String message;
  final bool isRead;
  final String? rideId;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.message,
    required this.isRead,
    this.rideId,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      type: json['type'] as String,
      message: json['message'] as String,
      isRead: (json['isRead'] ?? json['read']) as bool? ?? false,
      rideId: json['rideId'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? type,
    String? message,
    bool? isRead,
    String? rideId,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      message: message ?? this.message,
      isRead: isRead ?? this.isRead,
      rideId: rideId ?? this.rideId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
