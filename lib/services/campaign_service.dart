import 'package:piyangox/models/campaign.dart';
import 'package:piyangox/models/ticket.dart';
import 'package:piyangox/services/simple_campaign_service.dart';
import 'package:piyangox/services/supabase_service.dart';
import 'package:piyangox/services/shared_data_service.dart';

class CampaignService {
  // Singleton pattern
  static final CampaignService _instance = CampaignService._internal();
  factory CampaignService() => _instance;
  CampaignService._internal() {
    // Başlangıçta paylaşılan veriyi yükle
    _loadSharedData();
  }

  final SimpleCampaignService _simpleCampaignService = SimpleCampaignService();
  final SupabaseService _supabaseService = SupabaseService();
  final SharedDataService _sharedDataService = SharedDataService();

  // Kampanya listesi - BASİT LİST (Future değil)
  List<Campaign> get campaigns => _simpleCampaignService.campaigns;

  // Tamamlanmış kampanyalar
  List<Campaign> get completedCampaigns => campaigns.where((c) => c.isCompleted).toList();

  // Kampanya ekleme
  Future<bool> addCampaign(Campaign campaign) async {
    final result = _simpleCampaignService.addCampaign(campaign);
    try {
      await _supabaseService.addCampaign(campaign);
    } catch (e) {
      print('⚠️ Supabase hatası: $e');
    }
    
    // Paylaşılan veriyi güncelle
    await _sharedDataService.saveSharedData(
      isListPublished: isListPublished,
      campaigns: campaigns,
      tickets: getAllSystemTickets(),
    );
    
    return result;
  }

  // Kampanya güncelleme
  Future<bool> updateCampaign(Campaign campaign) async {
    final result = _simpleCampaignService.updateCampaign(campaign);
    try {
      await _supabaseService.updateCampaign(campaign);
    } catch (e) {
      print('⚠️ Supabase hatası: $e');
    }
    
    // Paylaşılan veriyi güncelle
    await _sharedDataService.saveSharedData(
      isListPublished: isListPublished,
      campaigns: campaigns,
      tickets: getAllSystemTickets(),
    );
    
    return result;
  }

  // Kampanya silme
  Future<bool> deleteCampaign(String campaignId) async {
    final result = _simpleCampaignService.deleteCampaign(campaignId);
    try {
      await _supabaseService.deleteCampaign(campaignId);
    } catch (e) {
      print('⚠️ Supabase hatası: $e');
    }
    
    // Paylaşılan veriyi güncelle
    await _sharedDataService.saveSharedData(
      isListPublished: isListPublished,
      campaigns: campaigns,
      tickets: getAllSystemTickets(),
    );
    
    return result;
  }

  // Kampanya getirme
  Campaign? getCampaign(String campaignId) {
    return _simpleCampaignService.getCampaign(campaignId);
  }

  // Tüm sistem biletleri
  List<Ticket> getAllSystemTickets() {
    return _simpleCampaignService.getAllSystemTickets();
  }

  // Kampanya biletleri
  List<Ticket> getCampaignTickets(String campaignId) {
    return _simpleCampaignService.getCampaignTickets(campaignId);
  }

  // Bilet ekleme
  void addTicket(Ticket ticket) {
    _simpleCampaignService.addTicket(ticket);
  }

  // Bilet sisteme ekleme
  void addTicketToSystem(Ticket ticket) {
    _simpleCampaignService.addTicketToSystem(ticket);
    // Paylaşılan veriyi güncelle
    _sharedDataService.saveSharedData(
      isListPublished: isListPublished,
      campaigns: campaigns,
      tickets: getAllSystemTickets(),
    );
  }

  // Çoklu bilet ekleme
  void addTickets(List<Ticket> tickets) {
    _simpleCampaignService.addTickets(tickets);
  }

  // Mevcut hafta numarası
  int getCurrentWeekNumber() {
    return _simpleCampaignService.getCurrentWeekNumber();
  }

  // Çekiliş yapma
  Map<String, dynamic> conductDraw(String campaignId, String winningNumber) {
    return _simpleCampaignService.conductDraw(campaignId, winningNumber);
  }

  // Bilet istatistikleri
  Map<String, int> getTicketStats(String campaignId) {
    return _simpleCampaignService.getTicketStats(campaignId);
  }

  // Liste yayınlama durumu
  bool get isListPublished => _simpleCampaignService.isListPublished;

  // Liste yayınlama
  Future<void> publishList() async {
    _simpleCampaignService.publishList();
    // Paylaşılan veriye kaydet
    await _sharedDataService.saveSharedData(
      isListPublished: true,
      campaigns: campaigns,
      tickets: getAllSystemTickets(),
    );
  }

