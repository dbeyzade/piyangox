enum PrizeCurrency { tl, dolar, euro, altin, other }

class Partner {
  final String id;
  final String name;
  final String phone;
  final double percentage;
  final String? info;

  Partner({
    required this.id,
    required this.name,
    required this.phone,
    required this.percentage,
    this.info,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'percentage': percentage,
      'info': info,
    };
  }

  factory Partner.fromMap(Map<String, dynamic> map) {
    return Partner(
      id: map['id'],
      name: map['name'],
      phone: map['phone'],
      percentage: map['percentage']?.toDouble() ?? 0.0,
      info: map['info'],
    );
  }

  // JSON serialization için
  Map<String, dynamic> toJson() => toMap();
  factory Partner.fromJson(Map<String, dynamic> json) => Partner.fromMap(json);

  Partner copyWith({
    String? id,
    String? name,
    String? phone,
    double? percentage,
    String? info,
  }) {
    return Partner(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      percentage: percentage ?? this.percentage,
      info: info ?? this.info,
    );
  }
}

class Campaign {
  final String id;
  final String name;
  final int lastDigitCount; // Son hane sayısı (1-4)
  final int chanceCount; // Şans adeti (1-6)
  final int ticketCount; // Bilet adeti
  final PrizeCurrency prizeCurrency;
  final String? customCurrency; // Diğer para birimi
  final String prizeAmount; // İkramiye tutarı (artık string olarak kabul eder)
  final String lowerPrize; // Bir alt değer (artık string olarak kabul eder)
  final String upperPrize; // Bir üst değer (artık string olarak kabul eder)
  final double ticketPrice; // Bilet fiyatı
  final int weekNumber; // Kaçıncı hafta
  final DateTime drawDate; // Çekiliş tarihi
  final DateTime salesEndDate; // Satış bitiş tarihi (çekilişten 1 saat önce)
  final List<Partner> partners; // Ortaklar
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? winningNumber; // Kazanan numara
  bool isCompleted; // Çekiliş tamamlandı mı

  Campaign({
    required this.id,
    required this.name,
    required this.lastDigitCount,
    required this.chanceCount,
    required this.ticketCount,
    required this.prizeCurrency,
    this.customCurrency,
    required this.prizeAmount,
    required this.lowerPrize,
    required this.upperPrize,
    required this.ticketPrice,
    required this.weekNumber,
    required this.drawDate,
    DateTime? salesEndDate,
    this.partners = const [],
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
    this.winningNumber,
    this.isCompleted = false,
  }) : salesEndDate = salesEndDate ?? drawDate.subtract(const Duration(hours: 1));

  String get prizeAmountFormatted {
    String symbol = _getCurrencySymbol();
    // Artık prizeAmount string olduğu için direkt kullan
    if (symbol.isNotEmpty) {
      return prizeAmount;
    } else {
      return prizeAmount;
    }
  }

  String get upperPrizeFormatted {
    String symbol = _getCurrencySymbol();
    if (symbol.isNotEmpty) {
      return upperPrize;
    } else {
      return upperPrize;
    }
  }

  String get lowerPrizeFormatted {
    String symbol = _getCurrencySymbol();
    if (symbol.isNotEmpty) {
      return lowerPrize;
    } else {
      return lowerPrize;
    }
  }

  String _getCurrencySymbol() {
    switch (prizeCurrency) {
      case PrizeCurrency.tl:
        return '₺';
      case PrizeCurrency.dolar:
        return '\$';
      case PrizeCurrency.euro:
        return '€';
      case PrizeCurrency.altin:
        return '🥇';
      case PrizeCurrency.other:
        return customCurrency ?? '';
    }
  }

  String get currencyEmoji {
    switch (prizeCurrency) {
      case PrizeCurrency.tl:
        return '💰';
      case PrizeCurrency.dolar:
        return '💵';
      case PrizeCurrency.euro:
        return '💶';
      case PrizeCurrency.altin:
        return '🥇';
      case PrizeCurrency.other:
        return '💎';
    }
  }

