import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:piyangox/models/campaign.dart';
import 'package:piyangox/models/ticket.dart';
import 'dart:async';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  final SupabaseClient _client = Supabase.instance.client;

  // Realtime stream controllers
  final StreamController<List<Campaign>> _campaignsController =
      StreamController<List<Campaign>>.broadcast();
  final StreamController<List<Ticket>> _ticketsController =
      StreamController<List<Ticket>>.broadcast();
  final StreamController<Map<String, dynamic>> _realtimeEventsController =
      StreamController<Map<String, dynamic>>.broadcast();

  // Realtime subscriptions
  RealtimeChannel? _campaignsSubscription;
  RealtimeChannel? _ticketsSubscription;

  // Getters for streams
  Stream<List<Campaign>> get campaignsStream => _campaignsController.stream;
  Stream<List<Ticket>> get ticketsStream => _ticketsController.stream;
  Stream<Map<String, dynamic>> get realtimeEventsStream =>
      _realtimeEventsController.stream;

  // Supabase Auth ile giriş yapan kullanıcının UUID'si
  String? get currentUserId => _client.auth.currentUser?.id;

  // 🔥 REALTIME BAŞLATMA
  Future<void> initializeRealtime() async {
    try {
      // Kampanya realtime subscription
      _campaignsSubscription = _client
          .channel('campaigns_realtime')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'campaigns',
            callback: (payload) {
              print('🔄 Kampanya değişikliği algılandı: ${payload.eventType}');
              _handleCampaignChange(payload);

              // Tüm cihazlara bildirim gönder
              _realtimeEventsController.add({
                'type': 'campaign_change',
                'event': payload.eventType.name,
                'data': payload.newRecord ?? payload.oldRecord,
                'timestamp': DateTime.now().toIso8601String(),
              });
            },
          )
          .subscribe();

      // Bilet realtime subscription
      _ticketsSubscription = _client
          .channel('tickets_realtime')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'tickets',
            callback: (payload) {
              print('🔄 Bilet değişikliği algılandı: ${payload.eventType}');
              _handleTicketChange(payload);

              // Tüm cihazlara bildirim gönder
              _realtimeEventsController.add({
                'type': 'ticket_change',
                'event': payload.eventType.name,
                'data': payload.newRecord ?? payload.oldRecord,
                'timestamp': DateTime.now().toIso8601String(),
              });
            },
          )
          .subscribe();

      // İlk veri yüklemesi
      await _loadInitialData();

      print('✅ Supabase Realtime başlatıldı');
    } catch (e) {
      print('❌ Realtime başlatma hatası: $e');
    }
  }

  // 🔄 KAMPANYA DEĞİŞİKLİK HANDLER
  void _handleCampaignChange(PostgresChangePayload payload) async {
    try {
      // Güncel kampanya listesini al ve stream'e gönder
      final campaigns = await getCampaigns();
      _campaignsController.add(campaigns);
    } catch (e) {
      print('❌ Kampanya değişiklik handler hatası: $e');
    }
  }

  // 🔄 BİLET DEĞİŞİKLİK HANDLER
  void _handleTicketChange(PostgresChangePayload payload) async {
    try {
      // Güncel bilet listesini al ve stream'e gönder
      final tickets = await getAllTickets();
      _ticketsController.add(tickets);
    } catch (e) {
      print('❌ Bilet değişiklik handler hatası: $e');
    }
  }

  // 📊 İLK VERİ YÜKLEMESI
  Future<void> _loadInitialData() async {
    try {
      final campaigns = await getCampaigns();
      final tickets = await getAllTickets();

      _campaignsController.add(campaigns);
      _ticketsController.add(tickets);

      print('✅ İlk veriler yüklendi');
    } catch (e) {
      print('❌ İlk veri yükleme hatası: $e');
    }
  }

  // 🎯 KAMPANYA İŞLEMLERİ (Realtime özellikli)

  // Kampanya ekleme
  Future<bool> addCampaign(Campaign campaign) async {
    try {
      await _client.from('campaigns').insert(campaign.toJson());
      print('✅ Kampanya Supabase\'e eklendi: ${campaign.name}');

      // Admin işlemini broadcast et
      _broadcastAdminAction('campaign_added', {
        'campaign_name': campaign.name,
        'admin_action': 'Yeni kampanya eklendi',
      });

      return true;
    } catch (e) {
      print('❌ Supabase kampanya ekleme hatası: $e');
      return false;
    }
  }

  // Kampanya güncelleme
  Future<bool> updateCampaign(Campaign campaign) async {
    try {
      await _client
          .from('campaigns')
          .update(campaign.toJson())
          .eq('id', campaign.id);
      print('✅ Kampanya Supabase\'de güncellendi: ${campaign.name}');

      // Admin işlemini broadcast et
      _broadcastAdminAction('campaign_updated', {
        'campaign_name': campaign.name,
        'admin_action': 'Kampanya güncellendi',
      });

      return true;
    } catch (e) {
      print('❌ Supabase kampanya güncelleme hatası: $e');
      return false;
    }
  }

  // Kampanya silme
  Future<bool> deleteCampaign(String campaignId) async {
    try {
      await _client.from('campaigns').delete().eq('id', campaignId);
      await _client.from('tickets').delete().eq('campaign_id', campaignId);
      print('✅ Kampanya Supabase\'den silindi: $campaignId');

      // Admin işlemini broadcast et
      _broadcastAdminAction('campaign_deleted', {
        'campaign_id': campaignId,
        'admin_action': 'Kampanya silindi',
      });

      return true;
    } catch (e) {
      print('❌ Supabase kampanya silme hatası: $e');
      return false;
    }
  }

  // 🎫 BİLET İŞLEMLERİ (Realtime özellikli)

  // Bilet ekleme
  Future<bool> addTicket(Ticket ticket) async {
    try {
      await _client.from('tickets').insert(ticket.toJson());
      print('✅ Bilet Supabase\'e eklendi: ${ticket.number}');

      // Admin işlemini broadcast et
      _broadcastAdminAction('ticket_added', {
        'ticket_number': ticket.number,
        'admin_action': 'Yeni bilet eklendi',
      });

      return true;
    } catch (e) {
      print('❌ Supabase bilet ekleme hatası: $e');
      return false;
    }
  }

  // Bilet güncelleme
  Future<bool> updateTicket(Ticket ticket) async {
    try {
      await _client.from('tickets').update(ticket.toJson()).eq('id', ticket.id);
      print('✅ Bilet Supabase\'de güncellendi: ${ticket.number}');

      // Admin işlemini broadcast et
      _broadcastAdminAction('ticket_updated', {
        'ticket_number': ticket.number,
        'admin_action': 'Bilet güncellendi',
      });

      return true;
    } catch (e) {
      print('❌ Supabase bilet güncelleme hatası: $e');
      return false;
    }
  }

  // 📱 ADMIN İŞLEMİ BROADCAST
  void _broadcastAdminAction(String actionType, Map<String, dynamic> data) {
    _realtimeEventsController.add({
      'type': 'admin_action',
      'action': actionType,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
      'source': 'admin',
    });
  }

  // 🔄 MANUEL YENİLEME (Admin "Biletleri Listele" butonu için)
  Future<void> refreshTickets() async {
    try {
      print('🔄 Biletler manuel yenileniyor...');
      final tickets = await getAllTickets();
      _ticketsController.add(tickets);

      // Bayi'lere bildirim gönder
      _broadcastAdminAction('tickets_refreshed', {
        'admin_action': 'Biletler listelendi',
        'ticket_count': tickets.length,
      });

      print('✅ Biletler başarıyla yenilendi: ${tickets.length} bilet');
    } catch (e) {
      print('❌ Bilet yenileme hatası: $e');
    }
  }

  // 🔄 KAMPANYA YENİLEME
  Future<void> refreshCampaigns() async {
    try {
      print('🔄 Kampanyalar manuel yenileniyor...');
      final campaigns = await getCampaigns();
      _campaignsController.add(campaigns);

      // Bayi'lere bildirim gönder
      _broadcastAdminAction('campaigns_refreshed', {
        'admin_action': 'Kampanyalar listelendi',
        'campaign_count': campaigns.length,
      });

      print('✅ Kampanyalar başarıyla yenilendi: ${campaigns.length} kampanya');
    } catch (e) {
      print('❌ Kampanya yenileme hatası: $e');
    }
  }

  // 📊 MEVCUT METODLAR (değişiklik yok)

  // Tüm kampanyaları getir
  Future<List<Campaign>> getCampaigns() async {
    try {
      final response = await _client.from('campaigns').select();
      final campaigns =
          (response as List).map((json) => Campaign.fromJson(json)).toList();
      print('✅ ${campaigns.length} kampanya Supabase\'den alındı');
      return campaigns;
    } catch (e) {
      print('❌ Supabase kampanya getirme hatası: $e');
      return [];
    }
  }

  // Kampanya biletlerini getir
  Future<List<Ticket>> getCampaignTickets(String campaignId) async {
    try {
      final response =
          await _client.from('tickets').select().eq('campaign_id', campaignId);
      final tickets =
          (response as List).map((json) => Ticket.fromJson(json)).toList();
      print('✅ ${tickets.length} bilet Supabase\'den alındı');
      return tickets;
    } catch (e) {
      print('❌ Supabase bilet getirme hatası: $e');
      return [];
    }
  }

  // Tüm biletleri getir
  Future<List<Ticket>> getAllTickets() async {
    try {
      final response = await _client.from('tickets').select();
      final tickets =
          (response as List).map((json) => Ticket.fromJson(json)).toList();
      print('✅ ${tickets.length} bilet Supabase\'den alındı');
      return tickets;
    } catch (e) {
      print('❌ Supabase tüm bilet getirme hatası: $e');
      return [];
    }
  }

  // 🧪 Bağlantı testi
  Future<bool> testConnection() async {
    try {
      await _client.from('campaigns').select().limit(1);
      print('✅ Supabase bağlantısı başarılı');
      return true;
    } catch (e) {
      print('❌ Supabase bağlantı hatası: $e');
      return false;
    }
  }

  // 🗑️ KAYNAKLARI TEMİZLE
  void dispose() {
    _campaignsSubscription?.unsubscribe();
    _ticketsSubscription?.unsubscribe();
    _campaignsController.close();
    _ticketsController.close();
    _realtimeEventsController.close();
    print('✅ Supabase realtime kaynakları temizlendi');
  }
}
