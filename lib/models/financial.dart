enum TransactionType { income, expense }

class FinancialTransaction {
  final String id;
  final String description;
  final double amount;
  final TransactionType type;
  final DateTime date;
  final String? category;
  final String? campaignId;

  FinancialTransaction({
    required this.id,
    required this.description,
    required this.amount,
    required this.type,
    required this.date,
    this.category,
    this.campaignId,
  });

  String get typeText {
    switch (type) {
      case TransactionType.income:
        return 'Gelir';
      case TransactionType.expense:
        return 'Gider';
    }
  }

  String get typeEmoji {
    switch (type) {
      case TransactionType.income:
        return '💰';
      case TransactionType.expense:
        return '💸';
    }
  }

  int get typeColor {
    switch (type) {
      case TransactionType.income:
        return 0xFF4CAF50; // Yeşil
      case TransactionType.expense:
        return 0xFFF44336; // Kırmızı
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'amount': amount,
      'type': type.toString(),
      'date': date.millisecondsSinceEpoch,
      'category': category,
      'campaignId': campaignId,
    };
  }

  factory FinancialTransaction.fromMap(Map<String, dynamic> map) {
    return FinancialTransaction(
      id: map['id'],
      description: map['description'],
      amount: map['amount']?.toDouble() ?? 0.0,
      type: TransactionType.values.firstWhere(
        (e) => e.toString() == map['type'],
      ),
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      category: map['category'],
      campaignId: map['campaignId'],
    );
  }

  // JSON serialization için
  Map<String, dynamic> toJson() => toMap();
  factory FinancialTransaction.fromJson(Map<String, dynamic> json) => FinancialTransaction.fromMap(json);
}

class FinancialSummary {
  final double totalIncome;
  final double totalExpense;
  final double balance;
  final int soldTickets;
  final int availableTickets;
  final double poolAmount; // Havuz birikimi

  FinancialSummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.soldTickets,
    required this.availableTickets,
    required this.poolAmount,
  }) : balance = totalIncome - totalExpense;

  bool get isProfit => balance > 0;
  
  String get balanceText {
    if (balance > 0) {
      return 'Kar: ${balance.toStringAsFixed(2)} ₺';
    } else if (balance < 0) {
      return 'Zarar: ${(-balance).toStringAsFixed(2)} ₺';
    } else {
      return 'Başabaş: 0 ₺';
    }
  }

  String get balanceEmoji {
    if (balance > 0) {
      return '📈'; // Kar
    } else if (balance < 0) {
      return '📉'; // Zarar
    } else {
      return '⚖️'; // Başabaş
    }
  }

  int get balanceColor {
    if (balance > 0) {
      return 0xFF4CAF50; // Yeşil
    } else if (balance < 0) {
      return 0xFFF44336; // Kırmızı
    } else {
      return 0xFF9E9E9E; // Gri
    }
  }
}
