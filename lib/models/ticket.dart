enum TicketStatus {
  available,
  sold,
  paid,
  cancelled,
  winner,
  unpaid // Ödenmemiş biletler için
}

class Ticket {
  final String id;
  final String campaignId;
  final List<String> numbers; // Şans numaraları
  final double price;
  TicketStatus status; // final kaldırıldı
  final String? buyerName;
  final String? buyerPhone;
  final DateTime? soldAt;
  final DateTime? paidAt;
  final DateTime createdAt;

  // Kullanıcı kimliği
  final String? userId; // Bileti oluşturan kullanıcının ID'si

  // Kazanan bilgileri
  bool isWinner; // final kaldırıldı
  final String? winnerType; // 'main', 'upper', 'lower'
  final double? winAmount;

  // Otomatik iptal sistemi için
  final DateTime? drawDate; // Çekiliş tarihi
  final bool autoCancel; // Otomatik iptal etkin mi?

  Ticket({
    required this.id,
    required this.campaignId,
    required this.numbers,
    required this.price,
    this.status = TicketStatus.available,
    this.buyerName,
    this.buyerPhone,
    this.soldAt,
    this.paidAt,
    required this.createdAt,
    this.userId,
    this.isWinner = false,
    this.winnerType,
    this.winAmount,
    this.drawDate,
    this.autoCancel = true, // Varsayılan olarak otomatik iptal etkin
  });

  // Compat için number getter
  String get number => numbers.isNotEmpty ? numbers[0] : '';

  String get numbersFormatted => numbers.join('  ');

  String get statusText {
    switch (status) {
      case TicketStatus.available:
        return 'Müsait';
      case TicketStatus.sold:
        return 'Satıldı';
      case TicketStatus.unpaid:
        return 'Ödenmedi';
      case TicketStatus.paid:
        return 'Ödendi';
      case TicketStatus.cancelled:
        return 'İptal';
      case TicketStatus.winner:
        return 'Kazandı';
    }
  }

  int get statusColor {
    switch (status) {
      case TicketStatus.available:
        return 0xFFE0E0E0; // Gri
      case TicketStatus.sold:
        return 0xFFFFEB3B; // Sarı-kırmızı karışım
      case TicketStatus.unpaid:
        return 0xFFFF9800; // Turuncu
      case TicketStatus.paid:
        return 0xFF4CAF50; // Yeşil
      case TicketStatus.cancelled:
        return 0xFFF44336; // Kırmızı
      case TicketStatus.winner:
        return 0xFFFFD700; // Altın
    }
  }

  String get statusEmoji {
    switch (status) {
      case TicketStatus.available:
        return '🎫';
      case TicketStatus.sold:
        return '🟨';
      case TicketStatus.unpaid:
        return '⏰';
      case TicketStatus.paid:
        return '✅';
      case TicketStatus.cancelled:
        return '❌';
      case TicketStatus.winner:
        return '🏆';
    }
  }

  // Çekiliş saatine kalan süreyi hesapla
  Duration? get timeUntilDraw {
    if (drawDate == null) return null;

    final now = DateTime.now();
    final drawTime = DateTime(
      drawDate!.year,
      drawDate!.month,
      drawDate!.day,
      21, // Milli Piyango çekiliş saati: 21:15
      15,
    );

    if (now.isAfter(drawTime)) return null;
    return drawTime.difference(now);
  }

  // Bilet otomatik iptal edilmeli mi?
  bool get shouldAutoCancel {
    if (!autoCancel || status != TicketStatus.unpaid) return false;

    final remaining = timeUntilDraw;
    if (remaining == null) return false;

    // Çekilişe 1 saat kala iptal et
    return remaining.inHours <= 1;
  }

  // Çekiliş tarihi formatlanmış string
  String get drawDateFormatted {
    if (drawDate == null) return '';
    return '${drawDate!.day}/${drawDate!.month}/${drawDate!.year} 21:15';
  }

  // Kalan süre formatlanmış string
  String get timeUntilDrawFormatted {
    final remaining = timeUntilDraw;
    if (remaining == null) return 'Çekiliş geçti';

    if (remaining.inDays > 0) {
      return '${remaining.inDays} gün ${remaining.inHours % 24} saat';
    } else if (remaining.inHours > 0) {
      return '${remaining.inHours} saat ${remaining.inMinutes % 60} dk';
    } else {
      return '${remaining.inMinutes} dakika';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'campaignId': campaignId,
      'numbers': numbers,
      'price': price,
      'status': status.toString(),
      'buyerName': buyerName,
      'buyerPhone': buyerPhone,
      'soldAt': soldAt?.toIso8601String(),
      'paidAt': paidAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'user_id': userId,
      'isWinner': isWinner,
      'winnerType': winnerType,
      'winAmount': winAmount,
      'drawDate': drawDate?.toIso8601String(),
      'autoCancel': autoCancel,
    };
  }

  factory Ticket.fromMap(Map<String, dynamic> map) {
    return Ticket(
      id: map['id'],
      campaignId: map['campaignId'] ?? '',
      numbers: map['numbers'] != null
          ? List<String>.from(map['numbers'])
          : <String>[],
      price: map['price']?.toDouble() ?? 0.0,
      status: TicketStatus.values.firstWhere(
        (e) => e.toString() == map['status'],
        orElse: () => TicketStatus.available,
      ),
      buyerName: map['buyerName'],
      buyerPhone: map['buyerPhone'],
      soldAt: map['soldAt'] != null ? DateTime.tryParse(map['soldAt']) : null,
      paidAt: map['paidAt'] != null ? DateTime.tryParse(map['paidAt']) : null,
      createdAt: DateTime.tryParse(map['createdAt']) ?? DateTime.now(),
      userId: map['user_id'],
      isWinner: map['isWinner'] ?? false,
      winnerType: map['winnerType'],
      winAmount: map['winAmount']?.toDouble(),
      drawDate:
          map['drawDate'] != null ? DateTime.tryParse(map['drawDate']) : null,
      autoCancel: map['autoCancel'] ?? true,
    );
  }

  // JSON serialization için
  Map<String, dynamic> toJson() => toMap();
  factory Ticket.fromJson(Map<String, dynamic> json) => Ticket.fromMap(json);

  Ticket copyWith({
    String? id,
    String? campaignId,
    List<String>? numbers,
    double? price,
    TicketStatus? status,
    String? buyerName,
    String? buyerPhone,
    DateTime? soldAt,
    DateTime? paidAt,
    DateTime? createdAt,
    String? userId,
    bool? isWinner,
    String? winnerType,
    double? winAmount,
    DateTime? drawDate,
    bool? autoCancel,
  }) {
    return Ticket(
      id: id ?? this.id,
      campaignId: campaignId ?? this.campaignId,
      numbers: numbers ?? this.numbers,
      price: price ?? this.price,
      status: status ?? this.status,
      buyerName: buyerName ?? this.buyerName,
      buyerPhone: buyerPhone ?? this.buyerPhone,
      soldAt: soldAt ?? this.soldAt,
      paidAt: paidAt ?? this.paidAt,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
      isWinner: isWinner ?? this.isWinner,
      winnerType: winnerType ?? this.winnerType,
      winAmount: winAmount ?? this.winAmount,
      drawDate: drawDate ?? this.drawDate,
      autoCancel: autoCancel ?? this.autoCancel,
    );
  }
}
