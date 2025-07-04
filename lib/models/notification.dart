enum NotificationType { ticketRequest, general }
enum NotificationStatus { pending, approved, rejected }

class Notification {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final NotificationStatus status;
  final String fromUserId;
  final String fromUserName;
  final String? ticketId;
  final DateTime createdAt;
  final DateTime? processedAt;

  Notification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.status = NotificationStatus.pending,
    required this.fromUserId,
    required this.fromUserName,
    this.ticketId,
    required this.createdAt,
    this.processedAt,
  });

  String get statusText {
    switch (status) {
      case NotificationStatus.pending:
        return 'Bekliyor';
      case NotificationStatus.approved:
        return 'Onaylandı';
      case NotificationStatus.rejected:
        return 'Reddedildi';
    }
  }

  String get statusEmoji {
    switch (status) {
      case NotificationStatus.pending:
        return '⏳';
      case NotificationStatus.approved:
        return '✅';
      case NotificationStatus.rejected:
        return '❌';
    }
  }

  int get statusColor {
    switch (status) {
      case NotificationStatus.pending:
        return 0xFFFF9800; // Turuncu
      case NotificationStatus.approved:
        return 0xFF4CAF50; // Yeşil
      case NotificationStatus.rejected:
        return 0xFFF44336; // Kırmızı
    }
  }

  String get typeEmoji {
    switch (type) {
      case NotificationType.ticketRequest:
        return '🎫';
      case NotificationType.general:
        return '📢';
    }
  }

  bool get isPending => status == NotificationStatus.pending;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type.toString(),
      'status': status.toString(),
      'fromUserId': fromUserId,
      'fromUserName': fromUserName,
      'ticketId': ticketId,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'processedAt': processedAt?.millisecondsSinceEpoch,
    };
  }

  factory Notification.fromMap(Map<String, dynamic> map) {
    return Notification(
      id: map['id'],
      title: map['title'],
      message: map['message'],
      type: NotificationType.values.firstWhere(
        (e) => e.toString() == map['type'],
      ),
      status: NotificationStatus.values.firstWhere(
        (e) => e.toString() == map['status'],
      ),
      fromUserId: map['fromUserId'],
      fromUserName: map['fromUserName'],
      ticketId: map['ticketId'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      processedAt: map['processedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['processedAt'])
          : null,
    );
  }

  Notification copyWith({
    String? id,
    String? title,
    String? message,
    NotificationType? type,
    NotificationStatus? status,
    String? fromUserId,
    String? fromUserName,
    String? ticketId,
    DateTime? createdAt,
    DateTime? processedAt,
  }) {
    return Notification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      status: status ?? this.status,
      fromUserId: fromUserId ?? this.fromUserId,
      fromUserName: fromUserName ?? this.fromUserName,
      ticketId: ticketId ?? this.ticketId,
      createdAt: createdAt ?? this.createdAt,
      processedAt: processedAt ?? this.processedAt,
    );
  }
}
