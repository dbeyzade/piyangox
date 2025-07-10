import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:confetti/confetti.dart';

class DrawResultPage extends StatefulWidget {
  @override
  State<DrawResultPage> createState() => _DrawResultPageState();
}

class _DrawResultPageState extends State<DrawResultPage> {
  final supabase = Supabase.instance.client;
  late final ConfettiController _confettiController;
  String? winningNumber;
  List<Map<String, dynamic>> winners = [];

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: Duration(seconds: 4));
    _loadWinningNumber();
  }

  Future<void> _loadWinningNumber() async {
    final drawResp = await supabase
        .from('draws')
        .select('winning_number')
        .order('created_at', ascending: false)
        .limit(1);
    if (drawResp.isNotEmpty) {
      setState(() {
        winningNumber = drawResp.first['winning_number'];
      });
      _loadWinners();
    }
  }

  Future<void> _loadWinners() async {
    final ticketResp = await supabase
        .from('tickets')
        .select('*, draw_date')
        .eq('is_winner', true);

    setState(() {
      winners = List<Map<String, dynamic>>.from(ticketResp);
    });

    if (winners.isNotEmpty) {
      _confettiController.play();
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Çekiliş Sonucu')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (winningNumber != null)
              Text(
                '🎉 Büyük İkramiye Numarası: $winningNumber',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber),
              ),
            const SizedBox(height: 20),
            if (winners.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: winners.length,
                  itemBuilder: (context, index) {
                    final ticket = winners[index];
                    return Card(
                      child: ListTile(
                        title: Text('Kazanan Bilet No: ${ticket['number']}'),
                        subtitle: Text(
                            'Kullanıcı: ${ticket['user_id'] ?? 'Tanımsız'}'),
                      ),
                    );
                  },
                ),
              )
            else
              Text('Henüz kazanan bilet bulunamadı.'),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
