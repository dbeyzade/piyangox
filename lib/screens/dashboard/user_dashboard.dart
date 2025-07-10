import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/navigation.dart';
import '../../widgets/countdown_timer.dart';
import '../../widgets/ticket_card.dart';
import '../../widgets/share_row.dart';
import '../../models/ticket_model.dart';
import 'draw_result_page.dart';
import '../login_screen.dart';

class UserDashboard extends StatefulWidget {
  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  final supabase = Supabase.instance.client;
  late final RealtimeChannel _channel;
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> tickets = [];
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _loadTickets();
    _subscribeToTickets();
  }

  void _subscribeToTickets() {
    _channel = supabase
        .channel('public:tickets')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'tickets',
          callback: (payload, [ref]) {
            _loadTickets();
          },
        )
        .subscribe();
  }

  Future<void> _loadTickets() async {
    final response = await supabase
        .from('tickets')
        .select('*')
        .eq('published', true)
        .eq('status', 'musaid');

    setState(() {
      tickets = List<Map<String, dynamic>>.from(response);
    });
  }

  Future<void> _buyTicket(String ticketId) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await supabase.from('tickets').update({
        'status': 'satildi',
        'user_id': userId,
        'published': false,
      }).eq('id', ticketId);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bilet başarıyla satın alındı!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    supabase.removeChannel(_channel);
    super.dispose();
  }

  Widget _buildTicketItem(Map<String, dynamic> ticketData) {
    final ticket = Ticket.fromMap(ticketData);
    return TicketCard(
      ticket: ticket,
      onBuyPressed:
          ticket.status == 'musaid' ? () => _buyTicket(ticket.id) : null,
    );
  }

  Widget _buildTicketList() {
    final filteredTickets = tickets.where((ticket) {
      final number = ticket['number'].toString();
      return number.contains(_searchText);
    }).toList();

    if (filteredTickets.isEmpty) {
      return Center(
        child: Text(
          _searchText.isEmpty
              ? 'Bilet bulunamadı.'
              : 'Arama sonucu bulunamadı.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Expanded(
      child: ListView.builder(
        itemCount: filteredTickets.length,
        itemBuilder: (context, index) {
          return _buildTicketItem(filteredTickets[index]);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bilet Listesi'),
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/draw'),
            icon: Icon(Icons.emoji_events),
            tooltip: 'Çekiliş Sonucu',
          ),
          IconButton(
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (ctx) => LoginScreen()),
                );
              }
            },
            icon: Icon(Icons.logout),
          )
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Padding(
            padding: EdgeInsets.all(constraints.maxWidth > 600 ? 24.0 : 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Yayınlanan Biletler',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Bilet Ara',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Color(0xFF1E1E1E),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchText = value.trim();
                    });
                  },
                ),
                SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    print('🚨 Butona basıldı');
                    // Burada login fonksiyonu yok, dashboard işlemi yapılabilir.
                  },
                  child: Text('Giriş Yap'),
                ),
                const SizedBox(height: 16),
                ShareRow(),
                const SizedBox(height: 16),
                if (_searchText.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text(
                      '${tickets.where((ticket) => ticket['number'].toString().contains(_searchText)).length} sonuç bulundu',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ),
                _buildTicketList(),
              ],
            ),
          );
        },
      ),
    );
  }
}
