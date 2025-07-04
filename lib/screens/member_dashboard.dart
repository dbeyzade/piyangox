import 'package:flutter/material.dart';
import '../models/ticket.dart';
import '../models/campaign.dart';
import '../services/auth_service.dart';
import '../services/campaign_service.dart';
import 'login_screen.dart';
import '../widgets/dove_background.dart';

class MemberDashboard extends StatefulWidget {
  const MemberDashboard({super.key});

  @override
  _MemberDashboardState createState() => _MemberDashboardState();
}

class _MemberDashboardState extends State<MemberDashboard> {
  final AuthService _authService = AuthService();
  final CampaignService _campaignService = CampaignService();
  
  String _selectedMenuItem = 'liste';

  @override
  void initState() {
    super.initState();
    // Başlangıçta paylaşılan veriyi yükle
    _campaignService.refreshFromSharedData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: DoveBackground(
        child: Row(
          children: [
          // Sol menü
          Container(
            width: 280,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF6A1B9A),
                  Color(0xFF8E24AA),
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
                
                // Ana içerik alanı
                Expanded(
                  child: _buildMainContent(),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildSideMenu() {
    final menuItems = [
      {'id': 'liste', 'title': 'Liste', 'icon': Icons.list, 'color': Colors.purple},
      {'id': 'biletlerim', 'title': 'Biletlerim', 'icon': Icons.confirmation_number, 'color': Colors.blue},
      {'id': 'kampanyalar', 'title': 'Kampanyalar', 'icon': Icons.campaign, 'color': Colors.deepPurple},
      {'id': 'sansliyim', 'title': 'Şanslı Hissediyorum', 'icon': Icons.casino, 'color': Colors.orange},
      {'id': 'gecmis_cekilisler', 'title': 'Geçmiş Çekilişler', 'icon': Icons.history, 'color': Colors.green},
      {'id': 'kazanan_numara', 'title': 'Kazanan Talihli Numara', 'icon': Icons.emoji_events, 'color': Colors.purple},
      {'id': 'toplam_gelir', 'title': 'Toplam Gelir', 'icon': Icons.trending_up, 'color': Colors.teal},
      {'id': 'bilgilerim', 'title': 'Bilgilerim', 'icon': Icons.person, 'color': Colors.indigo},
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
                    radius: 40,
                    backgroundColor: Colors.white,
                    child: _authService.currentUser?.profileImage != null
                        ? ClipOval(
                            child: Image.asset(
                              _authService.currentUser!.profileImage!,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.person, size: 40, color: Color(0xFF6A1B9A));
                              },
                            ),
                          )
                        : const Icon(
                            Icons.person,
                            size: 40,
                            color: Color(0xFF6A1B9A),
                          ),
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
              const SizedBox(height: 12),
              Text(
                _authService.currentUser?.name ?? 'Üye',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _authService.currentUser?.isGuest == true ? 'Misafir Üye' : 'Üye Paneli',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
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
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withOpacity(0.2) : null,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: Icon(
                    item['icon'] as IconData,
                    color: isSelected ? Colors.white : Colors.white70,
                    size: 24,
                  ),
                  title: Text(
                    item['title'] as String,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 16,
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
                padding: const EdgeInsets.symmetric(vertical: 12),
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
          
          // Tarih
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
      case 'liste':
        return _buildListe();
      case 'biletlerim':
        return _buildBiletlerim();
      case 'kampanyalar':
        return _buildKampanyalar();
      case 'sansliyim':
        return _buildSansliHissediyorum();
      case 'gecmis_cekilisler':
        return _buildGecmisCekilisler();
      case 'kazanan_numara':
        return _buildKazananNumara();
      case 'toplam_gelir':
        return _buildToplamGelir();
      case 'bilgilerim':
        return _buildBilgilerim();
      default:
        return _buildListe();
    }
  }

  String _getPageTitle() {
    switch (_selectedMenuItem) {
      case 'liste': return '📋 Yayınlanan Liste';
      case 'biletlerim': return '🎫 Biletlerim';
      case 'kampanyalar': return '🎯 Kampanyalar';
      case 'sansliyim': return '🍀 Şanslı Hissediyorum';
      case 'gecmis_cekilisler': return '📜 Geçmiş Çekilişler';
      case 'kazanan_numara': return '🏆 Kazanan Talihli Numara';
      case 'toplam_gelir': return '📈 Toplam Gelir';
      case 'bilgilerim': return '👤 Bilgilerim';
      default: return '🏪 Üye Paneli';
    }
  }

  Widget _buildMenuCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 8),
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

  // Liste sayfası
  Widget _buildListe() {
    final publishedTickets = _campaignService.getPublishedTickets();
    
    return Padding(
      padding: const EdgeInsets.all(24),
      child: publishedTickets.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inbox, size: 80, color: Colors.grey),
                  const SizedBox(height: 24),
                  Text(
                    'Henüz liste yayınlanmamış',
                    style: TextStyle(fontSize: 24, color: Colors.grey[600], fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Admin liste yayınladığında burada görünecek',
                    style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Başlık ve bilgi
                Row(
                  children: [
                    const Icon(Icons.list, size: 28, color: Color(0xFF6A1B9A)),
                    const SizedBox(width: 12),
                    Text(
                      'Toplam ${publishedTickets.length} bilet',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Bilet listesi - Yatay scroll ile soldan sağa
                Expanded(
                  child: GridView.builder(
                    scrollDirection: Axis.horizontal, // Yatay scroll
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, // 2 satır
                      childAspectRatio: 0.7, // Bilet boyut oranı düzeltildi
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: publishedTickets.length,
                    itemBuilder: (context, index) {
                      final ticket = publishedTickets[index];
                      return _buildPublishedTicketItem(ticket);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  // Biletlerim sayfası
  Widget _buildBiletlerim() {
    // Üyenin satın aldığı biletleri getir (şimdilik örnek)
    final myTickets = _campaignService.getPublishedTickets().where((ticket) => 
      ticket.status == TicketStatus.paid || ticket.status == TicketStatus.sold
    ).take(3).toList(); // Örnek olarak ilk 3 satılmış bileti göster
    
    return Padding(
      padding: const EdgeInsets.all(24),
      child: myTickets.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.confirmation_number_outlined, size: 80, color: Colors.grey),
                  const SizedBox(height: 24),
                  Text(
                    'Henüz biletiniz yok',
                    style: TextStyle(fontSize: 24, color: Colors.grey[600], fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Şansınızı denemek için "Liste" sekmesinden bilet satın alın',
                    style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Başlık ve bilgi
                Row(
                  children: [
                    const Icon(Icons.confirmation_number, size: 28, color: Colors.blue),
                    const SizedBox(width: 12),
                    Text(
                      'Biletlerim (${myTickets.length} adet)',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Bilet listesi
                Expanded(
                  child: ListView.builder(
                    itemCount: myTickets.length,
                    itemBuilder: (context, index) {
                      final ticket = myTickets[index];
                      return _buildMyTicketCard(ticket);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildMyTicketCard(Ticket ticket) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: _buildTicketCard(ticket),
    );
  }

  // Şanslı hissediyorum sayfası
  Widget _buildSansliHissediyorum() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.casino, size: 80, color: Colors.orange),
            const SizedBox(height: 24),
            const Text(
              'Şansını Dene!',
              style: TextStyle(fontSize: 28, color: Colors.orange, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Bu özellik yakında aktif olacak',
              style: TextStyle(fontSize: 16, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
                    const Icon(Icons.campaign_outlined, size: 64, color: Colors.grey),
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
                  crossAxisCount: 3, // 3 sütun
                  childAspectRatio: 2.2, // Daha küçük ve geniş
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
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
      // Boyutları kaldırdık, GridView otomatik ayarlayacak
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                    
                    // Orta - Kampanya adı (çerçeveli)
                    Expanded(
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.black, width: 2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            campaign.name.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                              letterSpacing: 1.0,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                    
                    // Sağ - Çekiliş tarihi ve numara
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
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
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                
                // Orta kısım - İkramiye (ÇOK BÜYÜK!)
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('🕊️', style: TextStyle(fontSize: 32)), // GÜVERCINÍ BÜYÜTTÜM!
                    const SizedBox(width: 8),
                    const Text(
                      'İKRAMİYE',
                      style: TextStyle(
                        fontSize: 22, // İKRAMİYE YAZISINI BÜYÜTTÜM!
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      campaign.prizeAmount,
                      style: const TextStyle(
                        fontSize: 24, // TUTARI DA BÜYÜTTÜM!
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                
                // Alt kısım - Bir alt/üst ikramiye (çerçeveli)
                const Spacer(),
                Row(
                  children: [
                    // Bir Alt Numaralı Bilete - Kırmızı çerçeve
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.red, width: 2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Bir Alt Numaralı Bilete',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              campaign.lowerPrize.isNotEmpty ? campaign.lowerPrize : '10.000',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 8),
                    
                    // Bir Üst Numaralı Bilete - Kırmızı çerçeve
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.red, width: 2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Bir Üst Numaralı Bilete',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              campaign.upperPrize.isNotEmpty ? campaign.upperPrize : '10.000',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
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

  // Geçmiş çekilişler sayfası
  Widget _buildGecmisCekilisler() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.history, size: 80, color: Colors.green),
            const SizedBox(height: 24),
            const Text(
              'Geçmiş Çekilişler',
              style: TextStyle(fontSize: 24, color: Colors.green, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Henüz tamamlanmış çekiliş bulunmuyor',
              style: TextStyle(fontSize: 16, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Kazanan Talihli Numara sayfası
  Widget _buildKazananNumara() {
    final completedCampaigns = _campaignService.completedCampaigns;
    
    return Padding(
      padding: const EdgeInsets.all(24),
      child: completedCampaigns.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.emoji_events, size: 80, color: Colors.purple),
                  const SizedBox(height: 24),
                  const Text(
                    'Henüz Kazanan Numara Yok',
                    style: TextStyle(fontSize: 24, color: Colors.purple, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Kampanyalar tamamlandığında kazanan numaralar burada görünecek',
                    style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Başlık
                const Row(
                  children: [
                    Icon(Icons.emoji_events, size: 32, color: Colors.purple),
                    SizedBox(width: 12),
                    Text(
                      'Kazanan Talihli Numaralar',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Kazanan numaralar listesi
                Expanded(
                  child: ListView.builder(
                    itemCount: completedCampaigns.length,
                    itemBuilder: (context, index) {
                      final campaign = completedCampaigns[index];
                      return _buildWinningNumberCard(campaign);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildWinningNumberCard(Campaign campaign) {
    final stats = _campaignService.getTicketStats(campaign.id);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kampanya başlığı
          Row(
            children: [
              const Icon(Icons.campaign, color: Colors.purple, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  campaign.name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Gerçekçi bilet tasarımı - Kazanan numara ile
          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFF8BBD9), // Açık pembe
                      Color(0xFFE1BEE7), // Orta pembe
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    // Ana bilet içeriği
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          // Üst satır - Bilet fiyatı, NAZ, Kazanan numara
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Sol - Bilet fiyatı
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: const Text(
                                      'BİLET FIYATI',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    campaign.ticketPrice.toStringAsFixed(0),
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                              
                              // Orta - NAZ
                              Text(
                                campaign.name,
                                style: TextStyle(
                                  fontSize: 64,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.purple[800],
                                  letterSpacing: 8.0,
                                  height: 0.8,
                                ),
                              ),
                              
                              // Sağ - Kazanan numara (özel vurgu ile)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.amber[300],
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.orange, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.orange.withOpacity(0.3),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      '🏆 KAZANAN',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red[800],
                                      ),
                                    ),
                                    Text(
                                      campaign.winningNumber ?? '54',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.red[800],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 8),
                          
                          // Orta satır - Çekiliş tarihi
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: const Text(
                                  'ÇEKİLİŞ TARİHİ',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${campaign.drawDate.day}/${campaign.drawDate.month}/${campaign.drawDate.year}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // Ana ikramiye
                          Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.flutter_dash,
                                    color: Colors.purple[700],
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'demirci',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontStyle: FontStyle.italic,
                                      color: Colors.purple[700],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Icon(
                                    Icons.flutter_dash,
                                    color: Colors.purple[700],
                                    size: 16,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              SizedBox(
                                width: double.infinity,
                                child: Text(
                                  _formatPrizeAmount(campaign.prizeAmount),
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.black,
                                    letterSpacing: 1.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // Alt ikramiyeler
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Expanded(
                                child: Column(
                                  children: [
                                    const Text(
                                      'Bir Alt Numarası Bilet',
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: Colors.black54,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 2),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                      child: Text(
                                        _formatPrizeAmount(campaign.lowerPrize),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  children: [
                                    const Text(
                                      'Bir Üst Numarası Bilet',
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: Colors.black54,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 2),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                      child: Text(
                                        _formatPrizeAmount(campaign.upperPrize),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // Alt sarı-siyah çizgili kenar
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 8,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.yellow, Colors.black, Colors.yellow, Colors.black, Colors.yellow],
                            stops: [0.0, 0.2, 0.4, 0.6, 0.8],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Çekiliş sonuç özeti
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.emoji_events, color: Colors.green, size: 20),
                      const SizedBox(height: 4),
                      Text(
                        '${stats['winners']}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      Text(
                        'Kazanan Bilet',
                        style: TextStyle(fontSize: 12, color: Colors.green[700]),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.monetization_on, color: Colors.orange, size: 20),
                      const SizedBox(height: 4),
                      Text(
                        _formatPrizeAmount(campaign.prizeAmount),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      Text(
                        'Ana İkramiye',
                        style: TextStyle(fontSize: 12, color: Colors.orange[700]),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Toplam gelir sayfası
  Widget _buildToplamGelir() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.trending_up, size: 80, color: Colors.teal),
            const SizedBox(height: 24),
            const Text(
              'Toplam Gelir',
              style: TextStyle(fontSize: 24, color: Colors.teal, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              '0 ₺',
              style: TextStyle(fontSize: 32, color: Colors.teal, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Henüz kazanç elde etmediniz',
              style: TextStyle(fontSize: 16, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
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
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    // Profil resmi
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 80,
                          backgroundColor: Colors.grey[200],
                          child: user.profileImage != null
                              ? ClipOval(
                                  child: Image.asset(
                                    user.profileImage!,
                                    width: 160,
                                    height: 160,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(Icons.person, size: 80, color: Colors.grey[400]);
                                    },
                                  ),
                                )
                              : Icon(
                                  Icons.person,
                                  size: 80,
                                  color: Colors.grey[400],
                                ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF6A1B9A),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                              onPressed: _showProfileImageOptions,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Kullanıcı bilgileri
                    _buildInfoRow('👤 Ad Soyad', user.name),
                    if (!user.isGuest) _buildInfoRow('🆔 Kullanıcı Adı', user.username),
                    if (user.email != null && user.email!.isNotEmpty) _buildInfoRow('📧 E-posta', user.email!),
                    if (user.phone != null && user.phone!.isNotEmpty) _buildInfoRow('📞 Telefon', user.phone!),
                    _buildInfoRow('👑 Durum', user.isGuest ? 'Misafir Üye' : 'Kayıtlı Üye'),
                    if (!user.isGuest) _buildInfoRow('📅 Kayıt Tarihi', '${user.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}'),
                    
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
                                padding: const EdgeInsets.symmetric(vertical: 16),
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
                                padding: const EdgeInsets.symmetric(vertical: 16),
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

  Widget _buildPublishedTicketItem(Ticket ticket) {
    return _buildTicketCard(ticket);
  }

  // Gerçek bilet tasarımı - Milli Piyango benzeri
  Widget _buildTicketCard(Ticket ticket) {
    final campaign = _campaignService.campaigns.isNotEmpty 
        ? _campaignService.campaigns.first
        : Campaign(
            id: '',
            name: 'NAZ',
            lastDigitCount: 2,
            chanceCount: 2,
            ticketCount: 100,
            prizeCurrency: PrizeCurrency.tl,
            prizeAmount: '1500',
            lowerPrize: '100,0',
            upperPrize: '100,0',
            ticketPrice: 1500.0,
            weekNumber: 26,
            drawDate: DateTime(2025, 7, 9),
            createdAt: DateTime.now(),
          );

    return Container(
      width: 260,
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          color: const Color(0xFFF8D7E3), // Açık pembe tek renk
          child: Stack(
            children: [
              // Ana bilet içeriği
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  children: [
                    // Üst satır
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Sol - Bilet fiyatı
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(2),
                                border: Border.all(color: Colors.black, width: 1),
                              ),
                              child: const Text(
                                'BİLET FİYATI',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 7,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              '${campaign.ticketPrice.toStringAsFixed(0)} TL',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                        
                        // Orta - NAZ
                        Text(
                          campaign.name,
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            color: Colors.purple[900],
                            letterSpacing: 8,
                            height: 0.8,
                          ),
                        ),
                        
                        // Sağ taraf için boşluk
                        const SizedBox(width: 60),
                      ],
                    ),
                    
                    const Spacer(),
                    
                    // Ana ikramiye bölümü
                    Column(
                      children: [
                        // İkramiye yazısı
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '🕊️',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'ikramiye',
                              style: TextStyle(
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                        
                        // Ana ikramiye miktarı
                        Text(
                          campaign.prizeAmount,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                            height: 0.9,
                          ),
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Alt ve Üst ikramiye
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Bir Alt Numaralı Bilete
                            Column(
                              children: [
                                const Text(
                                  'Bir Alt Numaralı Bilete',
                                  style: TextStyle(
                                    fontSize: 8,
                                    color: Colors.black54,
                                  ),
                                ),
                                Text(
                                  campaign.lowerPrize,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                            
                            // Dikey çizgi
                            Container(
                              width: 1,
                              height: 25,
                              color: Colors.grey[400],
                              margin: const EdgeInsets.symmetric(horizontal: 16),
                            ),
                            
                            // Bir Üst Numaralı Bilete
                            Column(
                              children: [
                                const Text(
                                  'Bir Üst Numaralı Bilete',
                                  style: TextStyle(
                                    fontSize: 8,
                                    color: Colors.black54,
                                  ),
                                ),
                                Text(
                                  campaign.upperPrize,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 4),
                  ],
                ),
              ),
              
              // Sarı-siyah çizgili alt kenar
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: List.generate(20, (index) => 
                        index.isEven ? Colors.yellow[700]! : Colors.black),
                      stops: List.generate(20, (index) => index / 19),
                    ),
                  ),
                ),
              ),
              
              // Sağ üst - Çekiliş tarihi ve numara
              Positioned(
                top: 8,
                right: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Çekiliş tarihi
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: const Text(
                            'ÇEKİLİŞ TARİHİ',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 7,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          '9 TEMMUZ',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Bilet numarası
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.black, width: 1.5),
                      ),
                      child: Text(
                        ticket.numbersFormatted.replaceAll(' ', '').substring(
                          ticket.numbersFormatted.replaceAll(' ', '').length - campaign.lastDigitCount
                        ),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Satın Al durumu
              if (ticket.status == TicketStatus.available)
                Positioned(
                  bottom: 12,
                  right: 6,
                  child: InkWell(
                    onTap: () => _purchaseTicket(ticket),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Satın Al',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                )
              else if (ticket.status == TicketStatus.sold || ticket.status == TicketStatus.paid)
                Positioned(
                  bottom: 12,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Satıldı',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
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

  Widget _buildPrizeInfo(String label, String amount) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.black54,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            amount,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(TicketStatus status) {
    switch (status) {
      case TicketStatus.sold:
        return Colors.orange;
      case TicketStatus.paid:
        return Colors.green;
      case TicketStatus.cancelled:
        return Colors.red;
      case TicketStatus.winner:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _formatPrizeAmount(String amount) {
    try {
      final numAmount = double.parse(amount);
      if (numAmount >= 1000) {
        return '${(numAmount / 1000).toStringAsFixed(0)}.000';
      }
      return amount;
    } catch (e) {
      return amount;
    }
  }

  void _purchaseTicket(Ticket ticket) {
    // Satın alma işlemi burada yapılacak
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🎫 Bilet satın alma özelliği yakında eklenecek!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
                fontSize: 16,
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

  void _showProfileImageOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📷 Profil Resmi Seç'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Hazır resimlerden birini seçin:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildProfileImageOption('assets/images/profile1.png', 'Erkek 1'),
                _buildProfileImageOption('assets/images/profile2.png', 'Kadın 1'),
                _buildProfileImageOption('assets/images/profile3.png', 'Erkek 2'),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildProfileImageOption('assets/images/profile4.png', 'Kadın 2'),
                _buildProfileImageOption('assets/images/profile5.png', 'Avatar 1'),
                _buildProfileImageOption('assets/images/profile6.png', 'Avatar 2'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              _removeProfileImage();
              Navigator.pop(context);
            },
            child: const Text('Resmi Kaldır', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImageOption(String imagePath, String label) {
    return GestureDetector(
      onTap: () {
        _selectProfileImage(imagePath);
        Navigator.pop(context);
      },
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.grey[200],
            child: const Icon(Icons.person, size: 30, color: Color(0xFF6A1B9A)), // Placeholder icon
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  void _selectProfileImage(String imagePath) async {
    final success = await _authService.updateUserProfileImage(imagePath);
    if (success) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Profil resmi güncellendi!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Profil resmi güncellenemedi')),
      );
    }
  }

  void _removeProfileImage() async {
    final success = await _authService.updateUserProfileImage(null);
    if (success) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Profil resmi kaldırıldı!')),
      );
    }
  }

  void _showRegisterDialog() {
    final nameController = TextEditingController(text: _authService.currentUser?.name ?? '');
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📝 Üye Ol'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Ad Soyad',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(
                  labelText: 'Kullanıcı Adı',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.account_circle),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: 'Şifre',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                  helperText: 'En az 6 karakter olmalı',
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Şifre Tekrarı',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline),
                  helperText: 'Şifrenizi tekrar girin',
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'E-posta (opsiyonel)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Telefon (opsiyonel)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Zorunlu alanları kontrol et
              if (nameController.text.trim().isEmpty || 
                  usernameController.text.trim().isEmpty || 
                  passwordController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('❌ Ad, kullanıcı adı ve şifre gerekli')),
                );
                return;
              }

              // Şifre uzunluğunu kontrol et
              if (passwordController.text.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('❌ Şifre en az 6 karakter olmalı')),
                );
                return;
              }

              // Şifre tekrarını kontrol et
              if (passwordController.text != confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('❌ Şifreler eşleşmiyor')),
                );
                return;
              }

              final success = await _authService.convertGuestToMember(
                name: nameController.text.trim(),
                username: usernameController.text.trim(),
                password: passwordController.text,
                email: emailController.text.trim().isEmpty ? null : emailController.text.trim(),
                phone: phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
              );

              Navigator.pop(context);

              if (success) {
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✅ Başarıyla üye oldunuz!')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('❌ Bu kullanıcı adı zaten kullanılıyor')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Üye Ol'),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog() {
    final user = _authService.currentUser!;
    final nameController = TextEditingController(text: user.name);
    final emailController = TextEditingController(text: user.email ?? '');
    final phoneController = TextEditingController(text: user.phone ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('✏️ Bilgileri Düzenle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Ad Soyad',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'E-posta (opsiyonel)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'Telefon (opsiyonel)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
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
              final success = await _authService.updateUserProfile(
                name: nameController.text.trim().isEmpty ? null : nameController.text.trim(),
                email: emailController.text.trim().isEmpty ? null : emailController.text.trim(),
                phone: phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
              );

              Navigator.pop(context);

              if (success) {
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✅ Bilgiler güncellendi!')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('❌ Güncelleme başarısız')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Güncelle'),
          ),
        ],
      ),
    );
  }

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
              if (newPasswordController.text != confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('❌ Yeni şifreler eşleşmiyor')),
                );
                return;
              }

              if (newPasswordController.text.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('❌ Şifre en az 6 karakter olmalı')),
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
                  const SnackBar(content: Text('✅ Şifre başarıyla değiştirildi')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('❌ Mevcut şifre hatalı')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Değiştir'),
          ),
        ],
      ),
    );
  }

  void _logout() async {
    print('🚪 Member logout butonuna basıldı');
    
    // Önce logout yap
    await _authService.logout();
    print('✅ AuthService logout tamamlandı');
    
    // Sonra login ekranına git
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
      print('✅ LoginScreen\'e yönlendirildi');
    }
  }
} 