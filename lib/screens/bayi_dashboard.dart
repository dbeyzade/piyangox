import 'package:flutter/material.dart';
import 'dart:math';
import '../models/ticket.dart';
import '../models/campaign.dart';
import '../services/auth_service.dart';
import '../services/campaign_service.dart';
import '../services/ticket_service.dart';
import '../services/financial_service.dart';
import '../services/complaint_service.dart';
import '../services/local_storage_service.dart';
import '../services/supabase_service.dart';
import 'login_screen.dart';
import '../services/realtime_data_service.dart';

class BayiDashboard extends StatefulWidget {
  const BayiDashboard({super.key});

  @override
  _BayiDashboardState createState() => _BayiDashboardState();
}

class _BayiDashboardState extends State<BayiDashboard>
    with WidgetsBindingObserver {
  final AuthService _authService = AuthService();
  final CampaignService _campaignService = CampaignService();
  final TicketService _ticketService = TicketService();
  final FinancialService _financialService = FinancialService();
  final ComplaintService _complaintService = ComplaintService();
  final LocalStorageService _localStorageService = LocalStorageService();
  final RealtimeDataService _realtimeService = RealtimeDataService();

  // 🆕 YENİ: Supabase Service entegrasyonu
  final SupabaseService _supabaseService = SupabaseService();

  SharedData? _currentSharedData;

  // 🆕 YENİ: Gerçek zamanlı bilet listesi
  List<Ticket> _realtimeTickets = [];
  bool _isLoadingTickets = false;

  String _selectedMenuItem = 'biletlerim';
  bool _isSelectionMode = false;
  Set<String> _selectedTicketIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Başlangıçta paylaşılan veriyi yükle
    _loadData();
    _initializeRealtime();
  }

  @override

  // 🔧 GÜNCELLENDİ: Realtime initialization - hem SharedData hem de Tickets
  Future<void> _initializeRealtime() async {
    try {
      // SharedData realtime (mevcut)
      await _realtimeService.initializeRealtime();

      // 🆕 YENİ: Supabase Tickets realtime
      await _supabaseService.testConnection();

      // SharedData stream (mevcut)
      _realtimeService.sharedDataStream.listen((sharedData) {
        if (mounted) {
          setState(() {
            _currentSharedData = sharedData;
          });
          _showRealtimeUpdate(sharedData);
        }
      });

      print('✅ Bayi Dashboard realtime (SharedData + Tickets) başlatıldı');
    } catch (e) {
      print('❌ Bayi realtime başlatma hatası: $e');
    }
  }

  // 🆕 YENİ: Bilet güncellemesi bildirimi
  void _showTicketUpdateNotification(int ticketCount) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.confirmation_number, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '🎫 Bilet Listesi Güncellendi: $ticketCount bilet mevcut',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // 🆕 YENİ: Admin aksiyon bildirimi
  void _showAdminActionNotification(Map<String, dynamic> event) {
    if (event['source'] == 'admin' && event['type'] == 'admin_action') {
      final data = event['data'] as Map<String, dynamic>;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.admin_panel_settings, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '👨‍💼 Admin: ${data['admin_action']}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.blue,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Mevcut SharedData bildirimini güncelle
  void _showRealtimeUpdate(SharedData sharedData) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.update, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '🔄 Admin Güncellemesi: Bilet ${sharedData.currentTicketPrice.toStringAsFixed(0)} ₺, Sayı: ${sharedData.currentTicketCount}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _realtimeService.dispose();
    _supabaseService.dispose(); // 🆕 YENİ: Supabase realtime temizle
    WidgetsBinding.instance.removeObserver(this);
    _saveData();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _saveData();
    } else if (state == AppLifecycleState.resumed) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    // Önce local storage'dan yükle
    final selectedMenu = await _localStorageService.getSelectedMenuItem();
    if (selectedMenu != null) {
      setState(() {
        _selectedMenuItem = selectedMenu;
      });
    }

    // Sonra paylaşılan veriyi yükle
    await _campaignService.refreshFromSharedData();
    setState(() {});
  }

  Future<void> _saveData() async {
    await _localStorageService.saveSelectedMenuItem(_selectedMenuItem);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Row(
        children: [
          // Sol menü
          Container(
            width: 280,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF388E3C),
                  Color(0xFF4CAF50),
                ],
              ),
            ),
            child: _buildSideMenu(),
          ),

          // Ana içerik
          Expanded(
            child: Column(
              children: [
                // Üst bar
                _buildTopBar(),
                // Real-time Admin Info Banner
                if (_currentSharedData != null)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.blue, Colors.blueAccent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.admin_panel_settings,
                          color: Colors.white,
                          size: 32,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '📡 Admin Canlı Bilgileri',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '💰 ${_currentSharedData!.currentTicketPrice.toStringAsFixed(0)} ₺',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '🎫 ${_currentSharedData!.currentTicketCount} adet',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (_currentSharedData!.systemMessage !=
                                  null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  '📢 ${_currentSharedData!.systemMessage}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Text(
                          '🔄 ${_currentSharedData!.updatedAt.toString().substring(11, 16)}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Ana içerik alanı
                Expanded(
                  child: _buildMainContent(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSideMenu() {
    final menuItems = [
      {
        'id': 'biletlerim',
        'title': 'Biletlerim',
        'icon': Icons.confirmation_number,
        'color': Colors.blue
      },
      {
        'id': 'kampanyalar',
        'title': 'Kampanyalar',
        'icon': Icons.campaign,
        'color': Colors.deepPurple
      },
      {
        'id': 'yeni_kampanyalar',
        'title': 'Yeni Kampanyalar',
        'icon': Icons.new_releases,
        'color': Colors.purple
      },
      {
        'id': 'bilgilerim',
        'title': 'Bilgilerim',
        'icon': Icons.person,
        'color': Colors.indigo
      },
      {
        'id': 'sansliyim',
        'title': 'Kendimi Şanslı Hissediyorum',
        'icon': Icons.casino,
        'color': Colors.purple
      },
      {
        'id': 'gecmis_cekilisler',
        'title': 'Geçmiş Çekilişler',
        'icon': Icons.history,
        'color': Colors.orange
      },
      {
        'id': 'toplam_gelir',
        'title': 'Toplam Gelir',
        'icon': Icons.trending_up,
        'color': Colors.green
      },
      {
        'id': 'toplam_gider',
        'title': 'Toplam Gider',
        'icon': Icons.trending_down,
        'color': Colors.red
      },
      {
        'id': 'kasa_durumu',
        'title': 'Kasa Durumu',
        'icon': Icons.account_balance_wallet,
        'color': Colors.indigo
      },
    ];

    return Column(
      children: [
        // Profil alanı
        Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    backgroundImage: _authService.currentUser?.profileImage !=
                            null
                        ? NetworkImage(_authService.currentUser!.profileImage!)
                        : null,
                    child: _authService.currentUser?.profileImage == null
                        ? const Icon(
                            Icons.store,
                            size: 30,
                            color: Color(0xFF388E3C),
                          )
                        : null,
                  ),
                  if (_authService.currentUser?.isGuest == true)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person_outline,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                _authService.currentUser?.name ?? 'Üye',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _authService.currentUser?.isGuest == true
                    ? 'Misafir Üye'
                    : 'Üye Paneli',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),

        const Divider(color: Colors.white30),

        // Menü öğeleri
        Expanded(
          child: ListView.builder(
            itemCount: menuItems.length,
            itemBuilder: (context, index) {
              final item = menuItems[index];
              final isSelected = _selectedMenuItem == item['id'];

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withOpacity(0.2) : null,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  leading: Icon(
                    item['icon'] as IconData,
                    color: isSelected ? Colors.white : Colors.white70,
                  ),
                  title: Text(
                    item['title'] as String,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                  onTap: () {
                    setState(() {
                      _selectedMenuItem = item['id'] as String;
                    });
                  },
                ),
              );
            },
          ),
        ),

        // Dilek şikayet butonu
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showComplaintDialog,
              icon: const Icon(Icons.feedback),
              label: const Text('Dilek/Şikayet'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Çıkış butonu
        Container(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout),
              label: const Text('Çıkış Yap'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            _getPageTitle(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),

          const Spacer(),

          // Tarih ve saat
          Text(
            '📅 ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    switch (_selectedMenuItem) {
      case 'biletlerim':
        return _buildBiletlerim();
      case 'kampanyalar':
        return _buildKampanyalar();
      case 'yeni_kampanyalar':
        return _buildYeniKampanyalar();
      case 'bilgilerim':
        return _buildBilgilerim();
      case 'sansliyim':
        return _buildSansliHissediyorum();
      case 'gecmis_cekilisler':
        return _buildGecmisCekilisler();
      case 'toplam_gelir':
        return _buildToplamGelir();
      case 'toplam_gider':
        return _buildToplamGider();
      case 'kasa_durumu':
        return _buildKasaDurumu();
      default:
        return _buildBiletlerim();
    }
  }

  String _getPageTitle() {
    switch (_selectedMenuItem) {
      case 'biletlerim':
        return '🎫 Biletlerim';
      case 'kampanyalar':
        return '🎯 Kampanyalar';
      case 'yeni_kampanyalar':
        return '🆕 Yeni Kampanyalar';
      case 'bilgilerim':
        return '👤 Bilgilerim';
      case 'sansliyim':
        return '🍀 Kendimi Şanslı Hissediyorum';
      case 'gecmis_cekilisler':
        return '📜 Geçmiş Çekilişler';
      case 'toplam_gelir':
        return '📈 Toplam Gelir';
      case 'toplam_gider':
        return '📉 Toplam Gider';
      case 'kasa_durumu':
        return '💰 Kasa Durumu';
      default:
        return '🏪 Üye Paneli';
    }
  }

  // Bilgilerim sayfası
  Widget _buildBilgilerim() {
    final user = _authService.currentUser!;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Profil kartı
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Profil resmi
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: user.profileImage != null
                              ? NetworkImage(user.profileImage!)
                              : null,
                          child: user.profileImage == null
                              ? Icon(
                                  user.isGuest
                                      ? Icons.person_outline
                                      : Icons.person,
                                  size: 60,
                                  color: Colors.grey[400],
                                )
                              : null,
                        ),
                        if (!user
                            .isGuest) // Misafir kullanıcılar profil resmi değiştiremez
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.camera_alt,
                                    color: Colors.white),
                                onPressed: _showProfileImageOptions,
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Kullanıcı bilgileri
                    _buildInfoRow('👤 Ad Soyad', user.name),
                    if (!user.isGuest)
                      _buildInfoRow('🆔 Kullanıcı Adı', user.username),
                    if (user.email != null)
                      _buildInfoRow('📧 E-posta', user.email!),
                    if (user.phone != null)
                      _buildInfoRow('📞 Telefon', user.phone!),
                    _buildInfoRow('👑 Durum',
                        user.isGuest ? 'Misafir Üye' : 'Kayıtlı Üye'),
                    if (!user.isGuest)
                      _buildInfoRow('🎤 Kayıt Tarihi',
                          '${user.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}'),

                    const SizedBox(height: 32),

                    // Aksiyonlar
                    if (user.isGuest)
                      // Misafir kullanıcı için üye ol butonu
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _showRegisterDialog,
                          icon: const Icon(Icons.person_add),
                          label: const Text('Üye Ol'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      )
                    else
                      // Kayıtlı kullanıcı için düzenleme butonları
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _showEditProfileDialog,
                              icon: const Icon(Icons.edit),
                              label: const Text('Bilgileri Düzenle'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _showChangePasswordDialog,
                              icon: const Icon(Icons.lock),
                              label: const Text('Şifre Değiştir'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  // 🔧 GÜNCELLENDİ: _buildBiletlerim metodu - Supabase'den gerçek biletler
  Widget _buildBiletlerim() {
    final user = _authService.currentUser!;

    // 🆕 YENİ: Gerçek zamanlı Supabase biletlerinden kullanıcının biletlerini filtrele
    final myTickets = _realtimeTickets
        .where((ticket) =>
            ticket.buyerName?.toLowerCase() == user.name.toLowerCase())
        .toList();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // 🆕 YENİ: Realtime bilgi banner'ı
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.green, Colors.teal],
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.sync, color: Colors.green, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '📡 Gerçek Zamanlı Bilet Listesi',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Toplam ${_realtimeTickets.length} bilet • Admin\'deki değişiklikler anında görünür',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isLoadingTickets)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
              ],
            ),
          ),

          // Kontrol butonları (mevcut kodla aynı)
          if (myTickets.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Seçim modu butonu
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _isSelectionMode = !_isSelectionMode;
                        if (!_isSelectionMode) {
                          _selectedTicketIds.clear();
                        }
                      });
                    },
                    icon:
                        Icon(_isSelectionMode ? Icons.close : Icons.check_box),
                    label: Text(_isSelectionMode ? 'İptal' : 'Seç'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _isSelectionMode ? Colors.grey : Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),

                  // 🆕 YENİ: Manuel yenileme butonu
                  ElevatedButton.icon(
                    onPressed: () async {
                      setState(() {
                        _isLoadingTickets = true;
                      });

                      // Supabase'den manuel yenileme
                      await _supabaseService.testConnection();

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('🔄 Bilet listesi yenilendi'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: _isLoadingTickets
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.refresh),
                    label: const Text('Yenile'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                    ),
                  ),

                  // Seçim modunda ek butonlar
                  if (_isSelectionMode) ...[
                    Row(
                      children: [
                        // Tümünü seç/kaldır
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              if (_selectedTicketIds.length ==
                                  myTickets.length) {
                                _selectedTicketIds.clear();
                              } else {
                                _selectedTicketIds =
                                    myTickets.map((t) => t.id).toSet();
                              }
                            });
                          },
                          icon: Icon(
                              _selectedTicketIds.length == myTickets.length
                                  ? Icons.deselect
                                  : Icons.select_all),
                          label: Text(
                              _selectedTicketIds.length == myTickets.length
                                  ? 'Seçimi Kaldır'
                                  : 'Tümünü Seç'),
                        ),
                        const SizedBox(width: 8),
                        // Seçilenleri sil
                        ElevatedButton.icon(
                          onPressed: _selectedTicketIds.isEmpty
                              ? null
                              : _deleteSelectedTickets,
                          icon: const Icon(Icons.delete),
                          label: Text('Sil (${_selectedTicketIds.length})'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

          if (myTickets.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.confirmation_number_outlined,
                        size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      'Henüz biletiniz bulunmuyor',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Toplam ${_realtimeTickets.length} bilet mevcut',
                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _selectedMenuItem = 'sansliyim';
                        });
                      },
                      icon: const Icon(Icons.casino),
                      label: const Text('Şansını Dene'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount:
                      3, // 2'den 3'e çıkarıldı - daha fazla bilet yan yana
                  childAspectRatio:
                      1.0, // 1.5'ten 1.0'a düşürüldü - %70 daha küçük
                  crossAxisSpacing: 12, // Boşluk küçültüldü
                  mainAxisSpacing: 12,
                ),
                itemCount: myTickets.length,
                itemBuilder: (context, index) {
                  final ticket = myTickets[index];
                  final campaign =
                      _campaignService.getCampaign(ticket.campaignId);

                  return _buildTicketCard(ticket, campaign);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTicketCard(Ticket ticket, campaign) {
    final isSelected = _selectedTicketIds.contains(ticket.id);

    return GestureDetector(
      onTap: _isSelectionMode
          ? () {
              setState(() {
                if (isSelected) {
                  _selectedTicketIds.remove(ticket.id);
                } else {
                  _selectedTicketIds.add(ticket.id);
                }
              });
            }
          : null,
      onLongPress: !_isSelectionMode ? () => _showTicketOptions(ticket) : null,
      child: Container(
        margin: const EdgeInsets.all(4),
        child: Stack(
          children: [
            // Ana bilet kartı
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                  // Hologram efekti için ekstra gölge
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: -5,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isSelected
                          ? [
                              const Color(0xFFFF6B6B),
                              const Color(0xFFEE5A24),
                            ]
                          : [
                              const Color(0xFF667eea),
                              const Color(0xFF764ba2),
                              const Color(0xFFf093fb),
                            ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Arka plan deseni - Güvenlik için
                      Positioned.fill(
                        child: CustomPaint(
                          painter: TicketPatternPainter(),
                        ),
                      ),

                      // Ana içerik
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Üst başlık bölümü
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white.withOpacity(0.9),
                                    Colors.white.withOpacity(0.7),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Colors.amber,
                                              Colors.orange
                                            ],
                                          ),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.orange
                                                  .withOpacity(0.5),
                                              blurRadius: 8,
                                              spreadRadius: 2,
                                            ),
                                          ],
                                        ),
                                        child: const Center(
                                          child: Text(
                                            'P',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Text(
                                        'PiyangoX',
                                        style: TextStyle(
                                          color: Colors.black87,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      'SERİ: ${ticket.id.substring(0, 6).toUpperCase()}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 10),

                            // Kampanya adı
                            if (campaign != null)
                              Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.black.withOpacity(0.7),
                                        Colors.black.withOpacity(0.5),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Text(
                                    campaign.name.toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                              ),

                            const Spacer(),

                            // Bilet numaraları - Ana özellik
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.white,
                                    Colors.grey[100]!,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.5),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  ShaderMask(
                                    shaderCallback: (bounds) =>
                                        const LinearGradient(
                                      colors: [Colors.purple, Colors.blue],
                                    ).createShader(bounds),
                                    child: const Text(
                                      '🎰 ŞANS NUMARALARI 🎰',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  // Numaralar
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF1e3c72),
                                          Color(0xFF2a5298)
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.blue.withOpacity(0.3),
                                          blurRadius: 8,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      ticket.numbersFormatted,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        letterSpacing: 2,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black26,
                                            offset: Offset(1, 1),
                                            blurRadius: 2,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const Spacer(),

                            // Alt bilgi bölümü
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.green,
                                          borderRadius:
                                              BorderRadius.circular(5),
                                        ),
                                        child: Text(
                                          '${ticket.price.toStringAsFixed(0)}₺',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        ticket.statusText,
                                        style: TextStyle(
                                          color: _getStatusColor(ticket.status),
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  // QR kod simülasyonu
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: CustomPaint(
                                      painter: QRPainter(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Hologram efekti overlay
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withOpacity(0.1),
                                Colors.transparent,
                                Colors.white.withOpacity(0.05),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Kazanan rozeti
                      if (ticket.isWinner)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.yellow,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.yellow.withOpacity(0.5),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.star,
                              color: Colors.orange,
                              size: 20,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // Seçim checkbox'ı
            if (_isSelectionMode)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    isSelected ? Icons.check_circle : Icons.circle_outlined,
                    color: isSelected ? Colors.red : Colors.grey,
                    size: 28,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(TicketStatus status) {
    switch (status) {
      case TicketStatus.available:
        return Colors.white70;
      case TicketStatus.sold:
      case TicketStatus.unpaid:
        return Colors.orange;
      case TicketStatus.paid:
        return Colors.green;
      case TicketStatus.cancelled:
        return Colors.red;
      case TicketStatus.winner:
        return Colors.yellow;
    }
  }

  Widget _buildSansliHissediyorum() {
    // Tüm sistem biletlerinden sadece müsait olanları al
    final allTickets = _campaignService.getAllSystemTickets();
    final availableTickets =
        allTickets.where((t) => t.status == TicketStatus.available).toList();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Text(
            '🍀 Şansını Dene!',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            'Müsait biletlerden birini seçin',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Müsait bilet sayısı bilgisi
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.confirmation_number, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  '${availableTickets.length} adet müsait bilet',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          if (availableTickets.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.hourglass_empty,
                        size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      'Şu anda müsait bilet bulunmuyor',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Admin yeni biletler eklediğinde burada görünecek',
                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: Column(
                children: [
                  // Rastgele bilet seç butonu
                  ElevatedButton.icon(
                    onPressed: () =>
                        _selectRandomAvailableTicket(availableTickets),
                    icon: const Icon(Icons.casino),
                    label: const Text('Rastgele Bilet Seç'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Müsait biletlerin grid listesi - Scrollbar ile
                  Expanded(
                    child: Scrollbar(
                      thumbVisibility: true, // Scrollbar her zaman görünür
                      trackVisibility: true, // Scrollbar track'i görünür
                      child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount:
                              6, // 4'ten 6'ya çıkarıldı - daha fazla bilet yan yana
                          childAspectRatio:
                              0.7, // 1.0'dan 0.7'ye düşürüldü - %30 daha dar
                          crossAxisSpacing: 6, // Boşluk da küçültüldü
                          mainAxisSpacing: 6,
                        ),
                        itemCount: availableTickets.length,
                        itemBuilder: (context, index) {
                          final ticket = availableTickets[index];
                          return _buildAvailableTicketCard(ticket);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCampaignCard(campaign) {
    return Card(
      elevation: 8,
      child: InkWell(
        onTap: () => _selectRandomTicket(campaign),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [
                Colors.purple[400]!,
                Colors.purple[600]!,
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                campaign.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${campaign.currencyEmoji} ${campaign.prizeAmountFormatted}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '🎲 Şansını Dene',
                    style: TextStyle(
                      color: Colors.purple[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGecmisCekilisler() {
    final completedCampaigns = _campaignService.completedCampaigns;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Text(
            '📜 Geçmiş Çekilişler',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (completedCampaigns.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  'Henüz tamamlanmış çekiliş bulunmuyor',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: completedCampaigns.length,
                itemBuilder: (context, index) {
                  final campaign = completedCampaigns[index];
                  return Card(
                    child: ListTile(
                      title: Text(campaign.name),
                      subtitle: Text(
                          'Kazanan: ${campaign.winningNumber ?? "Belirlenmedi"}'),
                      trailing: Text(campaign.prizeAmountFormatted),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildToplamGelir() {
    final summary = _financialService.calculateSummary();

    return Center(
      child: Card(
        child: Container(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.trending_up, size: 64, color: Colors.green),
              const SizedBox(height: 16),
              const Text(
                'Toplam Gelir',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                '${summary.totalIncome.toStringAsFixed(0)} ₺',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToplamGider() {
    final summary = _financialService.calculateSummary();

    return Center(
      child: Card(
        child: Container(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.trending_down, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Toplam Gider',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                '${summary.totalExpense.toStringAsFixed(0)} ₺',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKasaDurumu() {
    final summary = _financialService.calculateSummary();

    return Center(
      child: Card(
        child: Container(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                summary.isProfit
                    ? Icons.account_balance_wallet
                    : Icons.money_off,
                size: 64,
                color: Color(summary.balanceColor),
              ),
              const SizedBox(height: 16),
              const Text(
                'Kasa Durumu',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                summary.balanceEmoji,
                style: const TextStyle(fontSize: 32),
              ),
              Text(
                summary.balanceText,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(summary.balanceColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Profil resmi seçenekleri
  void _showProfileImageOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📷 Profil Resmi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeriden Seç'),
              onTap: () {
                Navigator.pop(context);
                _selectImageFromGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Fotoğraf Çek'),
              onTap: () {
                Navigator.pop(context);
                _takePicture();
              },
            ),
            if (_authService.currentUser?.profileImage != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Resmi Kaldır'),
                onTap: () {
                  Navigator.pop(context);
                  _removeProfileImage();
                },
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
        ],
      ),
    );
  }

  void _selectImageFromGallery() {
    // Simülasyon - gerçek uygulamada image_picker kullanılacak
    final imageUrl =
        'https://picsum.photos/200/200?random=${DateTime.now().millisecondsSinceEpoch}';
    _updateProfileImage(imageUrl);
  }

  void _takePicture() {
    // Simülasyon - gerçek uygulamada image_picker kullanılacak
    final imageUrl =
        'https://picsum.photos/200/200?random=${DateTime.now().millisecondsSinceEpoch}';
    _updateProfileImage(imageUrl);
  }

  void _removeProfileImage() {
    _updateProfileImage(null);
  }

  void _updateProfileImage(String? imageUrl) async {
    final success = await _authService.updateProfile(
      name: _authService.currentUser!.name,
      phone: _authService.currentUser!.phone,
      email: _authService.currentUser!.email,
      profileImage: imageUrl,
    );

    if (success) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Profil resmi güncellendi')),
      );
    }
  }

  // Misafir kullanıcı için üye olma
  void _showRegisterDialog() {
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('👤 Üye Ol'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Misafir hesabınızı kayıtlı üyeliğe çevirin'),
            const SizedBox(height: 16),
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(
                labelText: 'Kullanıcı Adı',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: 'Şifre',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'Telefon (opsiyonel)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (usernameController.text.isNotEmpty &&
                  passwordController.text.isNotEmpty) {
                final success = await _authService.register(
                  name: _authService.currentUser!.name,
                  username: usernameController.text,
                  password: passwordController.text,
                  phone: phoneController.text.isEmpty
                      ? null
                      : phoneController.text,
                );

                Navigator.pop(context);

                if (success) {
                  // Yeni hesapla giriş yap
                  await _authService.login(
                      usernameController.text, passwordController.text);
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('✅ Üyelik oluşturuldu!')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('❌ Bu kullanıcı adı zaten kullanılıyor')),
                  );
                }
              }
            },
            child: const Text('Üye Ol'),
          ),
        ],
      ),
    );
  }

  // Profil düzenleme
  void _showEditProfileDialog() {
    final user = _authService.currentUser!;
    final nameController = TextEditingController(text: user.name);
    final phoneController = TextEditingController(text: user.phone ?? '');
    final emailController = TextEditingController(text: user.email ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('✏️ Profili Düzenle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Ad Soyad',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'Telefon',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'E-posta',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await _authService.updateProfile(
                name: nameController.text,
                phone:
                    phoneController.text.isEmpty ? null : phoneController.text,
                email:
                    emailController.text.isEmpty ? null : emailController.text,
              );

              Navigator.pop(context);

              if (success) {
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✅ Profil güncellendi')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('❌ Güncelleme başarısız')),
                );
              }
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  // Şifre değiştirme
  void _showChangePasswordDialog() {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🔒 Şifre Değiştir'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPasswordController,
              decoration: const InputDecoration(
                labelText: 'Mevcut Şifre',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_outline),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newPasswordController,
              decoration: const InputDecoration(
                labelText: 'Yeni Şifre',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              decoration: const InputDecoration(
                labelText: 'Yeni Şifre (Tekrar)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (newPasswordController.text !=
                  confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('❌ Yeni şifreler eşleşmiyor')),
                );
                return;
              }

              if (newPasswordController.text.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('❌ Şifre en az 6 karakter olmalı')),
                );
                return;
              }

              final success = await _authService.changePassword(
                oldPasswordController.text,
                newPasswordController.text,
              );

              Navigator.pop(context);

              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('✅ Şifre başarıyla değiştirildi')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('❌ Mevcut şifre hatalı')),
                );
              }
            },
            child: const Text('Değiştir'),
          ),
        ],
      ),
    );
  }

  void _selectRandomTicket(campaign) async {
    final randomTicket = await _ticketService.selectRandomTicket(campaign.id);

    if (randomTicket != null) {
      final success = await _ticketService.createTicketRequest(
        ticketId: randomTicket.id,
        fromUserId: _authService.currentUser!.id,
        fromUserName: _authService.currentUser!.name,
      );

      if (success) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('🍀 Şanslı Bilet Seçildi!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Seçilen bilet numaraları:'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    randomTicket.numbersFormatted,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Bilet talebiniz admin onayına gönderildi.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tamam'),
              ),
            ],
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('❌ Bu kampanyada müsait bilet bulunmuyor')),
      );
    }
  }

  void _selectRandomAvailableTicket(List<Ticket> availableTickets) {
    if (availableTickets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Müsait bilet bulunmuyor')),
      );
      return;
    }

    final random = Random();
    final selectedTicket =
        availableTickets[random.nextInt(availableTickets.length)];

    _showTicketSelectionDialog(selectedTicket);
  }

  void _selectSpecificTicket(Ticket ticket) {
    _showTicketSelectionDialog(ticket);
  }

  void _showTicketSelectionDialog(Ticket ticket) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🍀 Bilet Seçildi!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Seçilen bilet numaraları:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green),
              ),
              child: Column(
                children: [
                  Text(
                    ticket.numbersFormatted,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Fiyat: ${ticket.price.toStringAsFixed(0)} ₺',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.green[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Bu bileti almak istediğinizden emin misiniz?',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[700]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await _ticketService.createTicketRequest(
                ticketId: ticket.id,
                fromUserId: _authService.currentUser!.id,
                fromUserName: _authService.currentUser!.name,
              );

              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        '✅ Bilet talebi gönderildi! Admin onayını bekliyor.'),
                    backgroundColor: Colors.green,
                  ),
                );
                setState(() {}); // Listeyi güncelle
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('❌ Bilet talebi gönderilemedi')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Bilet Al'),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableTicketCard(Ticket ticket) {
    return Card(
      elevation: 3, // Gölge de küçültüldü
      child: InkWell(
        onTap: () => _selectSpecificTicket(ticket),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(6), // Border radius küçültüldü
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Padding(
            padding: const EdgeInsets.all(6), // Padding küçültüldü
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  ticket.numbersFormatted,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 10, // 14'ten 10'a küçültüldü
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4), // Boşluk küçültüldü
                const Text(
                  'Müsait',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 8, // 11'den 8'e küçültüldü
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 2), // Boşluk küçültüldü
                Text(
                  '${ticket.price.toStringAsFixed(0)} ₺',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 7, // 10'dan 7'ye küçültüldü
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showComplaintDialog() {
    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📝 Dilek/Şikayet'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: messageController,
              decoration: const InputDecoration(
                hintText: 'Mesajınızı yazın...',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (messageController.text.isNotEmpty) {
                _complaintService.addComplaint(
                  message: messageController.text,
                  senderName: _authService.currentUser!.name,
                  senderPhone: _authService.currentUser!.phone,
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✅ Mesajınız gönderildi')),
                );
              }
            },
            child: const Text('Gönder'),
          ),
        ],
      ),
    );
  }

  // Kampanyalar sayfası
  Widget _buildKampanyalar() {
    // Önce paylaşılan veriyi yükle
    _campaignService.refreshFromSharedData();

    final publishedCampaigns = _campaignService.getPublishedCampaigns();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık ve açıklama
          Row(
            children: [
              const Icon(Icons.campaign, size: 32, color: Colors.deepPurple),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tüm Kampanyalar',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    Text(
                      'Admin tarafından oluşturulan tüm kampanyalar',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              // Yenileme butonu
              IconButton(
                onPressed: () async {
                  await _campaignService.refreshFromSharedData();
                  setState(() {}); // Sayfayı yenile
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('🔄 Kampanyalar yenilendi'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                icon: const Icon(Icons.refresh, color: Colors.deepPurple),
                tooltip: 'Kampanyaları Yenile',
              ),
            ],
          ),

          const SizedBox(height: 24),

          if (publishedCampaigns.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.campaign_outlined,
                        size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      'Henüz kampanya yok',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Admin kampanya oluşturduğunda burada görünecek',
                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 260 / 120,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: publishedCampaigns.length,
                itemBuilder: (context, index) {
                  final campaign = publishedCampaigns[index];
                  return _buildCampaignTicketCard(campaign);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCampaignTicketCard(Campaign campaign) {
    return Container(
      width: 260,
      height: 120,
      decoration: BoxDecoration(
        color: const Color(0xFFF8D7E3), // Pembe arka plan
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.pink.shade200, width: 1),
      ),
      child: Stack(
        children: [
          // Ana içerik
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Üst kısım
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sol - Bilet fiyatı
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'BİLET FİYATI',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            '${campaign.ticketPrice.toStringAsFixed(0)} TL',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Orta - Kampanya adı
                    Expanded(
                      child: Center(
                        child: Text(
                          campaign.name.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF6A1B9A),
                            letterSpacing: 1.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),

                    // Sağ - Çekiliş tarihi ve numara
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'ÇEKİLİŞ TARİHİ',
                                style: TextStyle(
                                  fontSize: 6,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                '${campaign.drawDate.day}/${campaign.drawDate.month}/${campaign.drawDate.year}',
                                style: const TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'NO: ${campaign.id.substring(0, 6).toUpperCase()}',
                            style: const TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Orta kısım - İkramiye
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('🕊️',
                        style:
                            TextStyle(fontSize: 24)), // 16'dan 24'e büyütüldü
                    const SizedBox(width: 6),
                    const Text(
                      'ikramiye',
                      style: TextStyle(
                        fontSize: 14, // 10'dan 14'e büyütüldü
                        color: Colors.black54,
                        fontWeight: FontWeight.bold, // Bold eklendi
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      campaign.prizeAmount,
                      style: const TextStyle(
                        fontSize: 16, // 14'ten 16'ya büyütüldü
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),

                // Alt kısım - Bir alt/üst ikramiye
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            const Text(
                              'Bir Alt Numaralı Bilete',
                              style:
                                  TextStyle(fontSize: 7, color: Colors.black54),
                            ),
                            Text(
                              campaign.lowerPrize.isNotEmpty
                                  ? campaign.lowerPrize
                                  : '100 TL',
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 20,
                        color: Colors.black26,
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            const Text(
                              'Bir Üst Numaralı Bilete',
                              style:
                                  TextStyle(fontSize: 7, color: Colors.black54),
                            ),
                            Text(
                              campaign.upperPrize.isNotEmpty
                                  ? campaign.upperPrize
                                  : '100 TL',
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Alt sarı-siyah çizgili border
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 6,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
                gradient: LinearGradient(
                  colors: [
                    Colors.yellow,
                    Colors.black,
                    Colors.yellow,
                    Colors.black,
                    Colors.yellow,
                    Colors.black,
                    Colors.yellow,
                    Colors.black,
                  ],
                  stops: [0.0, 0.125, 0.25, 0.375, 0.5, 0.625, 0.75, 0.875],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Yeni Kampanyalar sayfası
  Widget _buildYeniKampanyalar() {
    // Önce paylaşılan veriyi yükle
    _campaignService.refreshFromSharedData();

    final publishedCampaigns = _campaignService.getPublishedCampaigns();

    // Debug: Konsola yazdır
    print('🔍 Debug - isListPublished: ${_campaignService.isListPublished}');
    print('🔍 Debug - publishedCampaigns count: ${publishedCampaigns.length}');
    print(
        '🔍 Debug - all campaigns count: ${_campaignService.campaigns.length}');

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık ve açıklama
          Row(
            children: [
              const Icon(Icons.new_releases, size: 32, color: Colors.purple),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Yeni Kampanyalar',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    Text(
                      'Admin tarafından yayınlanan kampanyalar',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              // Yenileme butonu
              IconButton(
                onPressed: () async {
                  await _campaignService.refreshFromSharedData();
                  setState(() {}); // Sayfayı yenile
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('🔄 Kampanyalar yenilendi'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                icon: const Icon(Icons.refresh, color: Colors.purple),
                tooltip: 'Kampanyaları Yenile',
              ),
            ],
          ),

          const SizedBox(height: 24),

          if (publishedCampaigns.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.campaign_outlined,
                        size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      'Henüz yayınlanan kampanya yok',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Admin yeni kampanya yayınladığında burada görünecek',
                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: publishedCampaigns.length,
                itemBuilder: (context, index) {
                  final campaign = publishedCampaigns[index];
                  final availableTickets = _ticketService
                      .getAvailableTicketsForCampaign(campaign.id);
                  final soldTickets =
                      _ticketService.getSoldTicketsForCampaign(campaign.id);

                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Kampanya başlığı
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.purple.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.purple),
                                ),
                                child: const Text(
                                  'YENİ KAMPANYA',
                                  style: TextStyle(
                                    color: Colors.purple,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                'Çekiliş: ${campaign.drawDate.day}/${campaign.drawDate.month}/${campaign.drawDate.year}',
                                style: TextStyle(
                                  color: Colors.orange[700],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Kampanya adı
                          Text(
                            campaign.name,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Kampanya detayları
                          Row(
                            children: [
                              Expanded(
                                child: _buildCampaignInfoCard(
                                  'Bilet Fiyatı',
                                  '${campaign.ticketPrice.toStringAsFixed(0)} ₺',
                                  Icons.local_offer,
                                  Colors.green,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildCampaignInfoCard(
                                  'İkramiye',
                                  campaign.prizeAmount,
                                  Icons.emoji_events,
                                  Colors.amber,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildCampaignInfoCard(
                                  'Müsait Bilet',
                                  '${availableTickets.length}',
                                  Icons.confirmation_number,
                                  Colors.blue,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Aksiyon butonları
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: availableTickets.isNotEmpty
                                      ? () => _selectRandomTicket(campaign)
                                      : null,
                                  icon: const Icon(Icons.casino),
                                  label: const Text('Şansını Dene'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.purple,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () =>
                                      _showCampaignTickets(campaign),
                                  icon: const Icon(Icons.list),
                                  label: const Text('Biletleri Gör'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCampaignInfoCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showCampaignTickets(campaign) {
    final availableTickets =
        _ticketService.getAvailableTicketsForCampaign(campaign.id);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('🎫 ${campaign.name} - Biletler'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: Column(
            children: [
              Text(
                'Müsait Biletler: ${availableTickets.length}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              if (availableTickets.isEmpty)
                const Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.no_accounts, size: 48, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('Bu kampanyada müsait bilet kalmamış'),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount:
                          4, // 3'ten 4'e çıkarıldı - daha fazla bilet yan yana
                      childAspectRatio:
                          0.9, // 1.2'den 0.9'a düşürüldü - %70 daha küçük
                      crossAxisSpacing: 6, // Boşluk küçültüldü
                      mainAxisSpacing: 6,
                    ),
                    itemCount: availableTickets.length,
                    itemBuilder: (context, index) {
                      final ticket = availableTickets[index];
                      return _buildAvailableTicketCard(ticket);
                    },
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
          if (availableTickets.isNotEmpty)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _selectRandomAvailableTicket(availableTickets);
              },
              icon: const Icon(Icons.casino),
              label: const Text('Rastgele Seç'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  void _logout() async {
    print('🚪 Logout butonuna basıldı');
    try {
      await _authService.logout();
      print('✅ AuthService logout tamamlandı');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
      print('✅ LoginScreen\'e yönlendirildi');
    } catch (e) {
      print('❌ Logout hatası: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Çıkış yapılamadı: $e')),
      );
    }
  }

  // Bilet silme fonksiyonları
  void _deleteSelectedTickets() {
    if (_selectedTicketIds.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('⚠️ Biletleri Sil'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                '${_selectedTicketIds.length} bileti silmek istediğinizden emin misiniz?'),
            const SizedBox(height: 12),
            const Text('Bu işlem geri alınamaz!',
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _performBulkDelete();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  void _performBulkDelete() {
    final user = _authService.currentUser!;
    final deletedCount = _selectedTicketIds.length;

    // Biletleri sil
    for (final ticketId in _selectedTicketIds) {
      _ticketService.updateTicketStatus(
        ticketId: ticketId,
        status: TicketStatus.cancelled,
      );
    }

    setState(() {
      _selectedTicketIds.clear();
      _isSelectionMode = false;
    });

    _saveData(); // Veriyi kaydet

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text('✅ $deletedCount bilet başarıyla silindi!'),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showTicketOptions(Ticket ticket) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.info, color: Colors.blue),
              title: const Text('Bilet Detayları'),
              onTap: () {
                Navigator.pop(context);
                _showTicketDetails(ticket);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Bileti Sil'),
              onTap: () {
                Navigator.pop(context);
                _confirmSingleDelete(ticket);
              },
            ),
            if (ticket.status == TicketStatus.available)
              ListTile(
                leading: const Icon(Icons.share, color: Colors.green),
                title: const Text('Bileti Paylaş'),
                onTap: () {
                  Navigator.pop(context);
                  _shareTicket(ticket);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showTicketDetails(Ticket ticket) {
    final campaign = _campaignService.getCampaign(ticket.campaignId);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🎫 Bilet Detayları'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Bilet No', ticket.numbersFormatted),
            if (campaign != null) _buildDetailRow('Kampanya', campaign.name),
            _buildDetailRow('Fiyat', '${ticket.price} ₺'),
            _buildDetailRow('Durum', ticket.statusText),
            if (ticket.buyerName != null)
              _buildDetailRow('Alıcı', ticket.buyerName!),
            if (ticket.soldAt != null)
              _buildDetailRow('Satış Tarihi',
                  '${ticket.soldAt!.day}/${ticket.soldAt!.month}/${ticket.soldAt!.year}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _confirmSingleDelete(Ticket ticket) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Bileti Sil'),
        content: Text(
            '${ticket.numbersFormatted} numaralı bileti silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _ticketService.updateTicketStatus(
                ticketId: ticket.id,
                status: TicketStatus.cancelled,
              );
              setState(() {});
              _saveData();

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Bilet başarıyla silindi'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  void _shareTicket(Ticket ticket) {
    // Bilet paylaşma özelliği
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('📤 Bilet numarası kopyalandı: ${ticket.numbersFormatted}'),
        backgroundColor: Colors.green,
      ),
    );
  }
}

// Bilet arka plan deseni painter
class TicketPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    // Diagonal çizgiler
    canvas.save();
    canvas.rotate(0.5);
    for (double i = -size.width; i < size.width * 2; i += 20) {
      canvas.drawRect(
        Rect.fromLTWH(i, 0, 2, size.height * 2),
        paint,
      );
    }
    canvas.restore();

    // Güvenlik deseni - küçük noktalar
    final dotPaint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..style = PaintingStyle.fill;

    for (double x = 0; x < size.width; x += 15) {
      for (double y = 0; y < size.height; y += 15) {
        canvas.drawCircle(Offset(x, y), 1.5, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// QR kod simülasyonu painter
class QRPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    final cellSize = size.width / 7;
    final random = Random(42); // Sabit seed ile her zaman aynı desen

    // QR kod benzeri rastgele desen
    for (int x = 0; x < 7; x++) {
      for (int y = 0; y < 7; y++) {
        // Köşe işaretleyicileri
        if ((x < 3 && y < 3) || (x > 3 && y < 3) || (x < 3 && y > 3)) {
          if (x == 0 || y == 0 || x == 2 || y == 2 || (x == 1 && y == 1)) {
            canvas.drawRect(
              Rect.fromLTWH(x * cellSize, y * cellSize, cellSize, cellSize),
              paint,
            );
          }
        } else {
          // Rastgele desen
          if (random.nextBool()) {
            canvas.drawRect(
              Rect.fromLTWH(x * cellSize, y * cellSize, cellSize, cellSize),
              paint,
            );
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 🔧 GÜNCELLENDİ: Eksik metodlar - Bayi Dashboard Supabase entegrasyonu
extension _BayiDashboardMethods on _BayiDashboardState {
  Widget _buildSansliHissediyorum() {
    // 🆕 YENİ: Gerçek zamanlı Supabase biletlerinden müsait olanları al
    final availableTickets = _realtimeTickets
        .where((t) => t.status == TicketStatus.available)
        .toList();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Text(
            '🍀 Şansını Dene!',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            'Admin\'in oluşturduğu biletlerden birini seçin',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // 🆕 YENİ: Gerçek zamanlı müsait bilet sayısı
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.blue, Colors.blueAccent],
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.confirmation_number, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  '${availableTickets.length} adet müsait bilet (Gerçek Zamanlı)',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.sync, color: Colors.blue, size: 16),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          if (availableTickets.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.hourglass_empty,
                        size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      'Şu anda müsait bilet bulunmuyor',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Admin yeni biletler eklediğinde gerçek zamanlı olarak burada görünecek',
                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () async {
                        setState(() {
                          _isLoadingTickets = true;
                        });
                        await _supabaseService.testConnection();
                      },
                      icon: _isLoadingTickets
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.refresh),
                      label: const Text('Yenile'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: Column(
                children: [
                  // Rastgele bilet seç butonu
                  ElevatedButton.icon(
                    onPressed: () =>
                        _selectRandomAvailableTicket(availableTickets),
                    icon: const Icon(Icons.casino),
                    label: const Text('Rastgele Bilet Seç'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Müsait biletlerin grid listesi - Scrollbar ile
                  Expanded(
                    child: Scrollbar(
                      thumbVisibility: true,
                      trackVisibility: true,
                      child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 6,
                          childAspectRatio: 0.7,
                          crossAxisSpacing: 6,
                          mainAxisSpacing: 6,
                        ),
                        itemCount: availableTickets.length,
                        itemBuilder: (context, index) {
                          final ticket = availableTickets[index];
                          return _buildAvailableTicketCard(ticket);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvailableTicketCard(Ticket ticket) {
    return GestureDetector(
      onTap: () => _selectSpecificTicket(ticket),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.green, Colors.teal],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Bilet',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: Center(
                      child: Text(
                        ticket.numbersFormatted,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Text(
                    '${ticket.price.toStringAsFixed(0)}₺',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            Positioned(
              top: 2,
              right: 2,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.touch_app,
                  color: Colors.green,
                  size: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectSpecificTicket(Ticket ticket) {
    _showTicketSelectionDialog(ticket);
  }

  void _showTicketSelectionDialog(Ticket ticket) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🍀 Bilet Seçildi!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Seçilen bilet numaraları:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green),
              ),
              child: Column(
                children: [
                  Text(
                    ticket.numbersFormatted,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Fiyat: ${ticket.price.toStringAsFixed(0)} ₺',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.green[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Bu bileti almak istediğinizden emin misiniz?\nAdmin onayından sonra biletiniz olacak.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[700]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              // 🆕 YENİ: Supabase üzerinden bilet talebi oluştur
              final success = await _ticketService.createTicketRequest(
                ticketId: ticket.id,
                fromUserId: _authService.currentUser!.id,
                fromUserName: _authService.currentUser!.name,
              );

              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        '✅ Bilet talebi gönderildi! Admin onayını bekliyor.\n📡 Durum değişiklikleri gerçek zamanlı bildirilecek.'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 4),
                  ),
                );
                setState(() {}); // Listeyi güncelle
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('❌ Bilet talebi gönderilemedi')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Bilet Al'),
          ),
        ],
      ),
    );
  }
}