  // Liste yayından kaldırma
  Future<void> unpublishList() async {
    _simpleCampaignService.unpublishList();
    // Paylaşılan veriye kaydet
    await _sharedDataService.saveSharedData(
      isListPublished: false,
      campaigns: campaigns,
      tickets: getAllSystemTickets(),
    );
  }

  // Yayınlanmış biletler
  List<Ticket> getPublishedTickets() {
    return _simpleCampaignService.getPublishedTickets();
  }

  // Mevcut biletler
  List<Ticket> getAvailableTickets(String campaignId) {
    return _simpleCampaignService.getAvailableTickets(campaignId);
  }

  // Satılan biletler
  List<Ticket> getSoldTickets(String campaignId) {
    return _simpleCampaignService.getSoldTickets(campaignId);
  }

  // Kazanan biletler
  List<Ticket> getWinnerTickets() {
    return _simpleCampaignService.getWinnerTickets();
  }

  // Toplam gelir
  double getTotalRevenue() {
    return _simpleCampaignService.getTotalRevenue();
  }

  // Toplam bilet sayısı
  int getTotalTicketCount() {
    return _simpleCampaignService.getTotalTicketCount();
  }

  // Satılan bilet sayısı
  int getSoldTicketCount() {
    return _simpleCampaignService.getSoldTicketCount();
  }

  // Toplam ödül miktarı
  double getTotalPrizeAmount() {
    return _simpleCampaignService.getTotalPrizeAmount();
  }

  // Tüm kampanyaları temizle
  void clearAllCampaigns() {
    _simpleCampaignService.clearAllCampaigns();
  }

  // Sistem bilet temizleme
  void clearAllSystemTickets() {
    _simpleCampaignService.clearAllSystemTickets();
  }

  // Kampanya oluşturma
  Future<bool> createCampaign(Campaign campaign, {bool skipTicketGeneration = false}) async {
    return await addCampaign(campaign);
  }

  // Admin kampanya oluşturma
  Future<bool> createAdminCampaign(Campaign campaign) async {
    final result = await addCampaign(campaign);
    // Admin kampanya oluştururken otomatik olarak liste yayınla
    if (result) {
      await publishList();
    }
    return result;
  }

  // Bilet güncelleme
  void updateTicket(Ticket ticket) {
    _simpleCampaignService.updateTicket(ticket);
  }

  // Senkronizasyon metodu

  // Yayınlanan kampanyaları getir
  List<Campaign> getPublishedCampaigns() {
    if (!isListPublished) {
      return []; // Liste yayınlanmamışsa boş liste döndür
    }
    return campaigns; // Liste yayınlanmışsa tüm kampanyaları döndür
  }

  // Paylaşılan veriyi yükle
  Future<void> _loadSharedData() async {
    try {
      final data = await _sharedDataService.loadSharedData();
      
      // Eğer paylaşılan veri varsa kullan
      if (data['campaigns'] != null && (data['campaigns'] as List).isNotEmpty) {
        final sharedCampaigns = data['campaigns'] as List<Campaign>;
        final sharedTickets = data['tickets'] as List<Ticket>;
        final sharedIsPublished = data['isListPublished'] as bool;
        
        // Veriyi simple service'e aktar
        _simpleCampaignService.clearAllCampaigns();
        for (final campaign in sharedCampaigns) {
          _simpleCampaignService.addCampaign(campaign);
        }
        
        _simpleCampaignService.clearAllSystemTickets();
        for (final ticket in sharedTickets) {
          _simpleCampaignService.addTicketToSystem(ticket);
        }
        
        if (sharedIsPublished) {
          _simpleCampaignService.publishList();
        }
        
        print('✅ Paylaşılan veri yüklendi: ${sharedCampaigns.length} kampanya, ${sharedTickets.length} bilet');
      }
    } catch (e) {
      print('❌ Paylaşılan veri yükleme hatası: $e');
    }
  }

  // Veriyi yenile (bayi tarafında kullanılacak)
  Future<void> refreshFromSharedData() async {
    await _loadSharedData();
  }

  Future<void> syncWithSupabase() async {
    try {
      final localCampaigns = _simpleCampaignService.campaigns;
      for (final campaign in localCampaigns) {
        await _supabaseService.addCampaign(campaign);
      }
      print('✅ Supabase senkronizasyonu tamamlandı');
    } catch (e) {
      print('⚠️ Supabase senkronizasyon hatası: $e');
    }
  }
}
