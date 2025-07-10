import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../widgets/ticket_card.dart';
import '../../widgets/share_row.dart';
import '../../models/ticket_model.dart';

class AdminTabDashboard extends StatefulWidget {
  @override
  State<AdminTabDashboard> createState() => _AdminTabDashboardState();
}

class _AdminTabDashboardState extends State<AdminTabDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tc;
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> tickets = [];
  DateTime? drawTime;

  @override
  void initState() {
    super.initState();
    _tc = TabController(length: 4, vsync: this);
    _tc.addListener(() {
      if (_tc.index == 1) {
        // Borçlu sekmesi
        _checkExpiredUnpaid();
      }
    });
    _loadAll();
    _loadDrawTime();
    _scheduleAutoCancel();
  }

  Future<void> _loadAll() async {
    final resp = await supabase.from('tickets').select('*, draw_date');
    setState(() => tickets = List<Map<String, dynamic>>.from(resp));
    _checkExpiredUnpaid();
  }

  void _checkExpiredUnpaid() {
    final now = DateTime.now();
    for (var t in tickets.where((t) => t['status'] == 'ödenmedi')) {
      if (t['draw_date'] != null) {
        final deadline =
            DateTime.parse(t['draw_date']).subtract(Duration(hours: 1));
        if (deadline.isBefore(now)) {
          showDialog(
              context: context,
              builder: (_) => AlertDialog(
                    title: Text('Ödemeniz Gecikti'),
                    content:
                        Text('Bilet ${t['number']} için ödeme süresi doldu.'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Tamam'))
                    ],
                  ));
        }
      }
    }
  }

  Future<void> _loadDrawTime() async {
    final resp = await supabase
        .from('draws')
        .select('draw_date')
        .order('draw_date', ascending: false)
        .limit(1);
    if (resp.isNotEmpty) {
      final d = DateTime.parse(resp.first['draw_date']);
      setState(() => drawTime = d);
    }
  }

  void _scheduleAutoCancel() {
    // 10 dakika aralıklı kontrol
    Future.doWhile(() async {
      await Future.delayed(Duration(minutes: 10));
      final now = DateTime.now();

      // Ödenmemiş biletleri kontrol et
      for (var ticket in tickets.where((t) => t['status'] == 'ödenmedi')) {
        if (ticket['draw_date'] != null) {
          final deadline =
              DateTime.parse(ticket['draw_date']).subtract(Duration(hours: 1));
          if (deadline.isBefore(now)) {
            _cancelUnpaid();
            break;
          }
        }
      }
      return true;
    });
  }

  Future<void> _cancelUnpaid() async {
    await supabase.from('tickets').update(
        {'status': 'iptal', 'published': false}).eq('status', 'ödenmedi');
    _notifyUsers();
    _loadAll();
  }

  Future<void> _notifyUsers() async {
    // Basit dialog: burada push notification da entegre edilebilir
    showDialog(
        context: context,
        builder: (_) {
          return AlertDialog(
            title: Text('Bilet İptalleri'),
            content: Text(
                'Çekiliş saatine 1 saat kala ödenmeyen biletlere iptal geldi.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context), child: Text('Tamam'))
            ],
          );
        });
  }

  Widget _buildTicketCard(Map<String, dynamic> ticketData) {
    final ticket = Ticket.fromMap(ticketData);
    return TicketCard(
      ticket: ticket,
      isAdmin: true,
      onStatusChanged: () => _updateTicketStatus(ticket.id, ticket.status),
    );
  }

  Future<void> _updateTicketStatus(String id, String status) async {
    await supabase.from('tickets').update({
      'status': status,
      'published': status == 'musaid',
    }).eq('id', id);
    _loadAll();
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
      _loadAll();
    }
  }

  @override
  Widget build(BuildContext ctx) {
    return Scaffold(
      appBar: AppBar(
          title: Text('Admin Panel'),
          bottom: TabBar(controller: _tc, tabs: [
            Tab(text: 'Tümü'),
            Tab(text: 'Borçlu'),
            Tab(text: 'Satıldı'),
            Tab(text: 'İptal'),
          ])),
      body: Column(
        children: [
          ShareRow(),
          Expanded(
            child: TabBarView(controller: _tc, children: [
              _listByStatus(null),
              _listByStatus('ödenmedi'),
              _listByStatus('satildi'),
              _listByStatus('iptal'),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _listByStatus(String? status) {
    final list = status == null
        ? tickets
        : tickets.where((t) => t['status'] == status).toList();
    if (list.isEmpty) return Center(child: Text('Liste boş'));
    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView.builder(
          itemCount: list.length,
          itemBuilder: (_, i) => _buildTicketCard(list[i])),
    );
  }

  @override
  void dispose() {
    _tc.dispose();
    super.dispose();
  }
}
