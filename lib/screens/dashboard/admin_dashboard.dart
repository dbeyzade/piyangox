import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';
import 'create_ticket_page.dart';
import 'draw_result_page.dart';
import '../../services/draw_service.dart';
import '../../core/navigation.dart';
import '../../widgets/share_row.dart';
import '../../main.dart'; // themeNotifier erişimi için

enum AdminMenu { genel, kampanya, borclular, biletler, uyeler, gecmis, tema }

class AdminDashboard extends StatefulWidget {
  final void Function()? onToggleTheme;
  const AdminDashboard({Key? key, this.onToggleTheme}) : super(key: key);
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final supabase = Supabase.instance.client;
  final drawService = DrawService('API_KEYINIZ');
  late ConfettiController _confettiController;
  int userCount = 0;
  int ticketCount = 0;
  List<Map<String, dynamic>> tickets = [];
  bool _loading = true;
  String? _winning;
  bool _loadingDraw = false;
  AdminMenu _selectedMenu = AdminMenu.genel;
  List<Map<String, dynamic>> borcluBiletler = [];
  bool _isDarkTheme = false;

  // Kampanya formu alanları
  final _kampanyaFormKey = GlobalKey<FormState>();
  final _kampanyaIsimCtrl = TextEditingController();
  final _cekilisTarihiCtrl = TextEditingController();
  final _biletFiyatiCtrl = TextEditingController();
  final _biletAdetiCtrl = TextEditingController();
  final _ikramiyeBedeliCtrl = TextEditingController();
  final _ikramiyeCinsiCtrl = TextEditingController();
  int _sonNumaraAdeti = 2;
  int _sansAdeti = 2;
  int _birNumaraAlti = 0;
  int _birNumaraUstu = 0;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
    _loadStats();
    _loadDraw();
    _loadBorclular();
  }

  Future<void> _loadStats() async {
    setState(() => _loading = true);
    final usersResponse = await supabase.from('users').select('id');
    final ticketsResponse = await supabase.from('tickets').select('*');
    setState(() {
      userCount = usersResponse.length;
      ticketCount = ticketsResponse.length;
      tickets = List<Map<String, dynamic>>.from(ticketsResponse);
      _loading = false;
    });
  }

  Future<void> _loadBorclular() async {
    final borclular =
        await supabase.from('tickets').select('*').eq('status', 'ödenmedi');
    setState(() {
      borcluBiletler = List<Map<String, dynamic>>.from(borclular);
    });
  }

  Future<void> _publishAll() async {
    await supabase
        .from('tickets')
        .update({'published': true}).eq('status', 'musaid');

    await _loadStats();
  }

  Future<void> _markAsSold(String ticketId) async {
    await supabase
        .from('tickets')
        .update({'status': 'satildi', 'published': false}).eq('id', ticketId);

    await _loadStats();
  }

  Future<void> _loadDraw() async {
    setState(() => _loadingDraw = true);
    final draw = await drawService.fetchLatestDraw();
    setState(() {
      _winning = draw?['winning_number'];
      _loadingDraw = false;
    });
  }

  Future<void> _markWinner() async {
    if (_winning == null) return;

    try {
      await supabase
          .from('tickets')
          .update({'is_winner': true}).eq('number', _winning!);

      // Konfeti efektini başlat
      _confettiController.play();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kazanan bilet işaretlendi! 🎉')),
      );

      // Bilet listesini yenile
      await _loadStats();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    }
  }

  Future<void> _updateTicketStatus(String id, String status) async {
    await supabase.from('tickets').update({
      'status': status,
      'published': status == 'musaid', // sadece musaid tekrar yayınlanabilir
      'note': status != 'ödenmedi' ? null : null,
    }).eq('id', id);
    _loadStats();
  }

  Future<void> _promptNoteAndUpdate(String id, String status) async {
    String? note = await showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: Text('Ödenmedi Açıklama Gerekli'),
          content: TextField(
            controller: controller,
            decoration:
                InputDecoration(labelText: 'Kullanıcı ismi veya açıklama'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                final value = controller.text.trim();
                if (value.isNotEmpty) {
                  Navigator.pop(context, value);
                }
              },
              child: Text('Kaydet'),
            ),
          ],
        );
      },
    );

    if (note != null) {
      await supabase.from('tickets').update({
        'status': status,
        'note': note,
        'published': false,
      }).eq('id', id);
      _loadStats();
    }
  }

  Widget _buildStatusControl(Map<String, dynamic> ticket) {
    final id = ticket['id'];
    final status = ticket['status'];
    final currentNote = ticket['note'] ?? '';
    final color = {
          'musaid': Colors.grey[800],
          'satildi': Colors.green[800],
          'iptal': Colors.black,
          'ödenmedi': Colors.red[800],
        }[status] ??
        Colors.grey;

    return Card(
      color: color,
      margin: EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        title: Text('Bilet No: ${ticket['number']}',
            style: TextStyle(color: Colors.white)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Durum: $status', style: TextStyle(color: Colors.white70)),
            if (status == 'ödenmedi' && currentNote.isNotEmpty)
              Text('Açıklama: $currentNote',
                  style: TextStyle(color: Colors.orangeAccent)),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(Icons.settings, color: Colors.white),
          onSelected: (value) {
            if (value == 'ödenmedi') {
              _promptNoteAndUpdate(id, value);
            } else {
              _updateTicketStatus(id, value);
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(value: 'musaid', child: Text('Müsait')),
            PopupMenuItem(value: 'satildi', child: Text('Satıldı')),
            PopupMenuItem(value: 'ödenmedi', child: Text('Ödenmedi')),
            PopupMenuItem(value: 'iptal', child: Text('İptal')),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketList() {
    if (_loading) return Center(child: CircularProgressIndicator());

    return Expanded(
      child: ListView.builder(
        itemCount: tickets.length,
        itemBuilder: (context, index) {
          return _buildStatusControl(tickets[index]);
        },
      ),
    );
  }

  Widget _buildDrawer() {
    return ListView(
      children: [
        DrawerHeader(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.admin_panel_settings, size: 48, color: Colors.white),
              SizedBox(height: 8),
              Text('Yönetici',
                  style: TextStyle(color: Colors.white, fontSize: 20)),
            ],
          ),
          decoration: BoxDecoration(color: Colors.deepPurple),
        ),
        ListTile(
          leading: Icon(Icons.dashboard),
          title: Text('Genel Bilgi'),
          selected: _selectedMenu == AdminMenu.genel,
          onTap: () => setState(() => _selectedMenu = AdminMenu.genel),
        ),
        ListTile(
          leading: Icon(Icons.campaign),
          title: Text('Kampanya Oluştur'),
          selected: _selectedMenu == AdminMenu.kampanya,
          onTap: () => setState(() => _selectedMenu = AdminMenu.kampanya),
        ),
        ListTile(
          leading: Icon(Icons.warning),
          title: Text('Borçlu Olanlar'),
          selected: _selectedMenu == AdminMenu.borclular,
          onTap: () {
            _loadBorclular();
            setState(() => _selectedMenu = AdminMenu.borclular);
          },
        ),
        ListTile(
          leading: Icon(Icons.list),
          title: Text('Biletleri Listele'),
          selected: _selectedMenu == AdminMenu.biletler,
          onTap: () => setState(() => _selectedMenu = AdminMenu.biletler),
        ),
        ListTile(
          leading: Icon(Icons.people),
          title: Text('Üyeler'),
          selected: _selectedMenu == AdminMenu.uyeler,
          onTap: () => setState(() => _selectedMenu = AdminMenu.uyeler),
        ),
        ListTile(
          leading: Icon(Icons.history),
          title: Text('Geçmiş Çekilişler'),
          selected: _selectedMenu == AdminMenu.gecmis,
          onTap: () => setState(() => _selectedMenu = AdminMenu.gecmis),
        ),
        SwitchListTile(
          title: Text('Koyu Tema'),
          secondary: Icon(_isDarkTheme ? Icons.dark_mode : Icons.light_mode),
          value: themeNotifier.value == ThemeMode.dark,
          onChanged: (dark) {
            setState(() => _isDarkTheme = dark);
            themeNotifier.value = dark ? ThemeMode.dark : ThemeMode.light;
          },
        ),
      ],
    );
  }

  Widget _buildGenelBilgi() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Toplam Üye: $userCount', style: TextStyle(fontSize: 18)),
        Text('Toplam Bilet: $ticketCount', style: TextStyle(fontSize: 18)),
        // Buraya satılan, satılmayan, borçlu bilet sayıları eklenebilir
        SizedBox(height: 16),
        ElevatedButton(
          onPressed: _publishAll,
          child: Text('Tüm Müsait Biletleri Yayınla'),
        ),
      ],
    );
  }

  Widget _buildKampanyaOlustur() {
    return Form(
      key: _kampanyaFormKey,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Kampanya Oluştur',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 24),

            // Kampanya İsmi
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[100],
              ),
              child: TextFormField(
                controller: _kampanyaIsimCtrl,
                decoration: InputDecoration(
                  labelText: 'Kampanya İsmi',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.transparent,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            SizedBox(height: 16),

            // Son Numara ve Şans Adeti
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey[100],
                    ),
                    child: DropdownButtonFormField<int>(
                      value: _sonNumaraAdeti,
                      decoration: InputDecoration(
                        labelText: 'Son Numara Adeti',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.transparent,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      items: [2, 3, 4]
                          .map((e) =>
                              DropdownMenuItem(value: e, child: Text('$e')))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _sonNumaraAdeti = v ?? 2),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey[100],
                    ),
                    child: DropdownButtonFormField<int>(
                      value: _sansAdeti,
                      decoration: InputDecoration(
                        labelText: 'Şans Adeti',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.transparent,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      items: [2, 3, 4]
                          .map((e) =>
                              DropdownMenuItem(value: e, child: Text('$e')))
                          .toList(),
                      onChanged: (v) => setState(() => _sansAdeti = v ?? 2),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Bir Numara Altı ve Üstü
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey[100],
                    ),
                    child: TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Bir Numara Altı',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.transparent,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => _birNumaraAlti = int.tryParse(v) ?? 0,
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey[100],
                    ),
                    child: TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Bir Numara Üstü',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.transparent,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => _birNumaraUstu = int.tryParse(v) ?? 0,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Çekiliş Tarihi
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[100],
              ),
              child: TextFormField(
                controller: _cekilisTarihiCtrl,
                decoration: InputDecoration(
                  labelText: 'Çekiliş Tarihi',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.transparent,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onTap: () async {
                  FocusScope.of(context).requestFocus(FocusNode());
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    _cekilisTarihiCtrl.text =
                        picked.toIso8601String().split('T').first;
                  }
                },
              ),
            ),
            SizedBox(height: 16),

            // Bilet Fiyatı ve Adeti
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey[100],
                    ),
                    child: TextFormField(
                      controller: _biletFiyatiCtrl,
                      decoration: InputDecoration(
                        labelText: 'Bilet Fiyatı',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.transparent,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey[100],
                    ),
                    child: TextFormField(
                      controller: _biletAdetiCtrl,
                      decoration: InputDecoration(
                        labelText: 'Bilet Adeti',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.transparent,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            // İkramiye Bedeli
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[100],
              ),
              child: TextFormField(
                controller: _ikramiyeBedeliCtrl,
                decoration: InputDecoration(
                  labelText: 'İkramiye Bedeli (örn. 40 adet çeyrek altın)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.transparent,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            SizedBox(height: 16),

            // İkramiye Cinsi
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[100],
              ),
              child: TextFormField(
                controller: _ikramiyeCinsiCtrl,
                decoration: InputDecoration(
                  labelText: 'İkramiye Cinsi',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.transparent,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            SizedBox(height: 24),

            // Kaydet Butonu
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  if (_kampanyaFormKey.currentState!.validate()) {
                    setState(() => _loading = true);

                    try {
                      final user = supabase.auth.currentUser!;
                      final userId = user.id;

                      // 1) Kullanıcıyı users tablosuna ekle
                      try {
                        await supabase
                            .from('users')
                            .insert({'id': user.id, 'email': user.email});
                      } catch (e) {
                        // Kullanıcı zaten varsa hata verme
                        print('Kullanıcı zaten mevcut: $e');
                      }

                      // 2) Kampanya (draw) kaydı
                      final drawRes = await supabase
                          .from('draws')
                          .insert({
                            'name': _kampanyaIsimCtrl.text.trim(),
                            'last_number_count': _sonNumaraAdeti,
                            'chance_count': _sansAdeti,
                            'min_number': _birNumaraAlti,
                            'max_number': _birNumaraUstu,
                            'draw_date': _cekilisTarihiCtrl.text,
                            'ticket_price':
                                double.tryParse(_biletFiyatiCtrl.text) ?? 0.0,
                            'ticket_count':
                                int.tryParse(_biletAdetiCtrl.text) ?? 0,
                            'prize_amount':
                                double.tryParse(_ikramiyeBedeliCtrl.text) ??
                                    0.0,
                            'prize_unit': _ikramiyeCinsiCtrl.text,
                            'user_id': userId,
                          })
                          .select()
                          .single();

                      // 2) Biletleri oluştur
                      final draw = drawRes;
                      final count = draw['ticket_count'] as int;
                      final minNum = _birNumaraAlti;

                      if (count <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Bilet adeti 0\'dan büyük olmalı!'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        setState(() => _loading = false);
                        return;
                      }

                      final tickets = List.generate(count, (i) {
                        final numStr = (minNum + i).toString().padLeft(3, '0');
                        return {
                          'draw_id': draw['id'],
                          'user_id': userId,
                          'number': numStr,
                          'status': 'available',
                          'ticket_price':
                              double.tryParse(_biletFiyatiCtrl.text) ?? 0.0,
                          'created_at': DateTime.now().toIso8601String(),
                        };
                      });

                      final ticketRes =
                          await supabase.from('tickets').insert(tickets);

                      // 3) Başarı
                      print('✅ Başarıyla eklendi: ${tickets.length} bilet');

                      // Formu temizle
                      _kampanyaFormKey.currentState!.reset();
                      _kampanyaIsimCtrl.clear();
                      _cekilisTarihiCtrl.clear();
                      _biletFiyatiCtrl.clear();
                      _biletAdetiCtrl.clear();
                      _ikramiyeBedeliCtrl.clear();
                      _ikramiyeCinsiCtrl.clear();

                      // İstatistikleri yenile
                      await _loadStats();

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Kampanya ve biletler başarıyla oluşturuldu! ${tickets.length} bilet eklendi.'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      print('Kampanya oluşturma hatası: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Hata: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    } finally {
                      setState(() => _loading = false);
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: Text('Kampanyayı Kaydet',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBorclular() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Borçlu Olanlar',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: borcluBiletler.length,
            itemBuilder: (context, index) {
              final bilet = borcluBiletler[index];
              return Card(
                child: ListTile(
                  title: Text('Bilet No: ${bilet['number']}'),
                  subtitle: Text('Sahip: ${bilet['user_id'] ?? 'Bilinmiyor'}'),
                  trailing: Text('Durum: ${bilet['status']}'),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBiletleriListele() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Tüm Biletler',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ElevatedButton.icon(
              onPressed: () async {
                setState(() => _loading = true);
                await _loadStats();
                setState(() => _loading = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Biletler yenilendi!')),
                );
              },
              icon: Icon(Icons.refresh),
              label: Text('Yenile'),
            ),
          ],
        ),
        SizedBox(height: 16),
        if (_loading)
          Center(child: CircularProgressIndicator())
        else
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _loadTicketsFromSupabase(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, size: 64, color: Colors.red),
                        SizedBox(height: 16),
                        Text('Hata: ${snapshot.error}'),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => setState(() {}),
                          child: Text('Tekrar Dene'),
                        ),
                      ],
                    ),
                  );
                }

                final tickets = snapshot.data ?? [];

                if (tickets.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('Henüz bilet yok.'),
                        SizedBox(height: 8),
                        Text('Kampanya oluşturarak bilet ekleyebilirsiniz.',
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: tickets.length,
                  itemBuilder: (context, index) {
                    final ticket = tickets[index];
                    final status = ticket['status'] ?? 'bilinmiyor';
                    final createdAt = ticket['created_at'] ?? '';

                    // Durum rengi
                    Color statusColor;
                    switch (status) {
                      case 'musaid':
                        statusColor = Colors.blue;
                        break;
                      case 'satildi':
                        statusColor = Colors.green;
                        break;
                      case 'ödenmedi':
                        statusColor = Colors.red;
                        break;
                      case 'iptal':
                        statusColor = Colors.grey;
                        break;
                      default:
                        statusColor = Colors.orange;
                    }

                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: statusColor,
                          child: Text(
                            ticket['number'] ?? '?',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(
                          'Bilet #${ticket['number'] ?? 'N/A'}',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Durum: $status'),
                            if (ticket['campaign_id'] != null)
                              Text('Kampanya ID: ${ticket['campaign_id']}'),
                            if (ticket['price'] != null)
                              Text('Fiyat: ${ticket['price']} TL'),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                status.toUpperCase(),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (createdAt.isNotEmpty)
                              Text(
                                createdAt.substring(
                                    0,
                                    createdAt.length > 19
                                        ? 19
                                        : createdAt.length),
                                style:
                                    TextStyle(fontSize: 10, color: Colors.grey),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  // Supabase'den biletleri yükle
  Future<List<Map<String, dynamic>>> _loadTicketsFromSupabase() async {
    try {
      print('🔄 Biletler Supabase\'den yükleniyor...');

      final response = await supabase
          .from('tickets')
          .select(
              'id, number, status, user_id, campaign_id, price, created_at, published')
          .order('created_at', ascending: false);

      final tickets = List<Map<String, dynamic>>.from(response);
      print('✅ ${tickets.length} bilet yüklendi');

      return tickets;
    } catch (e) {
      print('❌ Bilet yükleme hatası: $e');
      rethrow;
    }
  }

  Widget _buildUyeler() {
    return Center(child: Text('Üyeler sayfası (örnek)'));
    // Burada Supabase’den üyeleri çekip listeleyebilirsin
  }

  Widget _buildGecmisCekilisler() {
    return Center(child: Text('Geçmiş Çekilişler sayfası (örnek)'));
    // Burada Supabase’den geçmiş çekilişleri çekip listeleyebilirsin
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Paneli'),
        automaticallyImplyLeading: false, // hamburger'ı gizle
        actions: [
          IconButton(
            onPressed: () => navigateWithFade(context, DrawResultPage()),
            icon: Icon(Icons.emoji_events),
            tooltip: 'Çekiliş Sonucu',
          ),
          IconButton(
            onPressed: () async {
              await supabase.auth.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
            icon: Icon(Icons.logout),
          )
        ],
      ),
      body: Row(
        children: [
          // Sabit açık sidebar
          SizedBox(
            width: 250,
            child: Drawer(
              elevation: 0,
              child: _buildDrawer(),
            ),
          ),
          // İçerik kısmı
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Builder(
                builder: (context) {
                  switch (_selectedMenu) {
                    case AdminMenu.genel:
                      return _buildGenelBilgi();
                    case AdminMenu.kampanya:
                      return _buildKampanyaOlustur();
                    case AdminMenu.borclular:
                      return _buildBorclular();
                    case AdminMenu.biletler:
                      return _buildBiletleriListele();
                    case AdminMenu.uyeler:
                      return _buildUyeler();
                    case AdminMenu.gecmis:
                      return _buildGecmisCekilisler();
                    case AdminMenu.tema:
                      return Container(); // Tema değiştir için ayrı bir sayfa yok, switch menüde
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
