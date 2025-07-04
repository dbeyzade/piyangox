import 'dart:math';
import '../models/ticket.dart';
import '../models/notification.dart';
import 'campaign_service.dart';

class TicketService {
  static final TicketService _instance = TicketService._internal();
  factory TicketService() => _instance;
  TicketService._internal();

  final CampaignService _campaignService = CampaignService();
  final List<Notification> _notifications = [];

  List<Notification> get notifications => List.unmodifiable(_notifications);
  List<Notification> get pendingNotifications => 
      _notifications.where((n) => n.isPending).toList();
  
  // Bilet satın al
  Future<bool> purchaseTicket({
    required String ticketId,
    required String buyerName,
    required String buyerPhone,
  }) async {
    try {
      // Tüm kampanyalardan tüm biletleri al
      for (var campaign in _campaignService.campaigns) {
        final tickets = _campaignService.getCampaignTickets(campaign.id);
        final ticketIndex = tickets.indexWhere((t) => t.id == ticketId);
        
        if (ticketIndex != -1 && tickets[ticketIndex].status == TicketStatus.available) {
          // Bu metod henüz yok, geçici olarak true döndürelim
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Bilet durumu güncelle
  Future<bool> updateTicketStatus({
    required String ticketId,
    required TicketStatus status,
    String? buyerName,
    String? buyerPhone,
  }) async {
    try {
      // Tüm kampanyalardan bilet ara
      for (var campaign in _campaignService.campaigns) {
        final tickets = _campaignService.getCampaignTickets(campaign.id);
        final ticketIndex = tickets.indexWhere((t) => t.id == ticketId);
        
        if (ticketIndex != -1) {
          // Geçici olarak true döndür
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Rastgele bilet seç (Şanslı hissediyorum)
  Future<Ticket?> selectRandomTicket(String campaignId) async {
    try {
      // Tüm sistem biletlerinden sadece müsait olanları al
      final allTickets = _campaignService.getAllSystemTickets();
      final availableTickets = allTickets.where((t) => 
          t.status == TicketStatus.available
      ).toList();
      
      if (availableTickets.isEmpty) {
        return null;
      }

      final random = Random();
      final selectedTicket = availableTickets[random.nextInt(availableTickets.length)];
      
      return selectedTicket;
    } catch (e) {
      return null;
    }
  }

  // Bilet talebi oluştur (Üyeden gelen)
  Future<bool> createTicketRequest({
    required String ticketId,
    required String fromUserId,
    required String fromUserName,
  }) async {
    try {
      // Tüm kampanyalardan bilet ara
      Ticket? ticket;
      for (var campaign in _campaignService.campaigns) {
        final tickets = _campaignService.getCampaignTickets(campaign.id);
        try {
          ticket = tickets.firstWhere((t) => t.id == ticketId);
          break;
        } catch (e) {
          continue;
        }
      }
      if (ticket == null) return false;
      final campaign = _campaignService.getCampaign(ticket.campaignId);
      
      if (campaign == null) return false;

      final notification = Notification(
        id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
        title: '🎫 Bilet Talebi',
        message: '$fromUserName ${campaign.name} kampanyası için bilet talebinde bulundu.\n'
                'Bilet No: ${ticket.numbers.join(', ')}\n'
                'Fiyat: ${ticket.price} ₺',
        type: NotificationType.ticketRequest,
        fromUserId: fromUserId,
        fromUserName: fromUserName,
        ticketId: ticketId,
        createdAt: DateTime.now(),
      );

      _notifications.add(notification);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Bilet talebini onayla/reddet
  Future<bool> processTicketRequest({
    required String notificationId,
    required bool approved,
    required String buyerName,
    required String buyerPhone,
  }) async {
    try {
      final notificationIndex = _notifications.indexWhere((n) => n.id == notificationId);
      if (notificationIndex == -1) return false;

      final notification = _notifications[notificationIndex];
      if (notification.ticketId == null) return false;

      // Bildirimi güncelle
      final updatedNotification = notification.copyWith(
        status: approved ? NotificationStatus.approved : NotificationStatus.rejected,
        processedAt: DateTime.now(),
      );
      _notifications[notificationIndex] = updatedNotification;

      // Onaylandıysa bileti sat
      if (approved) {
        return await purchaseTicket(
          ticketId: notification.ticketId!,
          buyerName: buyerName,
          buyerPhone: buyerPhone,
        );
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  // Kullanıcının biletlerini getir
  List<Ticket> getUserTickets(String buyerName) {
    List<Ticket> allTickets = [];
    for (var campaign in _campaignService.campaigns) {
      allTickets.addAll(_campaignService.getCampaignTickets(campaign.id));
    }
    return allTickets
        .where((t) => t.buyerName?.toLowerCase() == buyerName.toLowerCase())
        .toList();
  }

  // İsme göre bilet ara
  List<Ticket> searchTicketsByName(String searchTerm) {
    if (searchTerm.isEmpty) return [];

    List<Ticket> allTickets = [];
    for (var campaign in _campaignService.campaigns) {
      allTickets.addAll(_campaignService.getCampaignTickets(campaign.id));
    }
    
    return allTickets
        .where((t) => 
            (t.buyerName?.toLowerCase().contains(searchTerm.toLowerCase()) ?? false) ||
            (t.buyerPhone?.contains(searchTerm) ?? false) ||
            t.numbers.any((num) => num.contains(searchTerm))
        )
        .toList();
  }

  // Bilet numarasına göre ara
  List<Ticket> searchTicketsByNumber(String number) {
    if (number.isEmpty) return [];

    List<Ticket> allTickets = [];
    for (var campaign in _campaignService.campaigns) {
      allTickets.addAll(_campaignService.getCampaignTickets(campaign.id));
    }

    return allTickets
        .where((t) => t.numbers.any((num) => num.contains(number)))
        .toList();
  }

  // Kampanya biletlerini karışık sırala (Liste yayınla)
  List<Ticket> getShuffledCampaignTickets(String campaignId) {
    final tickets = _campaignService.getCampaignTickets(campaignId);
    final shuffledList = List<Ticket>.from(tickets);
    shuffledList.shuffle();
    return shuffledList;
  }

  // Ödenmemiş biletleri getir
  List<Ticket> getUnpaidTickets([String? campaignId]) {
    List<Ticket> allTickets = [];
    if (campaignId != null) {
      allTickets.addAll(_campaignService.getCampaignTickets(campaignId));
    } else {
      for (var campaign in _campaignService.campaigns) {
        allTickets.addAll(_campaignService.getCampaignTickets(campaign.id));
      }
    }

    return allTickets.where((t) => 
        t.status == TicketStatus.sold && !t.isWinner
    ).toList();
  }

  // Kazanan biletleri getir
  List<Ticket> getWinningTickets([String? campaignId]) {
    List<Ticket> allTickets = [];
    if (campaignId != null) {
      allTickets.addAll(_campaignService.getCampaignTickets(campaignId));
    } else {
      for (var campaign in _campaignService.campaigns) {
        allTickets.addAll(_campaignService.getCampaignTickets(campaign.id));
      }
    }

    return allTickets.where((t) => t.isWinner).toList();
  }

  // Belirli durumdaki biletleri getir
  List<Ticket> getTicketsByStatus(TicketStatus status, [String? campaignId]) {
    List<Ticket> allTickets = [];
    if (campaignId != null) {
      allTickets.addAll(_campaignService.getCampaignTickets(campaignId));
    } else {
      for (var campaign in _campaignService.campaigns) {
        allTickets.addAll(_campaignService.getCampaignTickets(campaign.id));
      }
    }

    return allTickets.where((t) => t.status == status).toList();
  }

  // Bildirim sil
  Future<bool> deleteNotification(String notificationId) async {
    try {
      _notifications.removeWhere((n) => n.id == notificationId);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Tüm bildirimleri okundu işaretle
  Future<void> markAllNotificationsAsRead() async {
    for (int i = 0; i < _notifications.length; i++) {
      if (_notifications[i].status == NotificationStatus.pending) {
        _notifications[i] = _notifications[i].copyWith(
          status: NotificationStatus.approved, // Okundu olarak işaretle
          processedAt: DateTime.now(),
        );
      }
    }
  }

  // Kampanya için müsait biletleri getir
  List<Ticket> getAvailableTicketsForCampaign(String campaignId) {
    return _campaignService.getAllSystemTickets()
        .where((ticket) => ticket.campaignId == campaignId && ticket.status == TicketStatus.available)
        .toList();
  }

  // Kampanya için satılan biletleri getir
  List<Ticket> getSoldTicketsForCampaign(String campaignId) {
    return _campaignService.getAllSystemTickets()
        .where((ticket) => ticket.campaignId == campaignId && 
                          (ticket.status == TicketStatus.sold || 
                           ticket.status == TicketStatus.paid ||
                           ticket.status == TicketStatus.unpaid))
        .toList();
  }
}
