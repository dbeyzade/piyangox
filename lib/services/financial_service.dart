import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/financial.dart';
import '../models/ticket.dart';
import 'campaign_service.dart';

class FinancialService {
  static final FinancialService _instance = FinancialService._internal();
  factory FinancialService() => _instance;
  FinancialService._internal() {
    _loadData(); // Uygulama başlarken verileri yükle
  }

  final List<FinancialTransaction> _transactions = [];
  final CampaignService _campaignService = CampaignService();

  List<FinancialTransaction> get allTransactions => List.unmodifiable(_transactions);
  List<FinancialTransaction> get incomes => 
      _transactions.where((t) => t.type == TransactionType.income).toList();
  List<FinancialTransaction> get expenses => 
      _transactions.where((t) => t.type == TransactionType.expense).toList();

  // Gelir ekle
  Future<bool> addIncome({
    required String description,
    required double amount,
    String? category,
    String? campaignId,
  }) async {
    try {
      final transaction = FinancialTransaction(
        id: 'income_${DateTime.now().millisecondsSinceEpoch}',
        description: description,
        amount: amount,
        type: TransactionType.income,
        date: DateTime.now(),
        category: category,
        campaignId: campaignId,
      );

      _transactions.add(transaction);
      await _saveData(); // Kalıcı olarak kaydet
      return true;
    } catch (e) {
      return false;
    }
  }

  // Gider ekle
  Future<bool> addExpense({
    required String description,
    required double amount,
    DateTime? date,
    String? category,
    String? campaignId,
  }) async {
    try {
      final transaction = FinancialTransaction(
        id: 'expense_${DateTime.now().millisecondsSinceEpoch}',
        description: description,
        amount: amount,
        type: TransactionType.expense,
        date: date ?? DateTime.now(),
        category: category,
        campaignId: campaignId,
      );

      _transactions.add(transaction);
      await _saveData(); // Kalıcı olarak kaydet
      return true;
    } catch (e) {
      return false;
    }
  }

  // İşlem sil
  Future<bool> deleteTransaction(String transactionId) async {
    try {
      _transactions.removeWhere((t) => t.id == transactionId);
      await _saveData(); // Kalıcı olarak kaydet
      return true;
    } catch (e) {
      return false;
    }
  }

  // Bilet satışından otomatik gelir ekle
  Future<void> addTicketSaleIncome(Ticket ticket) async {
    final campaign = _campaignService.getCampaign(ticket.campaignId);
    if (campaign != null) {
      await addIncome(
        description: 'Bilet Satışı - ${campaign.name}',
        amount: ticket.price,
        category: 'Bilet Satışı',
        campaignId: campaign.id,
      );
    }
  }

  // Finansal özet hesapla
  FinancialSummary calculateSummary([String? campaignId]) {
    var transactions = _transactions;
    
    if (campaignId != null) {
      transactions = transactions.where((t) => t.campaignId == campaignId).toList();
    }

    final totalIncome = transactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);

    final totalExpense = transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);

    // Bilet istatistikleri
    var allTickets = <Ticket>[];
    if (campaignId != null) {
      allTickets = _campaignService.getCampaignTickets(campaignId);
    } else {
      // Tüm kampanyalardan tüm biletler
      for (final campaign in _campaignService.campaigns) {
        allTickets.addAll(_campaignService.getCampaignTickets(campaign.id));
      }
    }

    final soldTickets = allTickets.where((t) => 
        t.status == TicketStatus.sold || t.status == TicketStatus.paid
    ).length;
    
    final availableTickets = allTickets.where((t) => 
        t.status == TicketStatus.available
    ).length;

    final poolAmount = allTickets
        .where((t) => t.status == TicketStatus.sold || t.status == TicketStatus.paid)
        .fold(0.0, (sum, t) => sum + t.price);

    return FinancialSummary(
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      soldTickets: soldTickets,
      availableTickets: availableTickets,
      poolAmount: poolAmount,
    );
  }

  // Kampanya bazlı finansal özet
  Map<String, FinancialSummary> getCampaignSummaries() {
    final summaries = <String, FinancialSummary>{};
    
    for (final campaign in _campaignService.campaigns) {
      summaries[campaign.id] = calculateSummary(campaign.id);
    }
    
    return summaries;
  }

  // Tarih aralığına göre işlemler
  List<FinancialTransaction> getTransactionsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) {
    return _transactions.where((t) => 
        t.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
        t.date.isBefore(endDate.add(const Duration(days: 1)))
    ).toList();
  }

  // Kategoriye göre işlemler
  List<FinancialTransaction> getTransactionsByCategory(String category) {
    return _transactions.where((t) => t.category == category).toList();
  }

  // En çok kullanılan kategoriler
  List<String> getTopCategories([int limit = 5]) {
    final categoryTotals = <String, double>{};
    
    for (final transaction in _transactions) {
      if (transaction.category != null) {
        categoryTotals[transaction.category!] = 
            (categoryTotals[transaction.category!] ?? 0) + transaction.amount;
      }
    }

    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedCategories
        .take(limit)
        .map((e) => e.key)
        .toList();
  }

  // Aylık finansal rapor
  Map<String, FinancialSummary> getMonthlyReport(int year) {
    final monthlyData = <String, FinancialSummary>{};
    
    for (int month = 1; month <= 12; month++) {
      final monthStart = DateTime(year, month, 1);
      final monthEnd = DateTime(year, month + 1, 0);
      
      final monthTransactions = getTransactionsByDateRange(monthStart, monthEnd);
      
      final totalIncome = monthTransactions
          .where((t) => t.type == TransactionType.income)
          .fold(0.0, (sum, t) => sum + t.amount);

      final totalExpense = monthTransactions
          .where((t) => t.type == TransactionType.expense)
          .fold(0.0, (sum, t) => sum + t.amount);

      monthlyData['$year-${month.toString().padLeft(2, '0')}'] = FinancialSummary(
        totalIncome: totalIncome,
        totalExpense: totalExpense,
        soldTickets: 0,
        availableTickets: 0,
        poolAmount: 0,
      );
    }
    
    return monthlyData;
  }

  // 💾 GİDERLERİ KALICI OLARAK SAKLA
  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final transactionsJson = _transactions.map((t) => t.toJson()).toList();
      await prefs.setString('financial_transactions', jsonEncode(transactionsJson));
      print('💾 GİDERLER KAYDEDİLDİ: ${_transactions.length} işlem');
    } catch (e) {
      print('❌ Gider kaydetme hatası: $e');
    }
  }

  // 📂 GİDERLERİ GERİ YÜKLE
  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final transactionsStr = prefs.getString('financial_transactions');
      if (transactionsStr != null) {
        final transactionsJson = jsonDecode(transactionsStr) as List;
        _transactions.clear();
        _transactions.addAll(transactionsJson.map((json) => FinancialTransaction.fromJson(json)));
      }
      print('📂 GİDERLER YÜKLENDİ: ${_transactions.length} işlem');
    } catch (e) {
      print('❌ Gider yükleme hatası: $e');
    }
  }
}
