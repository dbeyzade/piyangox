enum ComplaintStatus { pending, read, resolved }

class Complaint {
  final String id;
  final String message;
  final String senderName;
  final String? senderPhone;
  final ComplaintStatus status;
  final DateTime createdAt;
  final DateTime? readAt;
  final DateTime? resolvedAt;
  final String? adminResponse;

  Complaint({
    required this.id,
    required this.message,
    required this.senderName,
    this.senderPhone,
    this.status = ComplaintStatus.pending,
    required this.createdAt,
    this.readAt,
    this.resolvedAt,
    this.adminResponse,
  });

  String get statusText {
    switch (status) {
      case ComplaintStatus.pending:
        return 'Bekliyor';
      case ComplaintStatus.read:
        return 'Okundu';
      case ComplaintStatus.resolved:
        return 'Çözüldü';
    }
  }

  String get statusEmoji {
    switch (status) {
      case ComplaintStatus.pending:
        return '🔔';
      case ComplaintStatus.read:
        return '👀';
      case ComplaintStatus.resolved:
        return '✅';
    }
  }

  int get statusColor {
    switch (status) {
      case ComplaintStatus.pending:
        return 0xFFFF9800; // Turuncu
      case ComplaintStatus.read:
        return 0xFF2196F3; // Mavi
      case ComplaintStatus.resolved:
        return 0xFF4CAF50; // Yeşil
    }
  }

  bool get isNew => status == ComplaintStatus.pending;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'message': message,
      'senderName': senderName,
      'senderPhone': senderPhone,
      'status': status.toString(),
      'createdAt': createdAt.millisecondsSinceEpoch,
      'readAt': readAt?.millisecondsSinceEpoch,
      'resolvedAt': resolvedAt?.millisecondsSinceEpoch,
      'adminResponse': adminResponse,
    };
  }

  factory Complaint.fromMap(Map<String, dynamic> map) {
    return Complaint(
      id: map['id'],
      message: map['message'],
      senderName: map['senderName'],
      senderPhone: map['senderPhone'],
      status: ComplaintStatus.values.firstWhere(
        (e) => e.toString() == map['status'],
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      readAt: map['readAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['readAt'])
          : null,
      resolvedAt: map['resolvedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['resolvedAt'])
          : null,
      adminResponse: map['adminResponse'],
    );
  }

  // JSON serialization için
  Map<String, dynamic> toJson() => toMap();
  factory Complaint.fromJson(Map<String, dynamic> json) => Complaint.fromMap(json);

  Complaint copyWith({
    String? id,
    String? message,
    String? senderName,
    String? senderPhone,
    ComplaintStatus? status,
    DateTime? createdAt,
    DateTime? readAt,
    DateTime? resolvedAt,
    String? adminResponse,
  }) {
    return Complaint(
      id: id ?? this.id,
      message: message ?? this.message,
      senderName: senderName ?? this.senderName,
      senderPhone: senderPhone ?? this.senderPhone,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      adminResponse: adminResponse ?? this.adminResponse,
    );
  }
}
