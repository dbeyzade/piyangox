import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

class SharedData {
  final String id;
  final double currentTicketPrice;
  final int currentTicketCount;
  final String? systemMessage;
  final List<String>? adminNotifications;
  final List<String>? bayiNotifications;
  final bool maintenanceMode;
  final String? lastUpdatedBy;
  final DateTime updatedAt;
  final DateTime createdAt;

  SharedData({
    required this.id,
    required this.currentTicketPrice,
    required this.currentTicketCount,
    this.systemMessage,
    this.adminNotifications,
    this.bayiNotifications,
    required this.maintenanceMode,
    this.lastUpdatedBy,
    required this.updatedAt,
    required this.createdAt,
  });

  factory SharedData.fromJson(Map<String, dynamic> json) {
    return SharedData(
      id: json['id'],
      currentTicketPrice: (json['current_ticket_price'] as num?)?.toDouble() ?? 10.0,
      currentTicketCount: json['current_ticket_count'] ?? 100,
      systemMessage: json['system_message'],
      adminNotifications: json['admin_notifications'] != null 
          ? List<String>.from(json['admin_notifications']) 
          : null,
      bayiNotifications: json['bayi_notifications'] != null 
          ? List<String>.from(json['bayi_notifications']) 
          : null,
      maintenanceMode: json['maintenance_mode'] ?? false,
      lastUpdatedBy: json['last_updated_by'],
      updatedAt: DateTime.parse(json['updated_at']),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'current_ticket_price': currentTicketPrice,
      'current_ticket_count': currentTicketCount,
      'system_message': systemMessage,
      'admin_notifications': adminNotifications,
      'bayi_notifications': bayiNotifications,
      'maintenance_mode': maintenanceMode,
      'last_updated_by': lastUpdatedBy,
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class RealtimeDataService {
  static final RealtimeDataService _instance = RealtimeDataService._internal();
  factory RealtimeDataService() => _instance;
  RealtimeDataService._internal();

  final SupabaseClient _client = Supabase.instance.client;
  
  // Real-time subscription
  RealtimeChannel? _subscription;
  
  // Stream controller for shared data updates
  final StreamController<SharedData> _sharedDataController = 
      StreamController<SharedData>.broadcast();
  
  // Current shared data
  SharedData? _currentSharedData;
  
  // Getters
  Stream<SharedData> get sharedDataStream => _sharedDataController.stream;
  SharedData? get currentSharedData => _currentSharedData;

  // Initialize real-time subscription
  Future<void> initializeRealtime() async {
    try {
      // İlk veriyi yükle
      await _loadInitialData();
      
      // Real-time subscription başlat
      _subscription = _client
          .channel('shared_data_changes')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'shared_data',
            callback: (payload) {
              print('🔄 Real-time güncelleme alındı: ${payload.eventType}');
              _handleRealtimeUpdate(payload);
            },
          )
          .subscribe();
          
      print('✅ Real-time subscription başlatıldı');
    } catch (e) {
      print('❌ Real-time başlatma hatası: $e');
    }
  }

  // Load initial data
  Future<void> _loadInitialData() async {
    try {
      final response = await _client
          .from('shared_data')
          .select()
          .eq('id', 'main')
          .single();
      
      _currentSharedData = SharedData.fromJson(response);
      _sharedDataController.add(_currentSharedData!);
      
      print('✅ İlk veri yüklendi: ${_currentSharedData!.currentTicketPrice} TL');
    } catch (e) {
      print('❌ İlk veri yükleme hatası: $e');
    }
  }

  // Handle real-time updates
  void _handleRealtimeUpdate(PostgresChangePayload payload) {
    try {
      if (payload.newRecord != null) {
        _currentSharedData = SharedData.fromJson(payload.newRecord!);
        _sharedDataController.add(_currentSharedData!);
        print('✅ Real-time veri güncellendi: ${_currentSharedData!.currentTicketPrice} TL');
      }
    } catch (e) {
      print('❌ Real-time güncelleme işleme hatası: $e');
    }
  }

  // Update shared data (Admin tarafından kullanılır)
  Future<bool> updateSharedData({
    double? ticketPrice,
    int? ticketCount,
    String? systemMessage,
    List<String>? adminNotifications,
    List<String>? bayiNotifications,
    bool? maintenanceMode,
    required String updatedBy,
  }) async {
    try {
      final updates = <String, dynamic>{
        'last_updated_by': updatedBy,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (ticketPrice != null) updates['current_ticket_price'] = ticketPrice;
      if (ticketCount != null) updates['current_ticket_count'] = ticketCount;
      if (systemMessage != null) updates['system_message'] = systemMessage;
      if (adminNotifications != null) updates['admin_notifications'] = adminNotifications;
      if (bayiNotifications != null) updates['bayi_notifications'] = bayiNotifications;
      if (maintenanceMode != null) updates['maintenance_mode'] = maintenanceMode;

      await _client
          .from('shared_data')
          .update(updates)
          .eq('id', 'main');

      print('✅ Shared data güncellendi');
      return true;
    } catch (e) {
      print('❌ Shared data güncelleme hatası: $e');
      return false;
    }
  }

  // Add notification for bayi
  Future<bool> addBayiNotification(String message, String adminName) async {
    try {
      if (_currentSharedData == null) return false;
      
      List<String> notifications = List.from(_currentSharedData!.bayiNotifications ?? []);
      notifications.add('${DateTime.now().toString().substring(0, 16)}: $message');
      
      // Son 10 bildirimi tut
      if (notifications.length > 10) {
        notifications = notifications.sublist(notifications.length - 10);
      }
      
      return await updateSharedData(
        bayiNotifications: notifications,
        updatedBy: adminName,
      );
    } catch (e) {
      print('❌ Bayi bildirimi ekleme hatası: $e');
      return false;
    }
  }

  // Cleanup
  void dispose() {
    _subscription?.unsubscribe();
    _sharedDataController.close();
  }
}
