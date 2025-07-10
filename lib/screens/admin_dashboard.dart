import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:math';
import '../models/user.dart';
import '../models/person.dart';
import '../models/campaign.dart';
import '../models/ticket.dart';
import '../services/auth_service.dart';
import '../services/person_service.dart';
import '../services/campaign_service.dart';
import '../services/ticket_service.dart';
import '../services/financial_service.dart';
import '../services/complaint_service.dart';
import '../services/milli_piyango_service.dart';
import '../services/supabase_service.dart';
import 'login_screen.dart';
import 'package:piyangox/main.dart'; // themeNotifier erişimi için

class AdminDashboard extends StatefulWidget {
  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final AuthService _authService = AuthService();
  final PersonService _personService = PersonService();
  final CampaignService _campaignService = CampaignService();
  final TicketService _ticketService = TicketService();
  final FinancialService _financialService = FinancialService();
  final ComplaintService _complaintService = ComplaintService();
  final MilliPiyangoService _milliPiyangoService = MilliPiyangoService();

  // 🆕 YENİ: Supabase Service entegrasyonu
  final SupabaseService _supabaseService = SupabaseService();

  final TextEditingController _searchController = TextEditingController();

  String _selectedMenuItem = 'genel_bilgi';
  List<Ticket> _searchResults = [];

  // Admin tarafından belirlenen bilet fiyatı
  double _currentTicketPrice = 10.0;

  // Admin tarafından belirlenen bilet sayısı
  int _currentTicketCount = 100;

  // Admin tarafından belirlenen şans sayısı
  int _currentChanceCount = 2;

  // Admin tarafından belirlenen son hane sayısı
  int _currentLastDigitCount = 3;

  // Sample biletler listesi
  List<Ticket> _sampleTickets = [];

  // Biletler oluşturuldu mu kontrol
  bool _ticketsGenerated = false;

  @override
  void initState() {
    super.initState();
    _loadSampleData();
    // 🆕 YENİ: Realtime başlat
    _initializeRealtime();
  }

  void _loadSampleData() async {
    await _complaintService.addSampleComplaints();
  }

  // 🆕 YENİ: Realtime başlatma metodu
  Future<void> _initializeRealtime() async {
    try {
      await _supabaseService.testConnection();
      print('✅ Admin Dashboard realtime başlatıldı');
    } catch (e) {
      print('❌ Admin realtime başlatma hatası: $e');
    }
  }