  double get totalPartnerPercentage {
    return partners.fold(0.0, (sum, partner) => sum + partner.percentage);
  }

  bool get hasValidPartnerPercentages {
    return totalPartnerPercentage <= 100.0;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'lastDigitCount': lastDigitCount,
      'chanceCount': chanceCount,
      'ticketCount': ticketCount,
      'prizeCurrency': prizeCurrency.toString(),
      'customCurrency': customCurrency,
      'prizeAmount': prizeAmount,
      'lowerPrize': lowerPrize,
      'upperPrize': upperPrize,
      'ticketPrice': ticketPrice,
      'weekNumber': weekNumber,
      'drawDate': drawDate.millisecondsSinceEpoch,
      'salesEndDate': salesEndDate.millisecondsSinceEpoch,
      'partners': partners.map((p) => p.toMap()).toList(),
      'isActive': isActive,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
      'winningNumber': winningNumber,
      'isCompleted': isCompleted,
    };
  }

  factory Campaign.fromMap(Map<String, dynamic> map) {
    return Campaign(
      id: map['id'],
      name: map['name'],
      lastDigitCount: map['lastDigitCount'],
      chanceCount: map['chanceCount'],
      ticketCount: map['ticketCount'],
      prizeCurrency: PrizeCurrency.values.firstWhere(
        (e) => e.toString() == map['prizeCurrency'],
      ),
      customCurrency: map['customCurrency'],
      prizeAmount: map['prizeAmount']?.toString() ?? '',
      lowerPrize: map['lowerPrize']?.toString() ?? '',
      upperPrize: map['upperPrize']?.toString() ?? '',
      ticketPrice: map['ticketPrice']?.toDouble() ?? 0.0,
      weekNumber: map['weekNumber'],
      drawDate: DateTime.fromMillisecondsSinceEpoch(map['drawDate']),
      salesEndDate: map['salesEndDate'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['salesEndDate'])
          : null,
      partners: (map['partners'] as List?)
          ?.map((p) => Partner.fromMap(p))
          .toList() ?? [],
      isActive: map['isActive'] ?? true,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      updatedAt: map['updatedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'])
          : null,
      winningNumber: map['winningNumber'],
      isCompleted: map['isCompleted'] ?? false,
    );
  }

  // JSON serialization için
  Map<String, dynamic> toJson() => toMap();
  factory Campaign.fromJson(Map<String, dynamic> json) => Campaign.fromMap(json);

  Campaign copyWith({
    String? id,
    String? name,
    int? lastDigitCount,
    int? chanceCount,
    int? ticketCount,
    PrizeCurrency? prizeCurrency,
    String? customCurrency,
    String? prizeAmount,
    String? lowerPrize,
    String? upperPrize,
    double? ticketPrice,
    int? weekNumber,
    DateTime? drawDate,
    DateTime? salesEndDate,
    List<Partner>? partners,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? winningNumber,
    bool? isCompleted,
  }) {
    return Campaign(
      id: id ?? this.id,
      name: name ?? this.name,
      lastDigitCount: lastDigitCount ?? this.lastDigitCount,
      chanceCount: chanceCount ?? this.chanceCount,
      ticketCount: ticketCount ?? this.ticketCount,
      prizeCurrency: prizeCurrency ?? this.prizeCurrency,
      customCurrency: customCurrency ?? this.customCurrency,
      prizeAmount: prizeAmount ?? this.prizeAmount,
      lowerPrize: lowerPrize ?? this.lowerPrize,
      upperPrize: upperPrize ?? this.upperPrize,
      ticketPrice: ticketPrice ?? this.ticketPrice,
      weekNumber: weekNumber ?? this.weekNumber,
      drawDate: drawDate ?? this.drawDate,
      salesEndDate: salesEndDate ?? this.salesEndDate,
      partners: partners ?? this.partners,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      winningNumber: winningNumber ?? this.winningNumber,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
