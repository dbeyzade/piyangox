import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ticket.dart';

class LocalStorageService {
  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;
  LocalStorageService._internal();

  static const String _keyDrawDate = 'draw_date';
  static const String _keyTicketCount = 'ticket_count';
  static const String _keyCampaignName = 'campaign_name';
  static const String _keyPrizeType = 'prize_type';
  static const String _keyPrizeAmount = 'prize_amount';
  static const String _keyTicketPrice = 'ticket_price';
  static const String _keyTickets = 'tickets';
  static const String _keySelectedMenuItem = 'selected_menu_item';

  // Çekiliş tarihi
  Future<void> saveDrawDate(DateTime? date) async {
    final prefs = await SharedPreferences.getInstance();
    if (date != null) {
      await prefs.setString(_keyDrawDate, date.toIso8601String());
    } else {
      await prefs.remove(_keyDrawDate);
    }
  }

  Future<DateTime?> getDrawDate() async {
    final prefs = await SharedPreferences.getInstance();
    final dateStr = prefs.getString(_keyDrawDate);
    if (dateStr != null) {
      return DateTime.parse(dateStr);
    }
    return null;
  }

  // Bilet sayısı
  Future<void> saveTicketCount(int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyTicketCount, count);
    print('💾 Bilet sayısı kaydedildi: $count');
  }

  Future<int> getTicketCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyTicketCount) ?? 100;
  }

  // Kampanya adı
  Future<void> saveCampaignName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCampaignName, name);
    print('💾 Kampanya adı kaydedildi: $name');
  }

  Future<String?> getCampaignName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyCampaignName);
  }

  // İkramiye cinsi
  Future<void> savePrizeType(String type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPrizeType, type);
    print('💾 İkramiye cinsi kaydedildi: $type');
  }

  Future<String?> getPrizeType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyPrizeType);
  }

  // İkramiye miktarı
  Future<void> savePrizeAmount(String amount) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPrizeAmount, amount);
    print('💾 İkramiye miktarı kaydedildi: $amount');
  }

  Future<String?> getPrizeAmount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyPrizeAmount);
  }

  // Bilet fiyatı
  Future<void> saveTicketPrice(String price) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTicketPrice, price);
    print('💾 Bilet fiyatı kaydedildi: $price');
  }

  Future<String?> getTicketPrice() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyTicketPrice);
  }

  // Biletler
  Future<void> saveTickets(List<Ticket> tickets) async {
    final prefs = await SharedPreferences.getInstance();
    final ticketsJson = tickets.map((t) => {
      'id': t.id,
      'numbers': t.numbers,
      'campaignId': t.campaignId,
      'status': t.status.index,
      'buyerName': t.buyerName,
      'buyerPhone': t.buyerPhone,
      'soldAt': t.soldAt?.toIso8601String(),
      'paidAt': t.paidAt?.toIso8601String(),
              'ticket_price': t.price,
      'createdAt': t.createdAt.toIso8601String(),
    }).toList();
    
    await prefs.setString(_keyTickets, jsonEncode(ticketsJson));
    print('💾 ${tickets.length} bilet kaydedildi');
  }

  Future<List<Ticket>> getTickets() async {
    final prefs = await SharedPreferences.getInstance();
    final ticketsStr = prefs.getString(_keyTickets);
    
    if (ticketsStr != null) {
      final ticketsJson = jsonDecode(ticketsStr) as List;
      final tickets = ticketsJson.map((json) {
        return Ticket(
          id: json['id'],
          numbers: json['numbers'],
          campaignId: json['campaignId'],
          status: TicketStatus.values[json['status']],
          buyerName: json['buyerName'],
          buyerPhone: json['buyerPhone'],
          soldAt: json['soldAt'] != null ? DateTime.parse(json['soldAt']) : null,
          paidAt: json['paidAt'] != null ? DateTime.parse(json['paidAt']) : null,
          price: json['price'].toDouble(),
          createdAt: DateTime.parse(json['createdAt']),
        );
      }).toList();
      
      print('💾 ${tickets.length} bilet yüklendi');
      return tickets;
    }
    
    return [];
  }

  // Tüm verileri temizle
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyDrawDate);
    await prefs.remove(_keyTicketCount);
    await prefs.remove(_keyCampaignName);
    await prefs.remove(_keyPrizeType);
    await prefs.remove(_keyPrizeAmount);
    await prefs.remove(_keyTicketPrice);
    await prefs.remove(_keyTickets);
    print('💾 Tüm veriler temizlendi');
  }

  // Biletleri temizle
  Future<void> clearTickets() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyTickets);
    print('💾 Biletler temizlendi');
  }

  // Ayarlar tamamlandı mı?
  Future<bool> isSettingsComplete() async {
    final drawDate = await getDrawDate();
    final ticketCount = await getTicketCount();
    final campaignName = await getCampaignName();
    final prizeAmount = await getPrizeAmount();
    final ticketPrice = await getTicketPrice();
    
    return drawDate != null &&
           ticketCount > 0 &&
           campaignName != null && campaignName.isNotEmpty &&
           prizeAmount != null && prizeAmount.isNotEmpty &&
           ticketPrice != null && ticketPrice.isNotEmpty;
  }
  
  // Seçili menü öğesi
  Future<void> saveSelectedMenuItem(String menuItem) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySelectedMenuItem, menuItem);
  }

  Future<String?> getSelectedMenuItem() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keySelectedMenuItem);
  }
} 