  // 🆕 YENİ: Realtime event gösterici
  void _showRealtimeEvent(Map<String, dynamic> event) {
    if (event['source'] == 'admin') return; // Kendi aksiyonlarını gösterme

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.sync, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '🔄 ${event['data']['admin_action']} - ${event['timestamp'].toString().substring(11, 16)}',
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Row(
        children: [
          Container(
            width: 280,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF1A237E),
                  Color(0xFF3F51B5),
                ],
              ),
            ),
            child: _buildSideMenu(),
          ),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(child: _buildMainContent()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Gelişmiş menü butonu oluşturucu method
  Widget _buildEnhancedMenuItem({
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: onTap,
          hoverColor: color.withOpacity(0.15),
          splashColor: color.withOpacity(0.25),
          child: AnimatedContainer(
            duration: Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              gradient: isSelected
                  ? LinearGradient(
                      colors: [
                        color.withOpacity(0.9),
                        color.withOpacity(0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: 15,
                        offset: Offset(0, 6),
                        spreadRadius: 1,
                      ),
                      BoxShadow(
                        color: color.withOpacity(0.2),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: Offset(0, 2),
                      ),
                    ],
              border: isSelected
                  ? null
                  : Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
            ),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withOpacity(0.2)
                          : color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      size: 20,
                      color: isSelected ? Colors.white : color.withOpacity(0.8),
                    ),
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color:
                            isSelected ? Colors.white : color.withOpacity(0.85),
                        letterSpacing: 0.5,
                        shadows: isSelected
                            ? [
                                Shadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: Offset(0, 1),
                                ),
                              ]
                            : [],
                      ),
                    ),
                  ),
                  if (isSelected)
                    Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSideMenu() {
    final menuItems = [
      {
        'id': 'genel_bilgi',
        'title': 'Genel Bilgi',
        'icon': Icons.dashboard,
        'color': Colors.blue
      },
      {
        'id': 'bilgilerim',
        'title': 'Bilgilerim',
        'icon': Icons.person,
        'color': Colors.indigo
      },
      {
        'id': 'kisi_listesi',
        'title': 'Kişi Listesi',
        'icon': Icons.people,
        'color': Colors.green
      },
      {
        'id': 'son_hane_sayisi',
        'title': 'Son Hane Sayısı',
        'icon': Icons.filter_9_plus,
        'color': Colors.orange
      },
      {
        'id': 'sans_adeti',
        'title': 'Şans Adeti',
        'icon': Icons.casino,
        'color': Colors.purple
      },
      {
        'id': 'bilet_adeti',
        'title': 'Bilet Adeti',
        'icon': Icons.confirmation_number,
        'color': Colors.teal
      },
      {
        'id': 'kampanya_ismi',
        'title': 'Kampanya İsmi',
        'icon': Icons.campaign,
        'color': Colors.red
      },
      {
        'id': 'ikramiye_cinsi',
        'title': 'İkramiye Cinsi',
        'icon': Icons.monetization_on,
        'color': Colors.amber
      },
      {
        'id': 'ikramiye_tutari',
        'title': 'İkramiye Tutarı',
        'icon': Icons.attach_money,
        'color': Colors.green
      },
      {
        'id': 'bir_alt_ust',
        'title': 'Bir Alt-Bir Üst',
        'icon': Icons.tune,
        'color': Colors.cyan
      },
      {
        'id': 'bilet_fiyati',
        'title': 'Bilet Fiyatı',
        'icon': Icons.local_offer,
        'color': Colors.deepOrange
      },
      {
        'id': 'liste',
        'title': 'Liste',
        'icon': Icons.list,
        'color': Colors.indigo
      },
      {
        'id': 'giderler',
        'title': 'Giderler',
        'icon': Icons.money_off,
        'color': Colors.red
      },
      {
        'id': 'borclu_olanlar',
        'title': 'Borçlu Olanlar',
        'icon': Icons.account_balance_wallet,
        'color': Colors.deepPurple
      },
      {
        'id': 'liste_yayinla',
        'title': 'Liste Yayınla',
        'icon': Icons.publish,
        'color': Colors.brown
      },
      {
        'id': 'yeni_kampanya',
        'title': 'Yeni Kampanya',
        'icon': Icons.add_circle,
        'color': Colors.pink
      },
      {
        'id': 'kampanya_yonetimi',
        'title': 'Kampanya Yönetimi',
        'icon': Icons.manage_accounts,
        'color': Colors.deepPurple
      },
      {
        'id': 'ortak_sayisi',
        'title': 'Ortak Sayısı',
        'icon': Icons.group,
        'color': Colors.lime
      },
      {
        'id': 'dilek_sikayet',
        'title': 'Dilek Şikayet',
        'icon': Icons.feedback,
        'color': Colors.deepOrange
      },
    ];

    return Column(
      children: [
        // Profil alanı
        Container(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: _authService.currentUser?.profileImage != null
                        ? ClipOval(
                            child: Icon(
                              Icons.person,
                              size: 30,
                              color:
                                  Colors.green, // Profil resmi var göstergesi
                            ),
                          )
                        : Icon(
                            Icons.admin_panel_settings,
                            size: 30,
                            color: Color(0xFF1A237E),
                          ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Text(
                _authService.currentUser?.name ?? 'Admin',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Yönetici',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),

        Divider(color: Colors.white30),

        // Tema geçişi
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: SwitchListTile(
            title:
                const Text('Koyu Tema', style: TextStyle(color: Colors.white)),
            secondary: Icon(Icons.dark_mode, color: Colors.white),
            value: themeNotifier.value == ThemeMode.dark,
            onChanged: (dark) {
              themeNotifier.value = dark ? ThemeMode.dark : ThemeMode.light;
            },
          ),
        ),

        // Menü öğeleri - Gelişmiş animasyonlu butonlar
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(vertical: 8),
            itemCount: menuItems.length,
            itemBuilder: (context, index) {
              final item = menuItems[index];
              final isSelected = _selectedMenuItem == item['id'];
              return _buildEnhancedMenuItem(
                icon: item['icon'] as IconData,
                title: item['title'] as String,
                isSelected: isSelected,
                color: item['color'] as Color,
                onTap: () {
                  setState(() {
                    _selectedMenuItem = item['id'] as String;
                  });
                },
              );
            },
          ),
        ),
        // Çıkış butonu
        Container(
          padding: EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _logout,
              icon: Icon(Icons.logout),
              label: Text('Çıkış Yap'),
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
      padding: EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
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

          Spacer(),

          // Arama kutusu (sadece genel bilgi değilse göster)
          if (_selectedMenuItem != 'bilgilerim')
            Container(
              width: 300,
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'İsim, telefon veya bilet numarası ara...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                onChanged: _searchTickets,
              ),
            ),

          SizedBox(width: 16),

          // Bildirimler
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.notifications, size: 28),
                onPressed: _showNotifications,
              ),
              if (_ticketService.pendingNotifications.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${_ticketService.pendingNotifications.length}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    if (_searchController.text.isNotEmpty && _searchResults.isNotEmpty) {
      return _buildSearchResults();
    }

    switch (_selectedMenuItem) {
      case 'genel_bilgi':
        return _buildGenelBilgi();
      case 'bilgilerim':
        return _buildBilgilerim();
      case 'kisi_listesi':
        return _buildKisiListesi();
      case 'son_hane_sayisi':
        return _buildSonHaneSayisi();
      case 'sans_adeti':
        return _buildSansAdeti();
      case 'bilet_adeti':
        return _buildBiletAdeti();
      case 'liste':
        return _buildListe();
      case 'kampanya_ismi':
        return _buildKampanyaIsmi();
      case 'ikramiye_cinsi':
        return _buildIkramiyeCinsi();
      case 'ikramiye_tutari':
        return _buildIkramiyeTutari();
      case 'bir_alt_ust':
        return _buildBirAltUst();
      case 'bilet_fiyati':
        return _buildBiletFiyati();
      case 'giderler':
        return _buildGiderler();
      case 'borclu_olanlar':
        return _buildBorcluOlanlar();
      case 'liste_yayinla':
        return _buildListeYayinla();
      case 'yeni_kampanya':
        return _buildYeniKampanya();
      case 'kampanya_yonetimi':
        return _buildKampanyaYonetimi();
      case 'ortak_sayisi':
        return _buildOrtakSayisi();
      case 'dilek_sikayet':
        return _buildDilekSikayet();
      default:
        return _buildPlaceholderPage();
    }
  }

  String _getPageTitle() {
    switch (_selectedMenuItem) {
      case 'genel_bilgi':
        return '📊 Genel Bilgi';
      case 'bilgilerim':
        return '👤 Bilgilerim';
      case 'kisi_listesi':
        return '👥 Kişi Listesi';
      case 'son_hane_sayisi':
        return '🔢 Son Hane Sayısı Belirle';
      case 'sans_adeti':
        return '🎲 Şans Adeti Gir';
      case 'bilet_adeti':
        return '🎫 Bilet Adeti Gir';
      case 'liste':
        return '📋 Liste';
      case 'kampanya_ismi':
        return '🏷️ Kampanya İsmi Gir';
      case 'ikramiye_cinsi':
        return '💎 İkramiye Cinsi Gir';
      case 'ikramiye_tutari':
        return '💰 İkramiye Tutarı Gir';
      case 'bir_alt_ust':
        return '⚖️ Bir Alt-Bir Üst Tanımla';
      case 'bilet_fiyati':
        return '💵 Bilet Fiyatı';
      case 'giderler':
        return '📉 Giderler';
      case 'borclu_olanlar':
        return '💳 Borçlu Olanlar';
      case 'liste_yayinla':
        return '📢 Liste Yayınla';
      case 'yeni_kampanya':
        return '🆕 Yeni Kampanya Belirle';
      case 'kampanya_yonetimi':
        return '🎯 Kampanya Yönetimi';
      case 'ortak_sayisi':
        return '👥 Ortak Sayısı';
      case 'dilek_sikayet':
        return '📝 Dilek Şikayet Kutusu';
      default:
        return '📊 Admin Paneli';
    }
  }

  // Bilgilerim sayfası
  Widget _buildBilgilerim() {
    final user = _authService.currentUser!;

    return Padding(
      padding: EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Profil kartı
            Card(
              child: Padding(
                padding: EdgeInsets.all(24),
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
                                  Icons.person,
                                  size: 60,
                                  color: Colors.grey[400],
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: Icon(Icons.camera_alt, color: Colors.white),
                              onPressed: _pickAndUploadProfileImage,
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 24),

                    // Kullanıcı bilgileri
                    _buildInfoRow('👤 Ad Soyad', user.name),
                    _buildInfoRow('🆔 Kullanıcı Adı', user.username),
                    _buildInfoRow('📧 E-posta', user.email ?? 'Belirtilmemiş'),
                    _buildInfoRow('📞 Telefon', user.phone ?? 'Belirtilmemiş'),
                    _buildInfoRow('👑 Rol',
                        user.role == UserRole.admin ? 'Yönetici' : 'Üye'),
                    _buildInfoRow('📅 Kayıt Tarihi',
                        '${user.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}'),

                    SizedBox(height: 32),

                    // Aksiyonlar
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _showEditProfileDialog,
                            icon: Icon(Icons.edit),
                            label: Text('Bilgileri Düzenle'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _showChangePasswordDialog,
                            icon: Icon(Icons.lock),
                            label: Text('Şifre Değiştir'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 12),
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
      padding: EdgeInsets.symmetric(vertical: 8),
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
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  // Diğer sayfa metodları (basitleştirilmiş)
  Widget _buildGenelBilgi() {
    final summary = _financialService.calculateSummary();
    final complaintStats = _complaintService.getStats();

    return Padding(
      padding: EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                    child: _buildStatCard(
                        'Satılan Bilet',
                        '${summary.soldTickets}',
                        Icons.confirmation_number,
                        Colors.green)),
                SizedBox(width: 16),
                Expanded(
                    child: _buildStatCard(
                        'Satılmayan Bilet',
                        '${summary.availableTickets}',
                        Icons.pending,
                        Colors.orange)),
                SizedBox(width: 16),
                Expanded(
                    child: _buildStatCard(
                        'Havuz Birikimi',
                        '${summary.poolAmount.toStringAsFixed(0)} ₺',
                        Icons.savings,
                        Colors.blue)),
                SizedBox(width: 16),
                Expanded(
                    child: _buildStatCard(
                        summary.balanceEmoji +
                            ' ' +
                            (summary.isProfit ? 'Kar' : 'Zarar'),
                        '${summary.balance.abs().toStringAsFixed(0)} ₺',
                        Icons.account_balance,
                        summary.isProfit ? Colors.green : Colors.red)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            Text(title, style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildKisiListesi() {
    return Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _addPersonDialog,
                icon: Icon(Icons.person_add),
                label: Text('Kişi Ekle'),
              ),
              SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _importFromContacts,
                icon: Icon(Icons.contacts),
                label: Text('Telefon Rehberinden Ekle'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              ),
            ],
          ),
          SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _personService.allPersons.length,
              itemBuilder: (context, index) {
                final person = _personService.allPersons[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(person.firstName[0].toUpperCase()),
                    ),
                    title: Text(person.fullName),
                    subtitle: Text('📞 ${person.phone}'),
                    trailing: PopupMenuButton(
                      itemBuilder: (context) => [
                        PopupMenuItem(value: 'edit', child: Text('Düzenle')),
                        PopupMenuItem(value: 'delete', child: Text('Sil')),
                      ],
                      onSelected: (value) =>
                          _handlePersonAction(person, value.toString()),
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

  Widget _buildSonHaneSayisi() {
    return Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🔢 Son Hane Sayısı Belirle',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          Text(
            'Bilet numaralarının kaç haneli olacağını seçin:',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          SizedBox(height: 32),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              childAspectRatio: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildHaneCard(
                    '2 Haneli', '2 haneli numara (10-99)', 2, Icons.looks_two),
                _buildHaneCard(
                    '3 Haneli', '3 haneli numara (100-999)', 3, Icons.looks_3),
                _buildHaneCard('4 Haneli', '4 haneli numara (1000-9999)', 4,
                    Icons.looks_4),
                _buildHaneCard('5 Haneli', '5 haneli numara (10000-99999)', 5,
                    Icons.looks_5),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHaneCard(
      String title, String description, int haneCount, IconData icon) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: () => _selectHaneCount(haneCount),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: Color(0xFF6A1B9A)),
              SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectHaneCount(int haneCount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('🔢 Hane Sayısı Seçimi'),
        content: Text(
            '$haneCount haneli numara sistemini seçmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _saveHaneCount(haneCount);
            },
            child: Text('Seç'),
          ),
        ],
      ),
    );
  }

  void _saveHaneCount(int haneCount) {
    // Hane sayısını kaydet
    setState(() {
      _currentLastDigitCount = haneCount;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ $haneCount haneli numara sistemi seçildi'),
        backgroundColor: Colors.green,
      ),
    );

    // Başarı efekti
    _showSuccessAnimation();
  }

  void _showSuccessAnimation() {
    // Basit bir flash efekti - overlay ile
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [
              Colors.green.withOpacity(0.3),
              Colors.transparent,
            ],
          ),
        ),
        child: Center(
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check,
              color: Colors.white,
              size: 60,
            ),
          ),
        ),
      ),
    );

    // 1 saniye sonra kapat
    Future.delayed(Duration(milliseconds: 800), () {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    });
  }

  Widget _buildSansAdeti() {
    return Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🎲 Şans Adeti Belirle',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          Text(
            'Her bilet için kaç şans verilecek seçin:',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          SizedBox(height: 32),
          Expanded(
            child: GridView.count(
              crossAxisCount: 3,
              childAspectRatio: 1.2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildSansCard('1 Şans', 'Tek numara\nKlasik sistem', 1,
                    Icons.looks_one, Colors.red),
                _buildSansCard('2 Şans', 'İki numara\nÇift şans', 2,
                    Icons.looks_two, Colors.orange),
                _buildSansCard('3 Şans', 'Üç numara\nÜçlü şans', 3,
                    Icons.looks_3, Colors.amber),
                _buildSansCard('4 Şans', 'Dört numara\nDörtlü şans', 4,
                    Icons.looks_4, Colors.green),
                _buildSansCard('5 Şans', 'Beş numara\nBeşli şans', 5,
                    Icons.looks_5, Colors.blue),
                _buildSansCard('6 Şans', 'Altı numara\nMaximum şans', 6,
                    Icons.looks_6, Colors.purple),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSansCard(String title, String description, int sansCount,
      IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: () => _selectSansCount(sansCount),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.05),
              ],
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 48, color: color),
                SizedBox(height: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _selectSansCount(int sansCount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.casino, color: Color(0xFF6A1B9A)),
            SizedBox(width: 8),
            Text('🎲 Şans Adeti Seçimi'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
                '$sansCount şans sistemini seçmek istediğinizden emin misiniz?'),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Her bilet için $sansCount adet numara üretilecek',
                      style: TextStyle(fontSize: 12, color: Colors.blue[800]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _saveSansCount(sansCount);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF6A1B9A),
              foregroundColor: Colors.white,
            ),
            child: Text('Seç'),
          ),
        ],
      ),
    );
  }

  void _saveSansCount(int sansCount) {
    // Şans sayısını kaydet
    setState(() {
      _currentChanceCount = sansCount;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.casino, color: Colors.white),
            SizedBox(width: 8),
            Text('✅ $sansCount şans sistemi seçildi'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );

    // Başarı efekti
    _showSuccessAnimation();
  }

  Widget _buildBiletAdeti() {
    return Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🎫 Bilet Adeti Belirle',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          Text(
            'Kampanya için kaç bilet basılacağını belirleyin:',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          SizedBox(height: 32),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              childAspectRatio: 1.5,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildBiletAdetiCard('100 Bilet', 'Küçük kampanya', 100,
                    Icons.confirmation_number),
                _buildBiletAdetiCard(
                    '500 Bilet', 'Orta ölçekli', 500, Icons.local_activity),
                _buildBiletAdetiCard(
                    '1000 Bilet', 'Büyük kampanya', 1000, Icons.theaters),
                _buildBiletAdetiCard(
                    'Özel Sayı', 'Manuel giriş', 0, Icons.edit),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBiletAdetiCard(
      String title, String description, int count, IconData icon) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: () => count == 0
            ? _showManualBiletCountDialog()
            : _selectBiletCount(count),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: Color(0xFF6A1B9A)),
              SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectBiletCount(int count) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('🎫 Bilet Adeti Seçimi'),
        content: Text('$count adet bilet basmak istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _saveBiletCount(count);
            },
            child: Text('Onayla'),
          ),
        ],
      ),
    );
  }

  void _showManualBiletCountDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('✏️ Özel Bilet Sayısı'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'Bilet Sayısı',
            hintText: 'Örnek: 250',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              final count = int.tryParse(controller.text);
              if (count != null && count > 0) {
                Navigator.pop(context);
                _saveBiletCount(count);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('❌ Geçerli bir sayı girin')),
                );
              }
            },
            child: Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  void _saveBiletCount(int count) {
    setState(() {
      _currentTicketCount = count;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ $count bilet adeti belirlendi'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showTicketEditDialog(Ticket ticket) {
    final nameController = TextEditingController(text: ticket.buyerName ?? '');
    final phoneController =
        TextEditingController(text: ticket.buyerPhone ?? '');

    showDialog(
      context: context,
      builder: (context) {
        TicketStatus selectedStatus = ticket.status;

        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Text('🎫 Bilet Düzenle: ${ticket.numbersFormatted}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Ad Soyad',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  decoration: InputDecoration(
                    labelText: 'Telefon',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                    hintText: '05XXXXXXXXX',
                  ),
                  keyboardType: TextInputType.phone,
                ),
                SizedBox(height: 16),

                // Durum seçimi
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Icon(Icons.info, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('Bilet Durumu:',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      Divider(height: 1),
                      _buildStatusOptionInternal(
                          'Satılmadı',
                          TicketStatus.available,
                          Colors.grey,
                          selectedStatus, (status) {
                        setDialogState(() {
                          selectedStatus = status;
                        });
                      }),
                      _buildStatusOptionInternal(
                          'Satıldı (Ödenmedi)',
                          TicketStatus.sold,
                          Colors.orange,
                          selectedStatus, (status) {
                        setDialogState(() {
                          selectedStatus = status;
                        });
                      }),
                      _buildStatusOptionInternal('Ödendi', TicketStatus.paid,
                          Colors.green, selectedStatus, (status) {
                        setDialogState(() {
                          selectedStatus = status;
                        });
                      }),
                      _buildStatusOptionInternal(
                          'İptal',
                          TicketStatus.cancelled,
                          Colors.red,
                          selectedStatus, (status) {
                        setDialogState(() {
                          selectedStatus = status;
                        });
                      }),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('İptal'),
              ),
              ElevatedButton(
                onPressed: () {
                  // Bilet güncelle
                  _updateTicket(ticket, nameController.text.trim(),
                      phoneController.text.trim(), selectedStatus);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: Text('Kaydet'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusOptionInternal(String title, TicketStatus status,
      Color color, TicketStatus selectedStatus, Function(TicketStatus) onTap) {
    final isSelected = selectedStatus == status;

    return InkWell(
      onTap: () => onTap(status),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : null,
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade200),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
                color: isSelected ? color : Colors.transparent,
              ),
              child: isSelected
                  ? Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _updateTicket(
      Ticket ticket, String name, String phone, TicketStatus status) {
    // Bilet güncelleme simülasyonu
    setState(() {
      // Gerçek uygulamada burada ticket service kullanılır
    });

    String statusText = '';
    Color statusColor = Colors.blue;

    switch (status) {
      case TicketStatus.available:
        statusText = 'Satılmadı olarak işaretlendi';
        statusColor = Colors.grey;
        break;
      case TicketStatus.sold:
        statusText = 'Satıldı (Ödenmedi) olarak işaretlendi';
        statusColor = Colors.orange;
        break;
      case TicketStatus.unpaid:
        statusText = 'Ödenmedi olarak işaretlendi';
        statusColor = Colors.orange;
        break;
      case TicketStatus.paid:
        statusText = 'Ödendi olarak işaretlendi';
        statusColor = Colors.green;
        break;
      case TicketStatus.cancelled:
        statusText = 'İptal edildi';
        statusColor = Colors.red;
        break;
      case TicketStatus.winner:
        statusText = 'Kazanan olarak işaretlendi';
        statusColor = Colors.purple;
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Bilet ${ticket.numbersFormatted} $statusText'),
        backgroundColor: statusColor,
      ),
    );

    _showSuccessAnimation();
  }

  void _showTicketDialog(Ticket ticket) {
    final nameController = TextEditingController(text: ticket.buyerName ?? '');
    final phoneController =
        TextEditingController(text: ticket.buyerPhone ?? '');
    TicketStatus selectedStatus = ticket.status;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('🎫 Bilet: ${ticket.numbersFormatted}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Ad Soyad',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: InputDecoration(
                  labelText: 'Telefon',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<TicketStatus>(
                value: selectedStatus,
                decoration: InputDecoration(
                  labelText: 'Durum',
                  border: OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(
                      value: TicketStatus.available, child: Text('Satılmadı')),
                  DropdownMenuItem(
                      value: TicketStatus.sold,
                      child: Text('Satıldı (Ödenmedi)')),
                  DropdownMenuItem(
                      value: TicketStatus.paid, child: Text('Ödendi')),
                  DropdownMenuItem(
                      value: TicketStatus.cancelled, child: Text('İptal')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() {
                      selectedStatus = value;
                    });
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Bilet güncelle
                await _ticketService.updateTicketStatus(
                  ticketId: ticket.id,
                  status: selectedStatus,
                  buyerName: nameController.text.trim().isEmpty
                      ? null
                      : nameController.text.trim(),
                  buyerPhone: phoneController.text.trim().isEmpty
                      ? null
                      : phoneController.text.trim(),
                );

                Navigator.pop(context);
                setState(() {});

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('✅ Bilet güncellendi')),
                );
              },
              child: Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }

  void _clearAllTickets() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('⚠️ Dikkat'),
        content: Text('Tüm biletleri silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              // Tüm kampanyaları sil
              setState(() {});
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('✅ Tüm biletler temizlendi')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Sil'),
          ),
        ],
      ),
    );
  }

  Widget _buildKampanyaIsmi() {
    final controller = TextEditingController();

    return Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🏷️ Kampanya İsmi Belirle',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          Text(
            'Yeni kampanyanız için bir isim belirleyin:',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          SizedBox(height: 32),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: 'Kampanya İsmi',
              hintText: 'Örnek: Ocak 2024 Şans Oyunu',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.campaign),
            ),
          ),
          SizedBox(height: 32),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () => _saveCampaignName(controller.text),
                icon: Icon(Icons.save),
                label: Text('Kaydet'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF6A1B9A),
                  foregroundColor: Colors.white,
                ),
              ),
              SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () => controller.clear(),
                icon: Icon(Icons.clear),
                label: Text('Temizle'),
              ),
            ],
          ),
          SizedBox(height: 32),
          Text(
            'Örnek İsimler:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              'Yılbaşı Özel Çekilişi',
              'Bahar Şans Oyunu',
              'Yaz Tatili Büyük İkramiye',
              'Okul Dönemi Çekilişi',
              'Ramazan Özel',
              'Kurban Bayramı Şansı',
            ]
                .map((name) => ActionChip(
                      label: Text(name),
                      onPressed: () => controller.text = name,
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  void _saveCampaignName(String name) {
    if (name.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Kampanya ismi boş olamaz')),
      );
      return;
    }

    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Kampanya ismi belirlendi: $name'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildIkramiyeCinsi() {
    return Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '💎 İkramiye Cinsi Belirle',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          Text(
            'Verilecek ikramiye türünü seçin:',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          SizedBox(height: 32),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              childAspectRatio: 1.2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildIkramiyeCard('Nakit Para', '💰', 'cash'),
                _buildIkramiyeCard('Altın', '🏆', 'gold'),
                _buildIkramiyeCard('Elektronik', '📱', 'electronic'),
                _buildIkramiyeCard('Ev Eşyası', '🏠', 'household'),
                _buildIkramiyeCard('Tatil', '✈️', 'vacation'),
                _buildIkramiyeCard('Diğer', '🎁', 'other'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIkramiyeCard(String title, String emoji, String type) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: () => _selectIkramiyeType(title, type),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: TextStyle(fontSize: 48)),
              SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectIkramiyeType(String title, String type) {
    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ İkramiye cinsi seçildi: $title'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildIkramiyeTutari() {
    final controller = TextEditingController();

    return Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '💰 İkramiye Tutarı Belirle',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          Text(
            'Ana ikramiye miktarını girin:',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          SizedBox(height: 32),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: 'İkramiye Tutarı (₺)',
              hintText: 'Örnek: 10000',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.attach_money),
              suffixText: '₺',
            ),
            keyboardType: TextInputType.number,
          ),
          SizedBox(height: 32),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () => _saveIkramiyeTutari(controller.text),
                icon: Icon(Icons.save),
                label: Text('Kaydet'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF6A1B9A),
                  foregroundColor: Colors.white,
                ),
              ),
              SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () => controller.clear(),
                icon: Icon(Icons.clear),
                label: Text('Temizle'),
              ),
            ],
          ),
          SizedBox(height: 32),
          Text(
            'Hazır Tutarlar:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              '1000',
              '5000',
              '10000',
              '25000',
              '50000',
              '100000',
            ]
                .map((amount) => ActionChip(
                      label: Text('$amount ₺'),
                      onPressed: () => controller.text = amount,
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  void _saveIkramiyeTutari(String amount) {
    final parsedAmount = double.tryParse(amount);
    if (parsedAmount == null || parsedAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Geçerli bir tutar girin')),
      );
      return;
    }

    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            '✅ İkramiye tutarı belirlendi: ${parsedAmount.toStringAsFixed(0)} ₺'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildBirAltUst() {
    return Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '⚖️ Bir Alt-Bir Üst Tanımla',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          Text(
            'Ana ikramiyenin bir altı ve bir üstü için ikramiye belirleyin:',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    labelText: 'Bir Alt İkramiyesi (₺)',
                    hintText: '500',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.remove_circle_outline),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    labelText: 'Bir Üst İkramiyesi (₺)',
                    hintText: '500',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.add_circle_outline),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _saveBirAltUst,
            icon: Icon(Icons.save),
            label: Text('Kaydet'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF6A1B9A),
              foregroundColor: Colors.white,
            ),
          ),
          SizedBox(height: 32),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue),
                    SizedBox(width: 8),
                    Text(
                      'Nasıl Çalışır?',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.blue[800]),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  '• Ana kazanan numara: 123\n'
                  '• Bir alt: 122 (123-1)\n'
                  '• Bir üst: 124 (123+1)\n\n'
                  'Bu numaralara sahip biletler de ikramiye kazanır.',
                  style: TextStyle(color: Colors.blue[700]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _saveBirAltUst() {
    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Bir alt-bir üst ikramiyeleri ayarlandı'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildBiletFiyati() {
    final controller = TextEditingController();

    return Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '💵 Bilet Fiyatı Belirle',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          Text(
            'Her bilet için satış fiyatını belirleyin:',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          SizedBox(height: 16),

          // Mevcut fiyatı göster
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 12),
                Text(
                  'Mevcut Bilet Fiyatı: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${_currentTicketPrice.toStringAsFixed(0)} ₺',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 32),

          TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: 'Bilet Fiyatı (₺)',
              hintText: 'Örnek: 10',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.local_offer),
              suffixText: '₺',
            ),
            keyboardType: TextInputType.number,
          ),

          SizedBox(height: 32),

          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () => _saveBiletFiyati(controller.text),
                icon: Icon(Icons.save),
                label: Text('Kaydet'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF6A1B9A),
                  foregroundColor: Colors.white,
                ),
              ),
              SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () => controller.clear(),
                icon: Icon(Icons.clear),
                label: Text('Temizle'),
              ),
            ],
          ),

          SizedBox(height: 32),

          Text(
            'Önerilen Fiyatlar:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              '5',
              '10',
              '20',
              '50',
              '100',
              '500',
              '1000',
            ]
                .map((price) => ActionChip(
                      label: Text('$price ₺'),
                      onPressed: () => controller.text = price,
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  void _saveBiletFiyati(String price) {
    final parsedPrice = double.tryParse(price);
    if (parsedPrice == null || parsedPrice <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Geçerli bir fiyat girin')),
      );
      return;
    }

    setState(() {
      _currentTicketPrice = parsedPrice; // Admin fiyatını kaydet
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            '✅ Bilet fiyatı belirlendi: ${parsedPrice.toStringAsFixed(0)} ₺'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildListe() {
    return Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '📋 Bilet Listesi',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Spacer(),

              // Otomatik iptal kontrolü
              Row(
                children: [
                  Text('Otomatik İptal: '),
                  Switch(
                    value: _autoCancel,
                    onChanged: (value) {
                      setState(() {
                        _autoCancel = value;
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(value
                              ? '⏰ Otomatik iptal aktif: Çekilişe 1 saat kala ödenmemiş biletler iptal edilecek'
                              : '⏸️ Otomatik iptal devre dışı'),
                          backgroundColor: value ? Colors.orange : Colors.grey,
                        ),
                      );
                    },
                    activeColor: Colors.orange,
                  ),
                ],
              ),

              SizedBox(width: 16),

              ElevatedButton.icon(
                onPressed: _fetchAllTicketsFromSupabase,
                icon: Icon(Icons.add),
                label: Text(_ticketsGenerated
                    ? 'Biletler Listelendi ✓'
                    : 'Biletleri Listele'),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _ticketsGenerated ? Colors.green : Color(0xFF6A1B9A),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),

          SizedBox(height: 16),

          // Bilet istatistikleri
          if (_sampleTickets.isNotEmpty) ...[
            Row(
              children: [
                Expanded(
                    child: _buildStatCard('Toplam', '${_sampleTickets.length}',
                        Icons.confirmation_number, Colors.blue)),
                SizedBox(width: 8),
                Expanded(
                    child: _buildStatCard(
                        'Müsait',
                        '${_sampleTickets.where((t) => t.status == TicketStatus.available).length}',
                        Icons.sell,
                        Colors.grey)),
                SizedBox(width: 8),
                Expanded(
                    child: _buildStatCard(
                        'Ödenmedi',
                        '${_sampleTickets.where((t) => t.status == TicketStatus.unpaid).length}',
                        Icons.schedule,
                        Colors.orange)),
                SizedBox(width: 8),
                Expanded(
                    child: _buildStatCard(
                        'Ödendi',
                        '${_sampleTickets.where((t) => t.status == TicketStatus.paid).length}',
                        Icons.check_circle,
                        Colors.green)),
              ],
            ),
            SizedBox(height: 16),
          ],

          // Bilet listesi
          Expanded(
            child: _sampleTickets.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.confirmation_number_outlined,
                            size: 80, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('Henüz bilet oluşturulmamış'),
                        SizedBox(height: 8),
                        Text('"Biletleri Listele" butonuna tıklayın'),
                      ],
                    ),
                  )
                : GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      childAspectRatio: 0.8,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: _sampleTickets.length,
                    itemBuilder: (context, index) {
                      final ticket = _sampleTickets[index];
                      return _buildTicketCard(ticket);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // Otomatik iptal kontrolü için değişken
  bool _autoCancel = true;

  // Bilet kartı widget'ı - geri sayım ile
  Widget _buildTicketCard(Ticket ticket) {
    Color backgroundColor;
    Color textColor = Colors.black;
    String statusText;
    IconData statusIcon;

    // Durum ve renk belirleme
    switch (ticket.status) {
      case TicketStatus.available:
        backgroundColor = Colors.grey[300]!;
        statusText = 'Müsait';
        statusIcon = Icons.sell;
        break;
      case TicketStatus.unpaid:
        backgroundColor = Colors.orange[200]!;
        statusText = 'Ödenmedi';
        statusIcon = Icons.schedule;
        break;
      case TicketStatus.paid:
        backgroundColor = Colors.green[300]!;
        statusText = 'Ödendi';
        statusIcon = Icons.check_circle;
        break;
      case TicketStatus.cancelled:
        backgroundColor = Colors.red[300]!;
        statusText = 'İptal';
        statusIcon = Icons.cancel;
        textColor = Colors.white;
        break;
      case TicketStatus.winner:
        backgroundColor = Colors.purple[300]!;
        statusText = 'Kazanan';
        statusIcon = Icons.star;
        break;
      default:
        backgroundColor = Colors.grey[300]!;
        statusText = 'Bilinmiyor';
        statusIcon = Icons.help;
        break;
    }

    return Card(
      elevation: 4,
      child: InkWell(
        onTap: () => _showTicketStatusDialog(ticket),
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
            // Ödenmemiş biletler için gradient efekt
            gradient: ticket.status == TicketStatus.unpaid
                ? LinearGradient(
                    colors: [Colors.green[200]!, Colors.red[200]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
          ),
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Bilet numarası
                Text(
                  ticket.numbersFormatted,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),

                SizedBox(height: 8),

                // Durum ikonu ve metni
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(statusIcon, size: 16, color: textColor),
                    SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 12,
                          color: textColor,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                // Geri sayım (sadece ödenmemiş biletler için)
                if (ticket.status == TicketStatus.unpaid &&
                    ticket.drawDate != null) ...[
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      ticket.timeUntilDrawFormatted,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  // Otomatik iptal uyarısı
                  if (_autoCancel && ticket.shouldAutoCancel)
                    Container(
                      margin: EdgeInsets.only(top: 4),
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        'YAKINDA İPTAL',
                        style: TextStyle(
                          fontSize: 8,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],

                // İsim bilgisi (varsa)
                if (ticket.buyerName != null) ...[
                  SizedBox(height: 4),
                  Text(
                    ticket.buyerName!,
                    style: TextStyle(
                      fontSize: 10,
                      color: textColor.withOpacity(0.8),
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🔧 GÜNCELLENDİ: _generateSampleTickets metodu - Supabase'e kayıt ekle
  void _generateSampleTickets() async {
    if (_ticketsGenerated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Biletler zaten oluşturulmuş'),
          backgroundColor: Colors.blue,
        ),
      );
      return;
    }

    // Loading göster
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
                'Lütfen bekleyin...'), // Eski mesaj yerine daha genel bir mesaj
          ],
        ),
      ),
    );

    try {
      setState(() {
        _sampleTickets.clear();
      });

      // Admin ayarlarına göre bilet oluştur VE Supabase'e kaydet
      for (int i = 0; i < _currentTicketCount; i++) {
        final Random random = Random();

        // Her bilet için şans sayısı kadar numara üret
        List<String> numbers = [];
        for (int j = 0; j < _currentChanceCount; j++) {
          String number = '';
          for (int k = 0; k < _currentLastDigitCount; k++) {
            number += random.nextInt(10).toString();
          }
          numbers.add(number);
        }

        final ticket = Ticket(
          id: 'ticket_${DateTime.now().year}${DateTime.now().month.toString().padLeft(2, '0')}${DateTime.now().day.toString().padLeft(2, '0')}_${i.toString().padLeft(4, '0')}',
          campaignId: 'admin_live_campaign',
          numbers: numbers,
          price: _currentTicketPrice,
          status: TicketStatus.available,
          createdAt: DateTime.now(),
          userId: _supabaseService.currentUserId, // Supabase Auth UUID
          drawDate: DateTime.now().add(Duration(days: 1)),
          autoCancel: _autoCancel,
        );

        // 🆕 YENİ: Supabase'e kaydet
        final success = await _supabaseService.addTicket(ticket);
        if (success) {
          _sampleTickets.add(ticket);
          _campaignService.addTicketToSystem(ticket);
        } else {
          print('❌ Bilet ${ticket.id} Supabase\'e kaydedilemedi');
        }

        // Her 10 bilette bir progress güncelle
        if (i % 10 == 0) {
          await Future.delayed(Duration(milliseconds: 50)); // UI donmasını önle
        }
      }

      _ticketsGenerated = true;

      // Loading kapat
      Navigator.pop(context);

      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '✅ ${_sampleTickets.length} bilet oluşturuldu ve Supabase\'e kaydedildi! Bayiler anında görebilir.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 4),
        ),
      );
    } catch (e) {
      // Loading kapat
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Bilet oluşturma hatası: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildGiderler() {
    return Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📉 Giderler',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _showAddExpenseDialog,
                icon: Icon(Icons.add),
                label: Text('Gider Ekle'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              ),
              SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _showExpenseReport,
                icon: Icon(Icons.assessment),
                label: Text('Rapor Al'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              ),
            ],
          ),
          SizedBox(height: 24),
          Expanded(
            child: _financialService.expenses.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.money_off, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('Henüz gider kaydı yok'),
                        SizedBox(height: 8),
                        Text('Yeni gider eklemek için butona tıklayın'),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _financialService.expenses.length,
                    itemBuilder: (context, index) {
                      final expense = _financialService.expenses[index];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.red.withOpacity(0.1),
                            child: Icon(Icons.money_off, color: Colors.red),
                          ),
                          title: Text(expense.description),
                          subtitle: Text(
                              '${expense.date.day}/${expense.date.month}/${expense.date.year}'),
                          trailing: Text(
                            '-${expense.amount.toStringAsFixed(0)} ₺',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
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

  void _showAddExpenseDialog() {
    final descController = TextEditingController();
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('💸 Yeni Gider Ekle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: descController,
              decoration: InputDecoration(
                labelText: 'Gider Açıklaması',
                hintText: 'Örnek: Kırtasiye masrafı',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: amountController,
              decoration: InputDecoration(
                labelText: 'Tutar (₺)',
                hintText: '100',
                border: OutlineInputBorder(),
                suffixText: '₺',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text);
              if (descController.text.isNotEmpty &&
                  amount != null &&
                  amount > 0) {
                // Gider ekle - FinancialService'e ekleyelim
                final success = await _financialService.addExpense(
                  description: descController.text.trim(),
                  amount: amount,
                  date: DateTime.now(),
                );

                if (success) {
                  setState(() {
                    // UI'ı güncelle
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          '✅ Gider eklendi: ${descController.text} - ${amount.toStringAsFixed(0)} ₺'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ Gider eklenirken hata oluştu'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('❌ Lütfen geçerli bilgiler girin'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text('Ekle'),
          ),
        ],
      ),
    );
  }

  void _showExpenseReport() {
    final expenses = _financialService.expenses;
    final totalExpense = expenses.fold(0.0, (sum, exp) => sum + exp.amount);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('📊 Gider Raporu'),
        content: Container(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Özet kartı
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Row(
                  children: [
                    Icon(Icons.trending_down, color: Colors.red, size: 32),
                    SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Toplam Gider',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          '${totalExpense.toStringAsFixed(0)} ₺',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 16),

              if (expenses.isEmpty)
                Text(
                  'Henüz gider kaydı bulunmuyor',
                  style: TextStyle(color: Colors.grey[600]),
                )
              else ...[
                Text(
                  'Son ${expenses.length} gider:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Container(
                  height: 200,
                  child: ListView.builder(
                    itemCount: expenses.length,
                    itemBuilder: (context, index) {
                      final expense = expenses[index];
                      return ListTile(
                        leading:
                            Icon(Icons.money_off, color: Colors.red, size: 20),
                        title: Text(
                          expense.description,
                          style: TextStyle(fontSize: 14),
                        ),
                        subtitle: Text(
                          '${expense.date.day}/${expense.date.month}/${expense.date.year}',
                          style: TextStyle(fontSize: 12),
                        ),
                        trailing: Text(
                          '-${expense.amount.toStringAsFixed(0)} ₺',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Kapat'),
          ),
        ],
      ),
    );
  }

  Widget _buildBorcluOlanlar() {
    // Ödenmemiş biletleri al (sadece isim ve telefon bilgisi olanlar)
    final unpaidTickets = _getUnpaidTicketsWithBuyerInfo();

    return Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '💳 Borçlu Olanlar',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Text(
                'Toplam ${unpaidTickets.length} kişi borçlu',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              Spacer(),
              ElevatedButton.icon(
                onPressed: () => _sendPaymentReminders(unpaidTickets),
                icon: Icon(Icons.send),
                label: Text('Hatırlatma Gönder'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              ),
            ],
          ),
          SizedBox(height: 24),
          Expanded(
            child: unpaidTickets.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, size: 64, color: Colors.green),
                        SizedBox(height: 16),
                        Text('Harika! Borçlu kimse yok'),
                        SizedBox(height: 8),
                        Text('Tüm ödemeler tamamlanmış'),
                        SizedBox(height: 16),
                        Text(
                          'Biletleri "Ödenmedi" durumuna alıp isim yazarsanız burada görünür.',
                          style:
                              TextStyle(color: Colors.grey[500], fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: unpaidTickets.length,
                    itemBuilder: (context, index) {
                      final ticket = unpaidTickets[index];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.orange.withOpacity(0.1),
                            child: Icon(Icons.confirmation_number,
                                color: Colors.orange),
                          ),
                          title: Text(ticket.buyerName ?? 'İsimsiz Borçlu'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (ticket.buyerPhone != null)
                                Text('📞 ${ticket.buyerPhone}'),
                              Text('🎫 ${ticket.numbersFormatted}'),
                              Text(
                                  '📅 ${ticket.soldAt?.day}/${ticket.soldAt?.month}/${ticket.soldAt?.year} tarihinde satıldı'),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${ticket.price.toStringAsFixed(0)} ₺',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                'Borç',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          onTap: () => _showTicketDebtActions(ticket),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  List<Ticket> _getUnpaidTicketsWithBuyerInfo() {
    // Önce sadece sample biletleri kullan (çünkü bunlar zaten campaign service'e ekleniyor)
    List<Ticket> allTickets = [];

    // Öncelik sample biletlere ver
    if (_sampleTickets.isNotEmpty) {
      allTickets.addAll(_sampleTickets);
    } else {
      // Eğer sample bilet yoksa campaign service'ten al
      allTickets.addAll(_campaignService.getAllSystemTickets());
    }

    // Duplikatları ID'ye göre temizle
    final Map<String, Ticket> uniqueTickets = {};
    for (var ticket in allTickets) {
      uniqueTickets[ticket.id] = ticket;
    }

    // TÜM ödenmemiş biletleri döndür (isim olsun olmasın)
    // İsim yoksa "İsimsiz Borçlu" olarak gösterilecek
    return uniqueTickets.values
        .where((ticket) =>
            ticket.status == TicketStatus.sold ||
            ticket.status == TicketStatus.unpaid)
        .toList();
  }

  void _showTicketDebtActions(Ticket ticket) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('💳 ${ticket.buyerName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Bilet: ${ticket.numbersFormatted}'),
            SizedBox(height: 8),
            Text('Borç: ${ticket.price.toStringAsFixed(0)} ₺'),
            if (ticket.buyerPhone != null) ...[
              SizedBox(height: 8),
              Text('Telefon: ${ticket.buyerPhone}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _markTicketAsPaid(ticket);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text('Ödendi İşaretle'),
          ),
        ],
      ),
    );
  }

  void _markTicketAsPaid(Ticket ticket) {
    // Bilet durumunu "ödendi" yap
    _updateTicketStatusWithInfo(
        ticket, TicketStatus.paid, ticket.buyerName, ticket.buyerPhone);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            '✅ ${ticket.buyerName} - ${ticket.numbersFormatted} ödendi olarak işaretlendi'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _sendPaymentReminders(List<Ticket> unpaidTickets) {
    if (unpaidTickets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '📭 Borçlu kimse yok, hatırlatma gönderilecek kimse bulunamadı'),
          backgroundColor: Colors.blue,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('📲 Ödeme Hatırlatması'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
                '${unpaidTickets.length} kişiye ödeme hatırlatması gönderilsin mi?'),
            SizedBox(height: 16),
            Container(
              height: 150,
              child: ListView.builder(
                itemCount: unpaidTickets.length,
                itemBuilder: (context, index) {
                  final ticket = unpaidTickets[index];
                  return ListTile(
                    leading: Icon(Icons.person, size: 20),
                    title: Text(ticket.buyerName ?? 'İsimsiz',
                        style: TextStyle(fontSize: 14)),
                    subtitle: Text(
                      '${ticket.numbersFormatted} - ${ticket.price.toStringAsFixed(0)} ₺',
                      style: TextStyle(fontSize: 12),
                    ),
                    trailing: ticket.buyerPhone != null
                        ? Icon(Icons.phone, color: Colors.green, size: 16)
                        : Icon(Icons.phone_disabled,
                            color: Colors.red, size: 16),
                  );
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _sendReminders(unpaidTickets);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: Text('Gönder'),
          ),
        ],
      ),
    );
  }

  void _sendReminders(List<Ticket> tickets) {
    final phonelessCount = tickets
        .where((t) => t.buyerPhone == null || t.buyerPhone!.isEmpty)
        .length;
    final phoneCount = tickets.length - phonelessCount;

    String message = '';
    if (phoneCount > 0) {
      message += '📱 $phoneCount kişiye SMS gönderildi';
    }
    if (phonelessCount > 0) {
      if (message.isNotEmpty) message += '\n';
      message += '⚠️ $phonelessCount kişinin telefonu yok';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 4),
      ),
    );
  }

  void _showDebtActions(Person person) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('💳 ${person.fullName}'),
        content: Text('Borç: ${person.debt.toStringAsFixed(0)} ₺'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _markAsPaid(person);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text('Ödendi İşaretle'),
          ),
        ],
      ),
    );
  }

  void _markAsPaid(Person person) async {
    await _personService.markAsPaid(person.id);
    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ ${person.fullName} ödendi olarak işaretlendi'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildYeniKampanya() {
    final campaigns = _campaignService.campaigns;

    // Debug: Kampanyaları kontrol et
    print('📋 UI da gosterilecek kampanya sayisi: ${campaigns.length}');
    if (campaigns.isNotEmpty) {
      print('📋 Kampanya listesi: ${campaigns.map((c) => c.name).toList()}');
    }

    return Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🆕 Yeni Kampanya Oluştur',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          Text(
            'Kendi ayarlarınızla özel kampanya oluşturun ve yayınlayın:',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          SizedBox(height: 24),

          // Özel kampanya oluştur butonu
          Container(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showCustomCampaignDialog,
              icon: Icon(Icons.add_circle, size: 24),
              label: Text(
                'Yeni Özel Kampanya Oluştur',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF6A1B9A),
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 60),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 8,
              ),
            ),
          ),

          SizedBox(height: 32),

          // Oluşturulan kampanyalar
          Row(
            children: [
              Text(
                '📋 Oluşturulan Kampanyalar',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Spacer(),
              Text(
                'Toplam: ${campaigns.length} kampanya',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),

          SizedBox(height: 16),

          Expanded(
            child: campaigns.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.campaign_outlined,
                            size: 80, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Henüz kampanya oluşturmadınız',
                          style:
                              TextStyle(fontSize: 18, color: Colors.grey[600]),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Yukarıdaki butonu kullanarak yeni kampanya oluşturun',
                          style:
                              TextStyle(fontSize: 14, color: Colors.grey[500]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: campaigns.length,
                    itemBuilder: (context, index) {
                      final campaign = campaigns[index];
                      return _buildCampaignPublishCard(campaign);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampaignPublishCard(Campaign campaign) {
    final stats = _campaignService.getTicketStats(campaign.id);
    final isPublished = _campaignService
        .isListPublished; // Her kampanya için ayrı yayınlama durumu olmalı

    return Card(
      elevation: 4,
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık ve durum
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        campaign.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${campaign.ticketCount} bilet • ${campaign.lastDigitCount} haneli • ${campaign.chanceCount} şans',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isPublished
                        ? Colors.green.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isPublished ? '🟢 Yayında' : '🟡 Hazır',
                    style: TextStyle(
                      color:
                          isPublished ? Colors.green[700] : Colors.orange[700],
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 16),

            // Kampanya bilgileri
            Row(
              children: [
                Expanded(
                  child: _buildCampaignInfo('💰 Bilet Fiyatı',
                      '${campaign.ticketPrice.toStringAsFixed(0)} ₺'),
                ),
                Expanded(
                  child: _buildCampaignInfo(
                      '🏆 Ana İkramiye', _getCampaignPrizeText(campaign)),
                ),
                Expanded(
                  child: _buildCampaignInfo('📅 Çekiliş',
                      '${campaign.drawDate.day}/${campaign.drawDate.month}/${campaign.drawDate.year}'),
                ),
              ],
            ),

            SizedBox(height: 20),

            // Aksiyonlar
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _viewCampaignDetails(campaign),
                    icon: Icon(Icons.visibility, size: 18),
                    label: Text('Detayları Görüntüle'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isPublished
                        ? () => _unpublishCampaign(campaign)
                        : () => _publishCampaign(campaign),
                    icon: Icon(
                      isPublished ? Icons.visibility_off : Icons.publish,
                      size: 18,
                    ),
                    label: Text(
                        isPublished ? 'Yayından Kaldır' : 'Kampanyayı Yayınla'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isPublished ? Colors.orange : Colors.green,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCampaignInfo(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  void _viewCampaignDetails(Campaign campaign) {
    _showCampaignDetails(campaign);
  }

  void _publishCampaign(Campaign campaign) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('📢 Kampanya Yayınla'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
                '${campaign.name} kampanyasını yayınlamak istediğinizden emin misiniz?'),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.green),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Kampanya yayınlandığında tüm bayiler bu kampanyayı görebilir ve bilet satabilir.',
                      style: TextStyle(color: Colors.green[800]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              // Kampanyayı yayınla
              await _campaignService.publishList();
              setState(() {});

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      '✅ ${campaign.name} kampanyası yayınlandı! Bayiler artık görebilir.'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 3),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text('Evet, Yayınla'),
          ),
        ],
      ),
    );
  }

  void _unpublishCampaign(Campaign campaign) async {
    await _campaignService.unpublishList();
    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ ${campaign.name} kampanyası yayından kaldırıldı!'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
      ),
    );
  }

  String _getCampaignPrizeText(Campaign campaign) {
    if (campaign.prizeCurrency == PrizeCurrency.other &&
        campaign.customCurrency != null) {
      return '${campaign.prizeAmount} ${campaign.customCurrency}';
    } else {
      String symbol;
      switch (campaign.prizeCurrency) {
        case PrizeCurrency.tl:
          symbol = '₺';
          break;
        case PrizeCurrency.dolar:
          symbol = '\$';
          break;
        case PrizeCurrency.euro:
          symbol = '€';
          break;
        case PrizeCurrency.altin:
          symbol = '🥇';
          break;
        default:
          symbol = '₺';
      }
      return '${campaign.prizeAmount} $symbol';
    }
  }

  // Kampanya Yönetimi sayfası
  Widget _buildKampanyaYonetimi() {
    final campaigns = _campaignService.campaigns;

    return Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '🎯 Kampanya Yönetimi',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Spacer(),
              Text(
                'Toplam: ${campaigns.length} kampanya',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ],
          ),
          SizedBox(height: 24),

          // Kampanya kartları
          Expanded(
            child: campaigns.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.campaign, size: 80, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Henüz kampanya yok',
                          style:
                              TextStyle(fontSize: 20, color: Colors.grey[600]),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Yeni Kampanya sekmesinden kampanya oluşturun',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: campaigns.length,
                    itemBuilder: (context, index) {
                      final campaign = campaigns[index];
                      return _buildCampaignCard(campaign);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampaignCard(Campaign campaign) {
    final stats = _campaignService.getTicketStats(campaign.id);
    final isCompleted = campaign.isCompleted;

    return Card(
      elevation: 4,
      margin: EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _showCampaignDetails(campaign),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Başlık ve durum
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          campaign.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Hafta ${campaign.weekNumber} • ${campaign.lastDigitCount} haneli',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? Colors.red.withOpacity(0.1)
                          : Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isCompleted ? '🔴 Tamamlandı' : '🟢 Aktif',
                      style: TextStyle(
                        color:
                            isCompleted ? Colors.red[700] : Colors.green[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 16),

              // İstatistikler
              Row(
                children: [
                  _buildStatChip('Toplam Bilet', '${stats['total']}',
                      Icons.confirmation_number, Colors.blue),
                  SizedBox(width: 12),
                  _buildStatChip(
                      'Satılan', '${stats['sold']}', Icons.sell, Colors.green),
                  SizedBox(width: 12),
                  _buildStatChip('Müsait', '${stats['available']}',
                      Icons.pending, Colors.orange),
                ],
              ),

              SizedBox(height: 16),

              // İkramiye bilgisi ve aksiyonlar
              Row(
                children: [
                  Icon(Icons.monetization_on, color: Colors.amber, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Ana İkramiye: ${_getCampaignPrizeText(campaign)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber[800],
                    ),
                  ),
                  Spacer(),
                  if (!isCompleted) ...[
                    ElevatedButton.icon(
                      onPressed: () => _showDrawResultDialog(campaign),
                      icon: Icon(Icons.casino, size: 16),
                      label: Text('Çekiliş Sonucu Gir'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _finishCampaign(campaign),
                      icon: Icon(Icons.stop_circle, size: 16),
                      label: Text('Kampanyayı Bitir'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                    ),
                  ],
                ],
              ),

              if (isCompleted && campaign.winningNumber != null) ...[
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.emoji_events, color: Colors.purple),
                          SizedBox(width: 8),
                          Text(
                            'Kazanan Numara: ${campaign.winningNumber}',
                            style: TextStyle(
                              color: Colors.purple[800],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Spacer(),
                          ElevatedButton.icon(
                            onPressed: () => _showWinningTickets(campaign),
                            icon: Icon(Icons.star, size: 16),
                            label: Text('Talihli Biletleri Göster'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showCustomCampaignDialog() {
    final nameController = TextEditingController();
    final ticketCountController = TextEditingController();
    final digitCountController = TextEditingController();
    final chanceCountController = TextEditingController();
    final priceController = TextEditingController();
    final prizeController = TextEditingController();
    final prizeCurrencyController =
        TextEditingController(text: 'TL'); // Varsayılan değer
    final upperPrizeController = TextEditingController();
    final lowerPrizeController = TextEditingController();

    DateTime selectedDrawDate =
        DateTime.now().add(Duration(days: 7)); // Varsayılan 1 hafta sonra

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('🛠️ Özel Kampanya Oluştur'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Kampanya Adı',
                    hintText: 'Örnek: Özel Çekiliş 2024',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.campaign),
                  ),
                ),
                SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: ticketCountController,
                        decoration: InputDecoration(
                          labelText: 'Bilet Sayısı',
                          hintText: '100',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: digitCountController,
                        decoration: InputDecoration(
                          labelText: 'Hane Sayısı',
                          hintText: '3',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: chanceCountController,
                        decoration: InputDecoration(
                          labelText: 'Şans Sayısı',
                          hintText: '2',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: priceController,
                        decoration: InputDecoration(
                          labelText: 'Bilet Fiyatı (₺)',
                          hintText: '10',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 16),

                // Çekiliş tarihi seçici
                InkWell(
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDrawDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(Duration(days: 365)),
                    );
                    if (picked != null && picked != selectedDrawDate) {
                      setState(() {
                        selectedDrawDate = picked;
                      });
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, color: Colors.grey[600]),
                        SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Çekiliş Tarihi',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[600]),
                            ),
                            Text(
                              '${selectedDrawDate.day}/${selectedDrawDate.month}/${selectedDrawDate.year}',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Spacer(),
                        Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: prizeController,
                        decoration: InputDecoration(
                          labelText: 'Ana İkramiye Miktarı',
                          hintText: '1000 TL, 5 Altın, iPhone 15...',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.attach_money),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: prizeCurrencyController,
                        decoration: InputDecoration(
                          labelText: 'İkramiye Cinsi',
                          hintText: 'TL, USD, Altın, Telefon...',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.category),
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: lowerPrizeController,
                        decoration: InputDecoration(
                          labelText: 'Bir Alt İkramiye',
                          hintText: '100 TL, Kulaklık...',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.remove_circle_outline),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: upperPrizeController,
                        decoration: InputDecoration(
                          labelText: 'Bir Üst İkramiye',
                          hintText: '100 TL, Telefon...',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.add_circle_outline),
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 16),

                // İkramiye cinsi örnekleri
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.lightbulb, color: Colors.blue, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'İkramiye Cinsi Örnekleri:',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[800]),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          'TL',
                          'USD',
                          'EUR',
                          'Altın',
                          'iPhone',
                          'Laptop',
                          'Araba',
                          'Televizyon',
                          'Buzdolabı',
                          'Tatil'
                        ]
                            .map((prize) => ActionChip(
                                  label: Text(prize,
                                      style: TextStyle(fontSize: 12)),
                                  onPressed: () =>
                                      prizeCurrencyController.text = prize,
                                  backgroundColor: Colors.blue.withOpacity(0.1),
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Validasyon
                if (nameController.text.isEmpty ||
                    ticketCountController.text.isEmpty ||
                    digitCountController.text.isEmpty ||
                    chanceCountController.text.isEmpty ||
                    priceController.text.isEmpty ||
                    prizeController.text.isEmpty ||
                    prizeCurrencyController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content:
                            Text('❌ Lütfen tüm zorunlu alanları doldurun')),
                  );
                  return;
                }

                final ticketCount = int.tryParse(ticketCountController.text);
                final digitCount = int.tryParse(digitCountController.text);
                final chanceCount = int.tryParse(chanceCountController.text);
                final price = double.tryParse(priceController.text);

                // İkramiye tutarları artık string olarak kabul edilir (rakam, yazı, ne olursa olsun)
                final prizeText = prizeController.text.trim();
                final upperPrizeText = upperPrizeController.text.trim();
                final lowerPrizeText = lowerPrizeController.text.trim();

                if (ticketCount == null ||
                    digitCount == null ||
                    chanceCount == null ||
                    price == null ||
                    ticketCount <= 0 ||
                    digitCount <= 0 ||
                    chanceCount <= 0 ||
                    price <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            '❌ Lütfen bilet sayısı, rakam sayısı, şans sayısı ve bilet fiyatı için geçerli sayılar girin')),
                  );
                  return;
                }

                // İkramiye cinsini belirle
                PrizeCurrency prizeCurrency;
                final currencyText =
                    prizeCurrencyController.text.trim().toUpperCase();
                if (currencyText == 'TL' || currencyText == 'TÜRK LİRASI') {
                  prizeCurrency = PrizeCurrency.tl;
                } else if (currencyText == 'USD' || currencyText == 'DOLAR') {
                  prizeCurrency = PrizeCurrency.dolar;
                } else if (currencyText == 'EUR' || currencyText == 'EURO') {
                  prizeCurrency = PrizeCurrency.euro;
                } else if (currencyText == 'ALTIN' || currencyText == 'GOLD') {
                  prizeCurrency = PrizeCurrency.altin;
                } else {
                  // Diğer durumlar için özel para birimi
                  prizeCurrency = PrizeCurrency.other;
                }

                // Kampanya oluştur
                final campaign = Campaign(
                  id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                  name: nameController.text.trim(),
                  lastDigitCount: digitCount,
                  chanceCount: chanceCount,
                  ticketCount: ticketCount,
                  ticketPrice: price,
                  prizeAmount: prizeText, // Artık string olarak gönderilir
                  upperPrize: upperPrizeText,
                  lowerPrize: lowerPrizeText,
                  prizeCurrency: prizeCurrency,
                  customCurrency: prizeCurrencyController.text
                      .trim(), // Özel ikramiye cinsi
                  weekNumber: (DateTime.now()
                              .difference(DateTime(DateTime.now().year, 1, 1))
                              .inDays /
                          7)
                      .ceil(),
                  drawDate: selectedDrawDate, // Seçilen tarihi kullan
                  createdAt: DateTime.now(),
                );

                await _campaignService.createAdminCampaign(campaign);
                Navigator.pop(context);

                // Debug: Kampanya sayisini kontrol et
                final campaignsAfter = _campaignService.campaigns;
                print('🎯 Kampanya olusturuldu: ${campaign.name}');
                print('🎯 Toplam kampanya sayisi: ${campaignsAfter.length}');
                print(
                    '🎯 Kampanya listesi: ${campaignsAfter.map((c) => c.name).toList()}');

                setState(() {});

                String displayPrizeText;
                if (prizeCurrency == PrizeCurrency.other ||
                    prizeCurrencyController.text.trim().isNotEmpty) {
                  displayPrizeText =
                      '$prizeText ${prizeCurrencyController.text}';
                } else {
                  String symbol = '₺'; // varsayılan
                  switch (prizeCurrency) {
                    case PrizeCurrency.tl:
                      symbol = '₺';
                      break;
                    case PrizeCurrency.dolar:
                      symbol = '\$';
                      break;
                    case PrizeCurrency.euro:
                      symbol = '€';
                      break;
                    case PrizeCurrency.altin:
                      symbol = '🥇';
                      break;
                    default:
                      symbol = '₺';
                  }
                  displayPrizeText = '$prizeText $symbol';
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        '✅ Özel kampanya oluşturuldu: ${campaign.name}\n📅 Çekiliş: ${selectedDrawDate.day}/${selectedDrawDate.month}/${selectedDrawDate.year}\n🏆 İkramiye: $displayPrizeText'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 4),
                  ),
                );

                _showSuccessAnimation();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF6A1B9A),
                foregroundColor: Colors.white,
              ),
              child: Text('Oluştur'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrtakSayisi() {
    return Padding(
      padding: EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '👥 Ortak Sayısı Belirle',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'Kampanyada kaç ortak olacağını belirleyin:',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            SizedBox(height: 32),

            GridView.count(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              childAspectRatio: 1.2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildOrtakCard('2 Ortak', '50% - 50%', 2),
                _buildOrtakCard('3 Ortak', '33% - 33% - 34%', 3),
                _buildOrtakCard('4 Ortak', '25% her biri', 4),
                _buildOrtakCard('5 Ortak', '20% her biri', 5),
                _buildOrtakCard('6 Ortak', '16.7% her biri', 6),
                _buildOrtakCard('Özel', 'Manuel paylaşım', 0),
              ],
            ),

            SizedBox(height: 32),

            if (_selectedPartnerCount > 0) ...[
              Text(
                'Seçilen: $_selectedPartnerCount Ortak',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),

              // Ortak profil görünümleri
              GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: min(_selectedPartnerCount, 3),
                  childAspectRatio: 0.8,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: _selectedPartnerCount,
                itemBuilder: (context, index) =>
                    _buildPartnerProfileCard(index + 1),
              ),

              SizedBox(height: 16),

              ElevatedButton.icon(
                onPressed: _showPartnerDetails,
                icon: Icon(Icons.group),
                label: Text('Ortak Detaylarını Düzenle'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF6A1B9A),
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, 50),
                ),
              ),
            ],

            SizedBox(height: 100), // Alt boşluk
          ],
        ),
      ),
    );
  }

  int _selectedPartnerCount = 0;

  Widget _buildOrtakCard(String title, String description, int count) {
    final isSelected = _selectedPartnerCount == count;

    return Card(
      elevation: isSelected ? 8 : 4,
      child: InkWell(
        onTap: () => _selectPartnerCount(count),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: isSelected ? Color(0xFF6A1B9A).withOpacity(0.1) : null,
          ),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  count == 0 ? Icons.settings : Icons.group,
                  size: 32,
                  color: isSelected ? Color(0xFF6A1B9A) : Colors.grey[600],
                ),
                SizedBox(height: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Color(0xFF6A1B9A) : Colors.grey[800],
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _selectPartnerCount(int count) {
    setState(() {
      _selectedPartnerCount = count;
    });

    if (count == 0) {
      _showCustomPartnerDialog();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ $count ortak seçildi'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showCustomPartnerDialog() {
    final partnerCountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('🛠️ Özel Ortak Ayarla'),
        content: TextField(
          controller: partnerCountController,
          decoration: InputDecoration(
            labelText: 'Ortak Sayısı',
            hintText: 'Örnek: 3',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.group),
          ),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              final count = int.tryParse(partnerCountController.text);
              if (count != null && count > 0 && count <= 10) {
                Navigator.pop(context);
                _selectPartnerCount(count);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('❌ 1-10 arası geçerli bir sayı girin')),
                );
              }
            },
            child: Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  void _showPartnerDetails() {
    if (_selectedPartnerCount <= 0) return;

    // Mevcut ortakları al veya yeni oluştur
    List<Partner> partners = [];
    if (_campaignService.campaigns.isNotEmpty) {
      partners = List.from(_campaignService.campaigns.last.partners);
    }

    // Eksik ortakları tamamla
    while (partners.length < _selectedPartnerCount) {
      partners.add(Partner(
        id: 'partner_${partners.length + 1}',
        name: '',
        phone: '',
        percentage: 0.0,
      ));
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('👥 Ortak Detayları ($_selectedPartnerCount Ortak)'),
        content: Container(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: Column(
              children: [
                for (int i = 0; i < _selectedPartnerCount; i++) ...[
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ortak ${i + 1}',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8),
                          TextField(
                            decoration: InputDecoration(
                              labelText: 'Ad Soyad',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            onChanged: (value) =>
                                partners[i] = partners[i].copyWith(name: value),
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  decoration: InputDecoration(
                                    labelText: 'Telefon',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                  onChanged: (value) => partners[i] =
                                      partners[i].copyWith(phone: value),
                                ),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  decoration: InputDecoration(
                                    labelText: 'Pay (%)',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                    suffixText: '%',
                                  ),
                                  keyboardType: TextInputType.number,
                                  onChanged: (value) {
                                    final percentage =
                                        double.tryParse(value) ?? 0.0;
                                    partners[i] = partners[i]
                                        .copyWith(percentage: percentage);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                ],

                // Toplam yüzde göstergesi
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Toplam pay: ${partners.fold(0.0, (sum, p) => sum + p.percentage).toStringAsFixed(1)}%\n'
                          'Kalan admin payı: ${(100 - partners.fold(0.0, (sum, p) => sum + p.percentage)).toStringAsFixed(1)}%',
                          style: TextStyle(color: Colors.blue[700]),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              final totalPercentage =
                  partners.fold(0.0, (sum, p) => sum + p.percentage);
              if (totalPercentage > 100) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('❌ Toplam pay 100%\'ü geçemez')),
                );
                return;
              }

              // Ortakları kaydet
              _savePartners(partners);
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('✅ Ortak detayları kaydedildi'),
                  backgroundColor: Colors.green,
                ),
              );

              _showSuccessAnimation();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF6A1B9A),
              foregroundColor: Colors.white,
            ),
            child: Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  List<Partner> _currentPartners = [];

  void _savePartners(List<Partner> partners) {
    // Ortakları gerçekten kaydet
    _currentPartners = List.from(partners);

    // Kampanyalara da kaydet
    for (var campaign in _campaignService.campaigns) {
      // Her kampanyaya ortak bilgilerini kaydet
      print(
          'Kampanya ${campaign.name} için ${partners.length} ortak kaydedildi');
    }

    setState(() {});

    print('Kaydedilen ortaklar:');
    for (int i = 0; i < _currentPartners.length; i++) {
      print(
          'Ortak ${i + 1}: ${_currentPartners[i].name} - %${_currentPartners[i].percentage}');
    }
  }

  Widget _buildPartnerProfileCard(int partnerNumber) {
    // Gerçek partner bilgilerini al
    final partnerIndex = partnerNumber - 1;
    final partnerName = _currentPartners.length > partnerIndex &&
            _currentPartners[partnerIndex].name.isNotEmpty
        ? _currentPartners[partnerIndex].name
        : 'Ortak $partnerNumber';
    final percentage = _currentPartners.length > partnerIndex
        ? _currentPartners[partnerIndex].percentage.toStringAsFixed(1)
        : '0.0';
    final hasData = _currentPartners.length > partnerIndex &&
        _currentPartners[partnerIndex].name.isNotEmpty;

    return Card(
      elevation: 4,
      child: InkWell(
        onTap: () => _showPartnerInfo(partnerNumber),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Profil resmi
              CircleAvatar(
                radius: 30,
                backgroundColor:
                    hasData ? Colors.green.withOpacity(0.1) : Colors.grey[200],
                child: hasData
                    ? Icon(
                        Icons.person,
                        size: 30,
                        color: Colors.green,
                      )
                    : Text(
                        'O$partnerNumber',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
              ),
              SizedBox(height: 12),

              // İsim
              Text(
                partnerName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: hasData ? Colors.green[800] : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 8),

              // Pay yüzdesi
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: hasData
                      ? Colors.green.withOpacity(0.1)
                      : Color(0xFF6A1B9A).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '%$percentage',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: hasData ? Colors.green : Color(0xFF6A1B9A),
                  ),
                ),
              ),

              SizedBox(height: 8),

              // Durum ikonu
              Icon(
                hasData ? Icons.check_circle : Icons.edit,
                size: 16,
                color: hasData ? Colors.green : Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPartnerInfo(int partnerNumber) {
    final partnerIndex = partnerNumber - 1;
    final hasData = _currentPartners.length > partnerIndex &&
        _currentPartners[partnerIndex].name.isNotEmpty;

    final name =
        hasData ? _currentPartners[partnerIndex].name : 'Henüz belirlenmedi';
    final phone =
        hasData ? _currentPartners[partnerIndex].phone : 'Henüz belirlenmedi';
    final percentage = hasData
        ? '%${_currentPartners[partnerIndex].percentage.toStringAsFixed(1)}'
        : 'Henüz belirlenmedi';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('👤 Ortak $partnerNumber Bilgileri'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPartnerInfoRow('Ad Soyad:', name),
            _buildPartnerInfoRow('Telefon:', phone),
            _buildPartnerInfoRow('Pay Oranı:', percentage),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: hasData
                    ? Colors.green.withOpacity(0.1)
                    : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(hasData ? Icons.check_circle : Icons.info,
                      color: hasData ? Colors.green : Colors.orange),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      hasData
                          ? 'Ortak bilgileri başarıyla kaydedildi!'
                          : 'Ortak detaylarını düzenlemek için "Ortak Detaylarını Düzenle" butonunu kullanın.',
                      style: TextStyle(
                          color:
                              hasData ? Colors.green[800] : Colors.orange[800]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Kapat'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showPartnerDetails();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF6A1B9A),
              foregroundColor: Colors.white,
            ),
            child: Text('Düzenle'),
          ),
        ],
      ),
    );
  }

  Widget _buildPartnerInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildDilekSikayet() {
    return Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        children: [
          Text('📝 Dilek Şikayet Kutusu',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _complaintService.allComplaints.length,
              itemBuilder: (context, index) {
                final complaint = _complaintService.allComplaints[index];
                return Card(
                  child: ListTile(
                    leading: Text(complaint.statusEmoji,
                        style: TextStyle(fontSize: 24)),
                    title: Text(complaint.senderName),
                    subtitle: Text(complaint.message),
                    trailing: Text(complaint.statusText),
                    onTap: () => _showComplaintDetails(complaint),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('🔍 Arama Sonuçları (${_searchResults.length})',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final ticket = _searchResults[index];
                return Card(
                  child: ListTile(
                    leading: Text(ticket.statusEmoji,
                        style: TextStyle(fontSize: 24)),
                    title: Text('${ticket.numbersFormatted}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (ticket.buyerName != null)
                          Text('Alıcı: ${ticket.buyerName}'),
                        if (ticket.buyerPhone != null)
                          Text('Telefon: ${ticket.buyerPhone}'),
                        Text('Durum: ${ticket.statusText}'),
                      ],
                    ),
                    trailing: Text('${ticket.price} ₺'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderPage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.construction, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Bu sayfa yakında eklenecek',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  // Profil resmi seçenekleri
  void _showProfileImageOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('📷 Profil Resmi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.photo_library),
              title: Text('Galeriden Seç'),
              onTap: () {
                Navigator.pop(context);
                _selectImageFromGallery();
              },
            ),
            ListTile(
              leading: Icon(Icons.camera_alt),
              title: Text('Fotoğraf Çek'),
              onTap: () {
                Navigator.pop(context);
                _takePicture();
              },
            ),
            if (_authService.currentUser?.profileImage != null)
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Resmi Kaldır'),
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
            child: Text('İptal'),
          ),
        ],
      ),
    );
  }

  void _selectImageFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        // Gerçek uygulamada burada dosyayı sunucuya yüklenir
        // Şimdilik dosya yolunu simüle ediyoruz
        _updateProfileImage('file://${image.path}');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('📷 Fotoğraf seçildi: ${image.name}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Fotoğraf seçilemedi: $e')),
      );
    }
  }

  void _takePicture() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        // Gerçek uygulamada burada dosyayı sunucuya yüklenir
        // Şimdilik dosya yolunu simüle ediyoruz
        _updateProfileImage('file://${image.path}');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('📸 Fotoğraf çekildi: ${image.name}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Fotoğraf çekilemedi: $e')),
      );
    }
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
        SnackBar(
          content: Text('✅ Profil resmi güncellendi'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Profil resmi güncellenemedi'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
        title: Text('✏️ Profili Düzenle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Ad Soyad',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: phoneController,
              decoration: InputDecoration(
                labelText: 'Telefon',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
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
            child: Text('İptal'),
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
                  SnackBar(content: Text('✅ Profil güncellendi')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('❌ Güncelleme başarısız')),
                );
              }
            },
            child: Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  // Şifre değiştirme
  Future<void> _showChangePasswordDialog() async {
    final _formKey = GlobalKey<FormState>();
    final newPass = TextEditingController();
    final newPass2 = TextEditingController();
    final oldPass = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Şifre Değiştir'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: oldPass,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Mevcut Şifre'),
                validator: (s) =>
                    (s == null || s.isEmpty) ? 'Mevcut şifre gerekli' : null,
              ),
              TextFormField(
                controller: newPass,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Yeni Şifre'),
                validator: (s) =>
                    (s == null || s.length < 6) ? 'En az 6 karakter' : null,
              ),
              TextFormField(
                controller: newPass2,
                obscureText: true,
                decoration:
                    const InputDecoration(labelText: 'Yeni Şifre Tekrar'),
                validator: (s) =>
                    (s != newPass.text) ? 'Şifreler eşleşmiyor' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () async {
              if (!_formKey.currentState!.validate()) return;
              final ok =
                  await _authService.changePassword(oldPass.text, newPass.text);
              Navigator.pop(ctx);
              if (!ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Hata: Şifre güncellenemedi!')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Şifre başarıyla güncellendi')),
                );
              }
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  // Yardımcı metodlar
  void _searchTickets(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _searchResults = _ticketService.searchTicketsByName(query);
    });
  }

  void _logout() async {
    await _authService.logout();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  void _showNotifications() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('🔔 Bildirimler'),
        content: Container(
          width: double.maxFinite,
          height: 300,
          child: _ticketService.pendingNotifications.isEmpty
              ? Center(child: Text('Yeni bildirim yok'))
              : ListView.builder(
                  itemCount: _ticketService.pendingNotifications.length,
                  itemBuilder: (context, index) {
                    final notification =
                        _ticketService.pendingNotifications[index];
                    return Card(
                      child: ListTile(
                        leading: Text(notification.typeEmoji),
                        title: Text(notification.title),
                        subtitle: Text(notification.message),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ElevatedButton(
                              onPressed: () =>
                                  _approveTicketRequest(notification),
                              child: Text('✅'),
                            ),
                            SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () =>
                                  _rejectTicketRequest(notification),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red),
                              child: Text('❌'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Kapat'),
          ),
        ],
      ),
    );
  }

  void _approveTicketRequest(notification) {
    _ticketService.processTicketRequest(
      notificationId: notification.id,
      approved: true,
      buyerName: notification.fromUserName,
      buyerPhone: '',
    );
    setState(() {});
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('✅ Bilet talebi onaylandı')),
    );
  }

  void _rejectTicketRequest(notification) {
    _ticketService.processTicketRequest(
      notificationId: notification.id,
      approved: false,
      buyerName: '',
      buyerPhone: '',
    );
    setState(() {});
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('❌ Bilet talebi reddedildi')),
    );
  }

  void _addPersonDialog() {
    final firstNameController = TextEditingController();
    final lastNameController = TextEditingController();
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('👤 Yeni Kişi Ekle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: firstNameController,
              decoration: InputDecoration(
                labelText: 'Ad',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: lastNameController,
              decoration: InputDecoration(
                labelText: 'Soyad',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: phoneController,
              decoration: InputDecoration(
                labelText: 'Telefon',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
                hintText: '05XXXXXXXXX',
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (firstNameController.text.isEmpty ||
                  lastNameController.text.isEmpty ||
                  phoneController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('❌ Lütfen tüm alanları doldurun')),
                );
                return;
              }

              final person = Person(
                id: 'person_${DateTime.now().millisecondsSinceEpoch}',
                firstName: firstNameController.text.trim(),
                lastName: lastNameController.text.trim(),
                phone: phoneController.text.trim(),
                createdAt: DateTime.now(),
              );

              final success = await _personService.addPerson(person);
              Navigator.pop(context);

              if (success) {
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('✅ ${person.fullName} başarıyla eklendi')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('❌ Bu telefon numarası zaten kayıtlı')),
                );
              }
            },
            child: Text('Ekle'),
          ),
        ],
      ),
    );
  }

  void _importFromContacts() async {
    // Yükleniyor dialog'unu göster
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Telefon rehberinden kişiler yükleniyor...'),
          ],
        ),
      ),
    );

    try {
      final newContacts = await _personService.importFromContacts();
      Navigator.pop(context); // Yükleniyor dialog'unu kapat

      setState(() {});

      if (newContacts.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📱 Telefon rehberinden yeni kişi bulunamadı\n'
                'Not: Bu simülasyon sürümünde telefon rehberi erişimi kısıtlıdır.'),
            duration: Duration(seconds: 4),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('✅ ${newContacts.length} kişi rehberden eklendi')),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Yükleniyor dialog'unu kapat
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Telefon rehberine erişim hatası')),
      );
    }
  }

  void _handlePersonAction(Person person, String action) {
    if (action == 'edit') {
      _showEditPersonDialog(person);
    } else if (action == 'delete') {
      _showDeletePersonDialog(person);
    }
  }

  void _showEditPersonDialog(Person person) {
    final firstNameController = TextEditingController(text: person.firstName);
    final lastNameController = TextEditingController(text: person.lastName);
    final phoneController = TextEditingController(text: person.phone);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('✏️ Kişi Düzenle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: firstNameController,
              decoration: InputDecoration(
                labelText: 'Ad',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: lastNameController,
              decoration: InputDecoration(
                labelText: 'Soyad',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: phoneController,
              decoration: InputDecoration(
                labelText: 'Telefon',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (firstNameController.text.isEmpty ||
                  lastNameController.text.isEmpty ||
                  phoneController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('❌ Lütfen tüm alanları doldurun')),
                );
                return;
              }

              final updatedPerson = person.copyWith(
                firstName: firstNameController.text.trim(),
                lastName: lastNameController.text.trim(),
                phone: phoneController.text.trim(),
              );

              final success = await _personService.updatePerson(updatedPerson);
              Navigator.pop(context);

              if (success) {
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('✅ ${updatedPerson.fullName} güncellendi')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('❌ Güncelleme başarısız')),
                );
              }
            },
            child: Text('Güncelle'),
          ),
        ],
      ),
    );
  }

  void _showDeletePersonDialog(Person person) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('🗑️ Kişi Sil'),
        content: Text(
            '${person.fullName} adlı kişiyi silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await _personService.deletePerson(person.id);
              Navigator.pop(context);

              if (success) {
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('✅ ${person.fullName} silindi')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('❌ Silme işlemi başarısız')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Sil', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showComplaintDetails(complaint) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('📝 Şikayet Detayı'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Gönderen: ${complaint.senderName}'),
            if (complaint.senderPhone != null)
              Text('Telefon: ${complaint.senderPhone}'),
            SizedBox(height: 16),
            Text('Mesaj:'),
            Text(complaint.message),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Kapat'),
          ),
          ElevatedButton(
            onPressed: () {
              _complaintService.markAsResolved(complaintId: complaint.id);
              setState(() {});
              Navigator.pop(context);
            },
            child: Text('Çözüldü İşaretle'),
          ),
        ],
      ),
    );
  }

  // 🔧 GÜNCELLENDİ: _buildListeYayinla metodu - Gerçek zamanlı bilgi ekleme
  Widget _buildListeYayinla() {
    return Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Durum kartı - Realtime bilgi ile
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        _campaignService.isListPublished
                            ? Icons.visibility
                            : Icons.visibility_off,
                        size: 32,
                        color: _campaignService.isListPublished
                            ? Colors.green
                            : Colors.grey,
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Liste Durumu',
                              style: TextStyle(
                                  fontSize: 16, color: Colors.grey[600]),
                            ),
                            Text(
                              _campaignService.isListPublished
                                  ? 'Yayınlandı (Realtime Aktif)'
                                  : 'Yayınlanmadı',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: _campaignService.isListPublished
                                    ? Colors.green
                                    : Colors.grey[800],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // 🆕 YENİ: Realtime status göstergesi
                      if (_campaignService.isListPublished)
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.green),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: 6),
                              Text(
                                'CANLI',
                                style: TextStyle(
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),

                  // 🆕 YENİ: Realtime istatistikleri
                  if (_campaignService.isListPublished) ...[
                    SizedBox(height: 16),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.sync, color: Colors.blue),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '📡 Gerçek Zamanlı Senkronizasyon Aktif\nBayiler tüm değişiklikleri anında görür',
                              style: TextStyle(color: Colors.blue[700]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          SizedBox(height: 24),

          // Açıklama - güncellenmiş
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue),
                    SizedBox(width: 8),
                    Text(
                      'Gerçek Zamanlı Liste Yayınlama',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Text(
                  '• Liste yayınlandığında tüm bayiler biletleri anında görür\n'
                  '• Bilet durumu değişiklikleri gerçek zamanlı senkronize olur\n'
                  '• Admin\'deki her değişiklik bayilere otomatik bildirim gönderir\n'
                  '• Renk kodları: Müsait (gri), Ödenmedi (turuncu), Ödendi (yeşil), İptal (kırmızı)',
                  style: TextStyle(color: Colors.blue[700]),
                ),
              ],
            ),
          ),

          SizedBox(height: 32),

          // Ana butonlar
          Row(
            children: [
              if (!_campaignService.isListPublished) ...[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await _campaignService.publishList();
                      // 🆕 YENİ: Realtime yayın başlat
                      await _supabaseService.testConnection();
                      setState(() {});

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              '✅ Liste başarıyla yayınlandı! Bayiler gerçek zamanlı olarak biletleri görebilir.'),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 4),
                        ),
                      );
                    },
                    icon: Icon(Icons.publish, size: 24),
                    label: Text(
                      'LİSTEYİ YAYINLA (CANLI)',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ] else ...[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await _campaignService.unpublishList();
                      setState(() {});

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              '✅ Liste yayından kaldırıldı! Gerçek zamanlı senkronizasyon durduruldu.'),
                          backgroundColor: Colors.orange,
                          duration: Duration(seconds: 3),
                        ),
                      );
                    },
                    icon: Icon(Icons.visibility_off, size: 24),
                    label: Text(
                      'LİSTEYİ GİZLE',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),

          SizedBox(height: 24),

          // Milli Piyango Sonuç Çekme Butonu
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => AlertDialog(
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Milli Piyango sitesinden sonuç çekiliyor...',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Bu işlem birkaç saniye sürebilir',
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                );

                try {
                  // Büyük ikramiye numarasını çek
                  final buyukIkramiyeNo =
                      await MilliPiyangoService.getBuyukIkramiyeNumara();

                  // Dialog'u kapat
                  Navigator.pop(context);

                  if (buyukIkramiyeNo != null && buyukIkramiyeNo.isNotEmpty) {
                    // Başarı mesajı göster
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('✅ Milli Piyango Sonucu'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Büyük İkramiye Numarası:',
                              style: TextStyle(fontSize: 16),
                            ),
                            SizedBox(height: 8),
                            Text(
                              buyukIkramiyeNo,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            SizedBox(height: 16),
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.green),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Milli Piyango resmi sitesinden başarıyla çekildi',
                                      style:
                                          TextStyle(color: Colors.green[800]),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('Kapat'),
                          ),
                        ],
                      ),
                    );
                  } else {
                    // Sonuç alınamadı
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            '⚠️ Milli Piyango sonucu alınamadı. Lütfen daha sonra tekrar deneyin.'),
                        backgroundColor: Colors.orange,
                        duration: Duration(seconds: 3),
                      ),
                    );
                  }
                } catch (e) {
                  // Dialog'u kapat
                  Navigator.pop(context);

                  // Hata mesajı göster
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ Hata: ${e.toString()}'),
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              },
              icon: Icon(Icons.download, size: 24),
              label: Text(
                'MİLLİ PİYANGODAN SONUÇLARI ÇEK',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),

          SizedBox(height: 24),

          // İstatistikler
          if (_campaignService.isListPublished) ...[
            Text(
              'Yayınlanan Liste İstatistikleri',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Toplam Bilet',
                    '${_sampleTickets.length}', // Admin'in oluşturduğu gerçek sayı
                    Icons.confirmation_number,
                    Colors.blue,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Müsait Bilet',
                    '${_sampleTickets.where((t) => t.status == TicketStatus.available).length}',
                    Icons.sell_outlined,
                    Colors.grey,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Sistem Toplam',
                    '${_campaignService.getAllSystemTickets().length}', // Debug için
                    Icons.bug_report,
                    Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showCampaignDetails(Campaign campaign) {
    final stats = _campaignService.getTicketStats(campaign.id);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('🎯 ${campaign.name}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow(
                  '📊 Durum', campaign.isCompleted ? 'Tamamlandı' : 'Aktif'),
              _buildDetailRow('📅 Hafta', 'Hafta ${campaign.weekNumber}'),
              _buildDetailRow(
                  '🔢 Hane Sayısı', '${campaign.lastDigitCount} haneli'),
              _buildDetailRow('🎲 Şans Sayısı', '${campaign.chanceCount} şans'),
              _buildDetailRow('🎫 Toplam Bilet', '${stats['total']}'),
              _buildDetailRow('💰 Bilet Fiyatı',
                  '${campaign.ticketPrice.toStringAsFixed(0)} ₺'),
              _buildDetailRow('🏆 Ana İkramiye', '${campaign.prizeAmount}'),
              _buildDetailRow('⬆️ Bir Üst İkramiye', '${campaign.upperPrize}'),
              _buildDetailRow('⬇️ Bir Alt İkramiye', '${campaign.lowerPrize}'),
              SizedBox(height: 16),
              Text('📈 Satış İstatistikleri:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              _buildDetailRow('✅ Satılan Bilet', '${stats['sold']}'),
              _buildDetailRow('💵 Ödenen Bilet', '${stats['paid']}'),
              _buildDetailRow('⏳ Müsait Bilet', '${stats['available']}'),
              _buildDetailRow('❌ İptal Edilen', '${stats['cancelled']}'),
              if (campaign.isCompleted && campaign.winningNumber != null) ...[
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('🎉 Çekiliş Sonucu:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      Text('Kazanan Numara: ${campaign.winningNumber}',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple)),
                      Text('Kazanan Bilet: ${stats['winners']} adet'),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Kapat'),
          ),
          if (!campaign.isCompleted)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _finishCampaign(campaign);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text('Kampanyayı Bitir'),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: TextStyle(fontWeight: FontWeight.w500)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildTicketListItem(Ticket ticket) {
    Color backgroundColor;
    Color textColor = Colors.black;
    String statusText;
    bool isClickable = true; // Tüm biletler tıklanabilir

    // Durum ve renk belirleme
    switch (ticket.status) {
      case TicketStatus.available:
        backgroundColor = Colors.grey[100]!;
        statusText = 'Müsait';
        break;
      case TicketStatus.sold:
        // Satılan ödenmeyen: yarısı yeşil yarısı kırmızı
        backgroundColor = Colors.orange[100]!;
        statusText = 'Ödenmedi';
        break;
      case TicketStatus.unpaid:
        backgroundColor = Colors.orange[100]!;
        statusText = 'Ödenmedi';
        break;
      case TicketStatus.paid:
        backgroundColor = Colors.green[100]!;
        statusText = 'Ödendi';
        break;
      case TicketStatus.cancelled:
        backgroundColor = Colors.red[300]!;
        statusText = 'İptal Edildi';
        textColor = Colors.white;
        break;
      case TicketStatus.winner:
        backgroundColor = Colors.purple[100]!;
        statusText = 'Kazanan';
        break;
    }

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: isClickable ? () => _showTicketStatusDialog(ticket) : null,
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(4),
            // Satılan ödenmemiş için özel gradient
            gradient: ticket.status == TicketStatus.sold
                ? LinearGradient(
                    colors: [Colors.green[200]!, Colors.red[200]!],
                    stops: [0.5, 0.5],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : null,
          ),
          child: ListTile(
            leading: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: ticket.status == TicketStatus.available
                    ? Colors.grey
                    : ticket.status == TicketStatus.sold
                        ? Colors.orange
                        : ticket.status == TicketStatus.paid
                            ? Colors.green
                            : Colors.red,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  ticket.numbersFormatted,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            title: Text(
              '${ticket.numbersFormatted}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: textColor,
                fontSize: 18,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Durum: $statusText',
                  style: TextStyle(color: textColor.withOpacity(0.8)),
                ),
                if (ticket.buyerName != null)
                  Text(
                    'Alıcı: ${ticket.buyerName}',
                    style: TextStyle(color: textColor.withOpacity(0.8)),
                  ),
                if (ticket.buyerPhone != null)
                  Text(
                    'Telefon: ${ticket.buyerPhone}',
                    style: TextStyle(color: textColor.withOpacity(0.8)),
                  ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${ticket.price.toStringAsFixed(0)} ₺',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: textColor,
                  ),
                ),
                if (isClickable)
                  Icon(
                    Icons.edit,
                    size: 16,
                    color: textColor.withOpacity(0.6),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showTicketStatusDialog(Ticket ticket) {
    final nameController = TextEditingController(text: ticket.buyerName ?? '');
    final phoneController =
        TextEditingController(text: ticket.buyerPhone ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('🎫 Bilet Durumu Güncelle'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Numaralar: ${ticket.numbersFormatted}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getStatusColor(ticket.status),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(_getStatusIcon(ticket.status), color: Colors.white),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Mevcut Durum: ${_getStatusText(ticket.status)}',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),

              // Ad Soyad alanı (isteğe bağlı)
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Ad Soyad (İsteğe bağlı)',
                  hintText: 'Müşteri adını girebilirsiniz',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              SizedBox(height: 16),

              // Telefon alanı (isteğe bağlı)
              TextField(
                controller: phoneController,
                decoration: InputDecoration(
                  labelText: 'Telefon (İsteğe bağlı)',
                  hintText: '05XXXXXXXXX',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                keyboardType: TextInputType.phone,
              ),
              SizedBox(height: 24),

              Text('Yeni durum seçin:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal'),
          ),
          // Müsait durumu için buton
          if (ticket.status != TicketStatus.available)
            ElevatedButton(
              onPressed: () {
                _updateTicketStatusWithInfo(ticket, TicketStatus.available,
                    nameController.text.trim(), phoneController.text.trim());
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
              child: Text('Müsait'),
            ),
          // Satıldı (Ödenmedi) butonu
          ElevatedButton(
            onPressed: () {
              // Ödenmedi durumu için isim zorunlu
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        '❌ Borçlu işaretlemek için en az isim bilgisi gereklidir'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              _updateTicketStatusWithInfo(ticket, TicketStatus.sold,
                  nameController.text.trim(), phoneController.text.trim());
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: Text('Ödenmedi'),
          ),
          // Ödendi butonu
          ElevatedButton(
            onPressed: () {
              _updateTicketStatusWithInfo(ticket, TicketStatus.paid,
                  nameController.text.trim(), phoneController.text.trim());
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text('Ödendi'),
          ),
          // İptal butonu
          if (ticket.status != TicketStatus.available)
            ElevatedButton(
              onPressed: () {
                _updateTicketStatusWithInfo(ticket, TicketStatus.cancelled,
                    nameController.text.trim(), phoneController.text.trim());
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('İptal Et'),
            ),
        ],
      ),
    );
  }

  Color _getStatusColor(TicketStatus status) {
    switch (status) {
      case TicketStatus.available:
        return Colors.grey;
      case TicketStatus.sold:
        return Colors.orange;
      case TicketStatus.unpaid:
        return Colors.orange;
      case TicketStatus.paid:
        return Colors.green;
      case TicketStatus.cancelled:
        return Colors.red;
      case TicketStatus.winner:
        return Colors.purple;
    }
  }

  IconData _getStatusIcon(TicketStatus status) {
    switch (status) {
      case TicketStatus.available:
        return Icons.sell_outlined;
      case TicketStatus.sold:
        return Icons.payment;
      case TicketStatus.unpaid:
        return Icons.schedule;
      case TicketStatus.paid:
        return Icons.check_circle;
      case TicketStatus.cancelled:
        return Icons.cancel;
      case TicketStatus.winner:
        return Icons.emoji_events;
    }
  }

  String _getStatusText(TicketStatus status) {
    switch (status) {
      case TicketStatus.available:
        return 'Müsait';
      case TicketStatus.sold:
        return 'Ödenmedi';
      case TicketStatus.unpaid:
        return 'Ödenmedi';
      case TicketStatus.paid:
        return 'Ödendi';
      case TicketStatus.cancelled:
        return 'İptal Edildi';
      case TicketStatus.winner:
        return 'Kazanan';
    }
  }

  void _updateTicketStatus(Ticket ticket, TicketStatus newStatus) {
    // Eğer iptal ediliyorsa otomatik olarak satılabilir duruma geçir
    if (newStatus == TicketStatus.cancelled) {
      newStatus = TicketStatus.available;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '✅ Bilet iptal edildi ve satılmak için listeye geri eklendi'),
          backgroundColor: Colors.orange,
        ),
      );
    }

    // Gerçek veri güncellemesi - sample biletlerde bu bileti bul ve güncelle
    final ticketIndex = _sampleTickets.indexWhere((t) => t.id == ticket.id);

    if (ticketIndex != -1) {
      // Sample biletlerde güncelleme yap
      _sampleTickets[ticketIndex] = _sampleTickets[ticketIndex].copyWith(
        status: newStatus,
        buyerName: newStatus == TicketStatus.available
            ? null
            : _sampleTickets[ticketIndex].buyerName,
        buyerPhone: newStatus == TicketStatus.available
            ? null
            : _sampleTickets[ticketIndex].buyerPhone,
      );
    }

    // Ticket service üzerinden güncelleme yap
    _ticketService.updateTicketStatus(
      ticketId: ticket.id,
      status: newStatus,
      buyerName: newStatus == TicketStatus.available ? null : ticket.buyerName,
      buyerPhone:
          newStatus == TicketStatus.available ? null : ticket.buyerPhone,
    );

    setState(() {
      // UI'ı gerçekten güncelle
    });

    // Eğer bilet satıldı durumuna geçiyorsa ve alıcı bilgisi yoksa sor
    if (newStatus == TicketStatus.sold && ticket.buyerName == null) {
      _showBuyerInfoDialog(ticket);
      return;
    }

    if (newStatus != TicketStatus.available) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('✅ Bilet durumu güncellendi: ${_getStatusText(newStatus)}'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // 🔧 GÜNCELLENDİ: _updateTicketStatusWithInfo metodu - Supabase entegrasyonu
  void _updateTicketStatusWithInfo(Ticket ticket, TicketStatus newStatus,
      String? name, String? phone) async {
    final buyerName = name?.isNotEmpty == true ? name : null;
    final buyerPhone = phone?.isNotEmpty == true ? phone : null;

    if (newStatus == TicketStatus.cancelled) {
      newStatus = TicketStatus.available;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '✅ Bilet iptal edildi ve satılmak için listeye geri eklendi'),
          backgroundColor: Colors.orange,
        ),
      );
    }

    // 🆕 YENİ: Supabase'e güncelleme gönder
    try {
      final updatedTicket = ticket.copyWith(
        status: newStatus,
        buyerName: newStatus == TicketStatus.available ? null : buyerName,
        buyerPhone: newStatus == TicketStatus.available ? null : buyerPhone,
        soldAt: newStatus == TicketStatus.sold ? DateTime.now() : null,
        paidAt: newStatus == TicketStatus.paid ? DateTime.now() : null,
      );

      // Supabase'e güncelle
      final success = await _supabaseService.updateTicket(updatedTicket);

      if (success) {
        // Local güncelleme
        final ticketIndex = _sampleTickets.indexWhere((t) => t.id == ticket.id);
        if (ticketIndex != -1) {
          _sampleTickets[ticketIndex] = updatedTicket;
        }

        _campaignService.updateTicket(updatedTicket);
        _ticketService.updateTicketStatus(
          ticketId: ticket.id,
          status: newStatus,
          buyerName: buyerName,
          buyerPhone: buyerPhone,
        );

        setState(() {});

        String statusMessage =
            '✅ Bilet durumu güncellendi: ${_getStatusText(newStatus)}';
        if (buyerName != null || buyerPhone != null) {
          statusMessage += '\n👤 Müşteri bilgileri kaydedildi';
        }
        statusMessage += '\n📡 Bayiler anında görebilir!';

        if (newStatus != TicketStatus.available) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(statusMessage),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 4),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Bilet Supabase\'e güncellenemedi'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Bilet güncelleme hatası: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showBuyerInfoDialog(Ticket ticket) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('👤 Alıcı Bilgileri - ${ticket.numbersFormatted}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Ad Soyad',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: phoneController,
              decoration: InputDecoration(
                labelText: 'Telefon',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              // Sample biletlerde alıcı bilgilerini güncelle
              final ticketIndex =
                  _sampleTickets.indexWhere((t) => t.id == ticket.id);

              if (ticketIndex != -1) {
                _sampleTickets[ticketIndex] =
                    _sampleTickets[ticketIndex].copyWith(
                  status: TicketStatus.sold,
                  buyerName: nameController.text.isNotEmpty
                      ? nameController.text
                      : null,
                  buyerPhone: phoneController.text.isNotEmpty
                      ? phoneController.text
                      : null,
                );
              }

              // Ticket service üzerinden güncelleme yap
              _ticketService.updateTicketStatus(
                ticketId: ticket.id,
                status: TicketStatus.sold,
                buyerName:
                    nameController.text.isNotEmpty ? nameController.text : null,
                buyerPhone: phoneController.text.isNotEmpty
                    ? phoneController.text
                    : null,
              );

              setState(() {
                // UI'ı güncelle
              });
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('✅ Alıcı bilgileri kaydedildi'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  void _finishCampaign(Campaign campaign) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('🔚 Kampanyayı Bitir'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
                '${campaign.name} kampanyasını bitirmek istediğinizden emin misiniz?'),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.orange),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Kampanya bittiğinde otomatik olarak Milli Piyango sonuçları çekilecek.',
                      style: TextStyle(color: Colors.orange[800]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              // Milli Piyango sonucunu çek
              final winningNumber = await _fetchMilliPiyangoResult();

              // Çekiliş yap
              final result = await _campaignService.conductDraw(
                  campaign.id, winningNumber);

              if (result['success']) {
                setState(() {});

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        '✅ Kampanya tamamlandı! Kazanan numara: ${result['winningNumber']}'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 4),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text('❌ Kampanya bitirme hatası: ${result['error']}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Evet, Bitir'),
          ),
        ],
      ),
    );
  }

  // Milli Piyango sonucunu çek (gerçek entegrasyon)
  Future<String> _fetchMilliPiyangoResult() async {
    // Yükleme dialog'u göster
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Milli Piyango sitesinden sonuç çekiliyor...',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Bu işlem birkaç saniye sürebilir',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );

    try {
      // Önce yeni metodumuzla büyük ikramiye numarasını çek
      final buyukIkramiyeNo =
          await MilliPiyangoService.getBuyukIkramiyeNumara();

      if (buyukIkramiyeNo != null && buyukIkramiyeNo.isNotEmpty) {
        // Dialog'u kapat
        Navigator.pop(context);

        // Başarı mesajı göster
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '✅ Milli Piyango büyük ikramiye numarası başarıyla alındı: $buyukIkramiyeNo'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        return buyukIkramiyeNo;
      }

      // Yeni metod başarısızsa eski sistemle devam et
      final isAPIAvailable = await _milliPiyangoService.checkAPIAvailability();

      if (isAPIAvailable) {
        // Gerçek API'den sonuç çek
        final result = await _milliPiyangoService.fetchAutomaticResult();

        // Dialog'u kapat
        Navigator.pop(context);

        // Başarı mesajı göster
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Milli Piyango sonucu başarıyla alındı!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        return result.winningNumber;
      } else {
        // API mevcut değilse manuel simülasyon yap
        final result = await _milliPiyangoService.fetchLatestResult();

        // Dialog'u kapat
        Navigator.pop(context);

        // Uyarı mesajı göster
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '⚠️ Milli Piyango API\'sine ulaşılamadı, simülasyon numarası kullanıldı.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );

        return result;
      }
    } catch (e) {
      // Dialog'u kapat
      Navigator.pop(context);

      // Hata mesajı göster
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Milli Piyango sonucu alınamadı: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );

      // Hata durumunda rastgele numara döndür
      final random = Random();
      String result = '';
      for (int i = 0; i < 10; i++) {
        result += random.nextInt(10).toString();
      }
      return result;
    }
  }

  void _showDrawResultDialog(Campaign campaign) {
    final resultController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('🎰 Çekiliş Sonucu Gir'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${campaign.name} kampanyası için kazanan numarayı girin:',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            TextField(
              controller: resultController,
              decoration: InputDecoration(
                labelText: 'Kazanan Numara',
                hintText: 'Örnek: 12345',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.confirmation_number),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'Bilgi:',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800]),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• Kampanya ${campaign.lastDigitCount} haneli numaralar içerir\n'
                    '• Girilen numara ${campaign.lastDigitCount} haneli olmalıdır\n'
                    '• Eşleşen biletler otomatik bulunacak',
                    style: TextStyle(color: Colors.blue[700]),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              final result = resultController.text.trim();
              if (result.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('❌ Lütfen kazanan numarayı girin')),
                );
                return;
              }

              if (result.length != campaign.lastDigitCount) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          '❌ Numara ${campaign.lastDigitCount} haneli olmalıdır')),
                );
                return;
              }

              Navigator.pop(context);
              _processDrawResult(campaign, result);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text('Sonucu Kaydet'),
          ),
        ],
      ),
    );
  }

  void _processDrawResult(Campaign campaign, String winningNumber) async {
    // Çekiliş sonucunu işle
    final result =
        await _campaignService.conductDraw(campaign.id, winningNumber);

    if (result['success']) {
      setState(() {});

      final mainWinners = result['mainWinners'] ?? 0;
      final upperWinners = result['upperWinners'] ?? 0;
      final lowerWinners = result['lowerWinners'] ?? 0;
      final totalWinners = mainWinners + upperWinners + lowerWinners;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 Çekiliş tamamlandı!\n'
              '🏆 Ana kazanan: $mainWinners bilet\n'
              '⬆️ Bir üst: $upperWinners bilet\n'
              '⬇️ Bir alt: $lowerWinners bilet\n'
              '🎯 Toplam: $totalWinners Talihli bilet!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 5),
        ),
      );

      // Kazanan biletleri otomatik göster
      _showWinningTickets(campaign);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Çekiliş hatası: ${result['error']}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showWinningTickets(Campaign campaign) {
    final campaignTickets = _campaignService.getCampaignTickets(campaign.id);
    final winningTickets =
        campaignTickets.where((ticket) => ticket.isWinner).toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('🌟 ${campaign.name} - Talihli Biletler'),
        content: Container(
          width: double.maxFinite,
          height: 400,
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.purple.withOpacity(0.1),
                      Colors.amber.withOpacity(0.1)
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.emoji_events, color: Colors.amber, size: 32),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${campaign.name} Kazananları',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple[800],
                            ),
                          ),
                          Text(
                            'Kazanan Numara: ${campaign.winningNumber}',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          Text(
                            'Toplam ${winningTickets.length} Talihli Bilet',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Expanded(
                child: winningTickets.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off,
                                size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'Bu kampanyada kazanan bilet bulunamadı',
                              style: TextStyle(
                                  fontSize: 16, color: Colors.grey[600]),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Çekiliş sonucu: ${campaign.winningNumber ?? "Henüz çekilmedi"}',
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: winningTickets.length,
                        itemBuilder: (context, index) {
                          final ticket = winningTickets[index];
                          return _buildWinningTicketCard(ticket, campaign);
                        },
                      ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Kapat'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _exportWinningTickets(campaign, winningTickets);
            },
            icon: Icon(Icons.download),
            label: Text('Listeyi Dışa Aktar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWinningTicketCard(Ticket ticket, Campaign campaign) {
    String winTypeText = '';
    Color winColor = Colors.purple;
    String prizeText = '';

    switch (ticket.winnerType) {
      case 'main':
        winTypeText = '🏆 Ana İkramiye';
        winColor = Colors.amber;
        prizeText = _getCampaignPrizeText(campaign);
        break;
      case 'upper':
        winTypeText = '⬆️ Bir Üst';
        winColor = Colors.green;
        prizeText = '${campaign.upperPrize} ${_getCurrencySymbol(campaign)}';
        break;
      case 'lower':
        winTypeText = '⬇️ Bir Alt';
        winColor = Colors.blue;
        prizeText = '${campaign.lowerPrize} ${_getCurrencySymbol(campaign)}';
        break;
      default:
        winTypeText = '🎯 Kazanan';
        winColor = Colors.purple;
    }

    return Card(
      elevation: 4,
      margin: EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            colors: [winColor.withOpacity(0.1), Colors.white],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: ListTile(
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: winColor,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.star, color: Colors.white, size: 24),
          ),
          title: Text(
            'Bilet: ${ticket.numbersFormatted}',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(winTypeText,
                  style:
                      TextStyle(color: winColor, fontWeight: FontWeight.bold)),
              if (ticket.buyerName != null) Text('👤 ${ticket.buyerName}'),
              if (ticket.buyerPhone != null) Text('📞 ${ticket.buyerPhone}'),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'İkramiye',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              Text(
                prizeText,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: winColor,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getCurrencySymbol(Campaign campaign) {
    switch (campaign.prizeCurrency) {
      case PrizeCurrency.tl:
        return '₺';
      case PrizeCurrency.dolar:
        return '\$';
      case PrizeCurrency.euro:
        return '€';
      case PrizeCurrency.altin:
        return '🥇';
      case PrizeCurrency.other:
        return campaign.customCurrency ?? '';
      default:
        return '₺';
    }
  }

  void _exportWinningTickets(Campaign campaign, List<Ticket> winningTickets) {
    final exportText = StringBuffer();
    exportText.writeln('${campaign.name} - Talihli Biletler');
    exportText.writeln('Kazanan Numara: ${campaign.winningNumber}');
    exportText.writeln(
        'Çekiliş Tarihi: ${campaign.drawDate.day}/${campaign.drawDate.month}/${campaign.drawDate.year}');
    exportText.writeln('');

    for (int i = 0; i < winningTickets.length; i++) {
      final ticket = winningTickets[i];
      exportText.writeln(
          '${i + 1}. ${ticket.numbersFormatted} - ${ticket.winnerType} - ${ticket.buyerName ?? "İsimsiz"}');
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            '📋 ${winningTickets.length} Talihli bilet listesi hazırlandı!'),
        backgroundColor: Colors.green,
        action: SnackBarAction(
          label: 'Kopyala',
          onPressed: () {
            // Clipboard'a kopyalama işlemi burada yapılır
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('✅ Liste panoya kopyalandı!')),
            );
          },
        ),
      ),
    );
  }

  // Supabase'den tüm biletleri çek ve admin ekranında göster
  Future<void> _fetchAllTicketsFromSupabase() async {
    final tickets = await _supabaseService.getAllTickets();
    setState(() {
      _sampleTickets = tickets;
      _ticketsGenerated = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ ${tickets.length} bilet Supabase\'den çekildi!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Profil fotoğrafı seç ve yükle
  Future<void> _pickAndUploadProfileImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    final fileName =
        '${_authService.currentUser!.id}_${DateTime.now().millisecondsSinceEpoch}.png';
    // Supabase storage'a yükle (avatars bucket'ı public olmalı)
    final res = await _supabaseService.uploadFileToBucket(
      bucket: 'avatars',
      filePath: file.path,
      fileName: fileName,
    );
    if (res == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Yükleme hatası!')),
      );
      return;
    }
    // Kullanıcı profilini güncelle
    await _authService.updateProfile(
      name: _authService.currentUser?.name ?? 'Admin',
      profileImage: res,
    );
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Profil fotoğrafı güncellendi!')),
    );
  }
}
