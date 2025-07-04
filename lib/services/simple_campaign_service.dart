import 'package:piyangox/models/campaign.dart';
import 'package:piyangox/models/ticket.dart';

class SimpleCampaignService {
  static final SimpleCampaignService _instance = SimpleCampaignService._internal();
  factory SimpleCampaignService() => _instance;
  SimpleCampaignService._internal();

  final List<Campaign> _campaigns = [];
  final List<Ticket> _allTickets = [];
  bool _isListPublished = false;

  // Kampanya listesi
  List<Campaign> get campaigns => List.from(_campaigns);

  // Tüm sistem biletleri
  List<Ticket> getAllSystemTickets() => List.from(_allTickets);

  // Kampanya ekleme
  bool addCampaign(Campaign campaign) {
    try {
      _campaigns.add(campaign);
      print('✅ Kampanya RAM\'e eklendi: ${campaign.name}');
      return true;
    } catch (e) {
      print('❌ Kampanya ekleme hatası: $e');
      return false;
    }
  }

  // Kampanya güncelleme
  bool updateCampaign(Campaign campaign) {
    try {
      final index = _campaigns.indexWhere((c) => c.id == campaign.id);
      if (index != -1) {
        _campaigns[index] = campaign;
        print('✅ Kampanya güncellendi: ${campaign.name}');
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Kampanya güncelleme hatası: $e');
      return false;
    }
  }

  // Kampanya silme
  bool deleteCampaign(String campaignId) {
    try {
      _campaigns.removeWhere((c) => c.id == campaignId);
      _allTickets.removeWhere((t) => t.campaignId == campaignId);
      print('✅ Kampanya silindi: $campaignId');
      return true;
    } catch (e) {
      print('❌ Kampanya silme hatası: $e');
      return false;
    }
  }

  // Kampanya getirme
  Campaign? getCampaign(String campaignId) {
    try {
      return _campaigns.firstWhere((c) => c.id == campaignId);
    } catch (e) {
      return null;
    }
  }

  // Kampanya biletleri
  List<Ticket> getCampaignTickets(String campaignId) {
    return _allTickets.where((t) => t.campaignId == campaignId).toList();
  }

  // Bilet ekleme
  void addTicket(Ticket ticket) {
    _allTickets.add(ticket);
  }

  // Bilet sisteme ekleme
  void addTicketToSystem(Ticket ticket) {
    _allTickets.add(ticket);
  }

  // Çoklu bilet ekleme
  void addTickets(List<Ticket> tickets) {
    _allTickets.addAll(tickets);
  }

  // Mevcut hafta numarası
  int getCurrentWeekNumber() {
    final now = DateTime.now();
    final startOfYear = DateTime(now.year, 1, 1);
    final difference = now.difference(startOfYear).inDays;
    return (difference / 7).ceil();
  }

  // Çekiliş yapma
  Map<String, dynamic> conductDraw(String campaignId, String winningNumber) {
    final campaignTickets = getCampaignTickets(campaignId);
    final winnerTickets = campaignTickets.where((t) => t.number == winningNumber).toList();
    
    // Biletleri kazanan olarak işaretle
    for (final ticket in winnerTickets) {
      ticket.isWinner = true;
      ticket.status = TicketStatus.winner;
    }

    // Kampanyayı tamamlanmış olarak işaretle
    final campaign = getCampaign(campaignId);
    if (campaign != null) {
      campaign.isCompleted = true;
      updateCampaign(campaign);
    }

    return {
      'success': true,
      'winningNumber': winningNumber,
      'winnerCount': winnerTickets.length,
      'winners': winnerTickets,
    };
  }

  // Bilet istatistikleri
  Map<String, int> getTicketStats(String campaignId) {
    final campaignTickets = getCampaignTickets(campaignId);
    final soldTickets = campaignTickets.where((t) => t.status == TicketStatus.sold).length;
    final availableTickets = campaignTickets.where((t) => t.status == TicketStatus.available).length;
    final winnerTickets = campaignTickets.where((t) => t.isWinner).length;

    return {
      'total': campaignTickets.length,
      'sold': soldTickets,
      'available': availableTickets,
      'winners': winnerTickets,
    };
  }

  // Liste yayınlama durumu
  bool get isListPublished => _isListPublished;

  // Liste yayınlama
  void publishList() {
    _isListPublished = true;
    print('✅ Liste yayınlandı');
  }

  // Liste yayından kaldırma
  void unpublishList() {
    _isListPublished = false;
    print('✅ Liste yayından kaldırıldı');
  }

  // Yayınlanmış biletler
  List<Ticket> getPublishedTickets() {
    return _isListPublished ? List.from(_allTickets) : [];
  }

  // Mevcut biletler
  List<Ticket> getAvailableTickets(String campaignId) {
    return _allTickets.where((t) => t.campaignId == campaignId && t.status == TicketStatus.available).toList();
  }

  // Satılan biletler
  List<Ticket> getSoldTickets(String campaignId) {
    return _allTickets.where((t) => t.campaignId == campaignId && t.status == TicketStatus.sold).toList();
  }

  // Kazanan biletler
  List<Ticket> getWinnerTickets() {
    return _allTickets.where((t) => t.isWinner).toList();
  }

  // Toplam gelir
  double getTotalRevenue() {
    return _allTickets.where((t) => t.status == TicketStatus.sold).fold(0.0, (sum, t) => sum + t.price);
  }

  // Toplam bilet sayısı
  int getTotalTicketCount() {
    return _allTickets.length;
  }

  // Satılan bilet sayısı
  int getSoldTicketCount() {
    return _allTickets.where((t) => t.status == TicketStatus.sold).length;
  }

  // Toplam ödül miktarı
  double getTotalPrizeAmount() {
    return _campaigns.fold(0.0, (sum, c) => sum + (double.tryParse(c.prizeAmount) ?? 0.0));
  }

  // Tüm kampanyaları temizle
  void clearAllCampaigns() {
    _campaigns.clear();
    _allTickets.clear();
    _isListPublished = false;
    print('✅ Tüm veriler temizlendi');
  }

  // Sistem bilet temizleme
  void clearAllSystemTickets() {
    _allTickets.clear();
    print('✅ Tüm sistem biletleri temizlendi');
  }

  // Bilet güncelleme
  void updateTicket(Ticket ticket) {
    final index = _allTickets.indexWhere((t) => t.id == ticket.id);
    if (index != -1) {
      _allTickets[index] = ticket;
      print('✅ Bilet güncellendi: ${ticket.id}');
    }
  }
}
