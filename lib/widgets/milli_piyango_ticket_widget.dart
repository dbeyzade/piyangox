import 'package:flutter/material.dart';
import '../models/ticket.dart';

class MilliPiyangoTicketWidget extends StatelessWidget {
  final Ticket ticket;
  final String campaignName;
  final String grandPrize;
  final String upperLowerPrize;
  final VoidCallback? onTap;

  const MilliPiyangoTicketWidget({
    super.key,
    required this.ticket,
    this.campaignName = 'NAZ',
    this.grandPrize = '280.000',
    this.upperLowerPrize = '10.000',
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 450,
        height: 250,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(3, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              // Üst kısım - Bilet fiyatı, NAZ ve Çekiliş tarihi
              SizedBox(
                height: 70,
                child: Row(
                  children: [
                    // Bilet fiyatı
                    Container(
                      width: 120,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.black, width: 2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'BİLET FİYATI',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            ticket.price.toStringAsFixed(0),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // NAZ kampanya adı
                    Expanded(
                      child: Container(
                        height: 70,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE53935), // Gerçek kırmızı
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            campaignName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 8,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Çekiliş tarihi
                    Container(
                      width: 130,
                      height: 70,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.black, width: 2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'ÇEKİLİŞ TARİHİ',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          if (ticket.drawDate != null)
                            Text(
                              '${ticket.drawDate!.day} ${_getMonthName(ticket.drawDate!.month)} ${ticket.drawDate!.year}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              // Alt kısım - İkramiye ve numaralar
              Expanded(
                child: Row(
                  children: [
                    // Sol taraf - İkramiye
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'ikramiye',
                            style: TextStyle(
                              fontSize: 26,
                              fontStyle: FontStyle.italic,
                              color: Color(0xFFE53935),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            grandPrize,
                            style: const TextStyle(
                              fontSize: 56,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1976D2), // Gerçek mavi
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Sarı-siyah çizgili bant
                          SizedBox(
                            width: 280,
                            height: 20,
                            child: CustomPaint(
                              painter: HazardStripePainter(),
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Alt ve üst numara ödülleri
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Column(
                                children: [
                                  const Text(
                                    'Bir Alt Numaralı Bilete',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE53935),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      upperLowerPrize,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 20),
                              Column(
                                children: [
                                  const Text(
                                    'Bir Üst Numaralı Bilete',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE53935),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      upperLowerPrize,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 15),
                    // Sağ taraf - Bilet numaraları
                    Container(
                      width: 110,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // İlk 3 numara
                          Container(
                            width: 80,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.black, width: 2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                ticket.numbers.isNotEmpty ? 
                                  '${ticket.numbers[0]}${ticket.numbers.length > 1 ? ticket.numbers[1] : ""}${ticket.numbers.length > 2 ? ticket.numbers[2] : ""}' : 
                                  '487',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),
                          // Son 3 numara
                          Container(
                            width: 80,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.black, width: 2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                ticket.numbers.length > 3 ? 
                                  '${ticket.numbers[3]}${ticket.numbers.length > 4 ? ticket.numbers[4] : ""}${ticket.numbers.length > 5 ? ticket.numbers[5] : ""}' : 
                                  '762',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
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
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'OCAK', 'ŞUBAT', 'MART', 'NİSAN', 'MAYIS', 'HAZİRAN',
      'TEMMUZ', 'AĞUSTOS', 'EYLÜL', 'EKİM', 'KASIM', 'ARALIK'
    ];
    return months[month - 1];
  }
}

// Sarı-siyah çizgili tehlike bandı çizer
class HazardStripePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    const stripeWidth = 15.0;
    
    for (double x = 0; x < size.width; x += stripeWidth * 2) {
      // Sarı çizgi
      paint.color = Colors.amber;
      canvas.drawRect(
        Rect.fromLTWH(x, 0, stripeWidth, size.height),
        paint,
      );
      
      // Siyah çizgi
      paint.color = Colors.black;
      canvas.drawRect(
        Rect.fromLTWH(x + stripeWidth, 0, stripeWidth, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 