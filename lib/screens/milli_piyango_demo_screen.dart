import 'package:flutter/material.dart';
import '../models/ticket.dart';
import '../widgets/milli_piyango_ticket_widget.dart';

class MilliPiyangoDemoScreen extends StatelessWidget {
  const MilliPiyangoDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Demo bilet oluştur
    final demoTicket = Ticket(
      id: '001234',
      campaignId: 'YB2025',
      numbers: ['4', '8', '7', '7', '6', '2'], // 487762 olarak gösterilecek
      price: 1000.0,
      status: TicketStatus.available,
      createdAt: DateTime.now(),
      drawDate: DateTime(2025, 7, 9), // 9 Temmuz 2025
    );

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('Milli Piyango Bileti'),
        backgroundColor: Colors.red,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Başlık
              Container(
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.only(bottom: 30),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.stars,
                      size: 50,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'MİLLİ PİYANGO',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Gerçek Bilet Tasarımı',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Bilet
              MilliPiyangoTicketWidget(
                ticket: demoTicket,
                campaignName: 'NAZ',
                grandPrize: '280.000',
                upperLowerPrize: '10.000',
                onTap: () {
                  _showTicketDetails(context, demoTicket);
                },
              ),
              
              const SizedBox(height: 30),
              
              // Bilgi kartları
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildInfoCard(
                    icon: Icons.monetization_on,
                    title: 'Bilet Fiyatı',
                    value: '₺1.000',
                    color: Colors.green,
                  ),
                  _buildInfoCard(
                    icon: Icons.emoji_events,
                    title: 'Büyük İkramiye',
                    value: '₺280.000',
                    color: Colors.amber,
                  ),
                  _buildInfoCard(
                    icon: Icons.calendar_today,
                    title: 'Çekiliş',
                    value: '9 Temmuz',
                    color: Colors.blue,
                  ),
                ],
              ),
              
              const SizedBox(height: 30),
              
              // Açıklama
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📌 Bilet Özellikleri',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),
                    _buildFeatureRow('✅ Gerçek Milli Piyango bilet tasarımı'),
                    _buildFeatureRow('✅ Kampanya adı ve çekiliş tarihi'),
                    _buildFeatureRow('✅ 6 haneli şans numarası'),
                    _buildFeatureRow('✅ Büyük ikramiye tutarı'),
                    _buildFeatureRow('✅ Alt ve üst numara ödülleri'),
                    _buildFeatureRow('✅ Perforasyon (delikli) kenar detayı'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 5),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Text(
        text,
        style: const TextStyle(fontSize: 16),
      ),
    );
  }

  void _showTicketDetails(BuildContext context, Ticket ticket) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bilet Detayları'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bilet No: ${ticket.id}'),
            Text('Şans Numarası: ${ticket.numbers.join("")}'),
            const Text('Kampanya: NAZ'),
            Text('Fiyat: ₺${ticket.price.toStringAsFixed(0)}'),
            Text('Durum: ${ticket.statusText}'),
            if (ticket.drawDate != null)
              Text('Çekiliş: ${ticket.drawDateFormatted}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }
} 