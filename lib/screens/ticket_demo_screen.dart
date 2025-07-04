import 'package:flutter/material.dart';
import '../models/ticket.dart';
import '../widgets/ticket_design_widget.dart';

class TicketDemoScreen extends StatelessWidget {
  const TicketDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Demo biletler oluştur
    final List<Ticket> demoTickets = [
      Ticket(
        id: '001234',
        campaignId: 'YB2024',
        numbers: ['42', '17', '89', '03', '71', '55'],
        price: 100.0,
        status: TicketStatus.available,
        createdAt: DateTime.now(),
        drawDate: DateTime.now().add(const Duration(days: 7)),
      ),
      Ticket(
        id: '001235',
        campaignId: 'YB2024',
        numbers: ['12', '34', '56', '78', '90', '11'],
        price: 100.0,
        status: TicketStatus.sold,
        buyerName: 'Ahmet Yılmaz',
        buyerPhone: '0555 123 4567',
        soldAt: DateTime.now().subtract(const Duration(hours: 2)),
        createdAt: DateTime.now(),
        drawDate: DateTime.now().add(const Duration(days: 7)),
      ),
      Ticket(
        id: '001236',
        campaignId: 'YB2024',
        numbers: ['07', '14', '21', '35', '49', '63'],
        price: 100.0,
        status: TicketStatus.paid,
        buyerName: 'Ayşe Demir',
        buyerPhone: '0555 987 6543',
        soldAt: DateTime.now().subtract(const Duration(hours: 5)),
        paidAt: DateTime.now().subtract(const Duration(hours: 4)),
        createdAt: DateTime.now(),
        drawDate: DateTime.now().add(const Duration(days: 7)),
      ),
      Ticket(
        id: '001237',
        campaignId: 'YB2024',
        numbers: ['77', '88', '99', '11', '22', '33'],
        price: 100.0,
        status: TicketStatus.winner,
        buyerName: 'Mehmet Öz',
        buyerPhone: '0555 111 2222',
        soldAt: DateTime.now().subtract(const Duration(days: 30)),
        paidAt: DateTime.now().subtract(const Duration(days: 30)),
        createdAt: DateTime.now().subtract(const Duration(days: 31)),
        isWinner: true,
        winnerType: 'main',
        winAmount: 10000000.0,
        drawDate: DateTime.now().subtract(const Duration(days: 1)),
      ),
      Ticket(
        id: '001238',
        campaignId: 'YB2024',
        numbers: ['13', '26', '39', '52', '65', '78'],
        price: 100.0,
        status: TicketStatus.unpaid,
        buyerName: 'Fatma Kaya',
        buyerPhone: '0555 333 4444',
        soldAt: DateTime.now().subtract(const Duration(hours: 1)),
        createdAt: DateTime.now(),
        drawDate: DateTime.now().add(const Duration(hours: 2)),
      ),
      Ticket(
        id: '001239',
        campaignId: 'YB2024',
        numbers: ['01', '02', '03', '04', '05', '06'],
        price: 100.0,
        status: TicketStatus.cancelled,
        buyerName: 'Can Yıldız',
        buyerPhone: '0555 555 6666',
        soldAt: DateTime.now().subtract(const Duration(days: 2)),
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        drawDate: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Piyango Bileti Tasarımları'),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.confirmation_number,
                    size: 50,
                    color: Colors.white,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Modern Bilet Tasarımları',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Farklı durumlar için bilet örnekleri',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: demoTickets.length,
                itemBuilder: (context, index) {
                  final ticket = demoTickets[index];
                  return Column(
                    children: [
                      // Durum başlığı
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Color(ticket.statusColor).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    ticket.statusEmoji,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    ticket.statusText,
                                    style: TextStyle(
                                      color: Color(ticket.statusColor),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (ticket.buyerName != null) ...[
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  '${ticket.buyerName}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      // Bilet widget'ı
                      TicketDesignWidget(
                        ticket: ticket,
                        onTap: () {
                          _showTicketDetails(context, ticket);
                        },
                      ),
                      const SizedBox(height: 20),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTicketDetails(BuildContext context, Ticket ticket) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Bilet Detayları',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              TicketDesignWidget(
                ticket: ticket,
                isInteractive: false,
              ),
              const SizedBox(height: 20),
              if (ticket.isWinner) ...[
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.amber, width: 2),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.emoji_events,
                        color: Colors.amber,
                        size: 40,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'TEBRİKLER!',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber[800],
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Kazanılan Tutar: ₺${ticket.winAmount?.toStringAsFixed(2) ?? "0.00"}',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.amber[700],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Kapat'),
                  ),
                  if (ticket.status == TicketStatus.available)
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Bilet satın alma işlemi başlatıldı!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      child: const Text('Satın Al'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
} 