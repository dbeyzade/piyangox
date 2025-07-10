import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class ShareRow extends StatelessWidget {
  final String? customMessage;
  final String? customUrl;

  const ShareRow({this.customMessage, this.customUrl, super.key});

  @override
  Widget build(BuildContext context) {
    final message = customMessage ??
        '🎫 PiyangoX - Gerçek zamanlı bilet yönetim sistemi!\n\nKazanma şansınızı artırın ve anlık çekiliş sonuçlarını takip edin.\n\n📱 Hemen katılın!';
    final url = customUrl ?? 'https://piyangox.com';

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(
            'Sosyal Medyada Paylaş',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(Icons.facebook, color: Colors.blue, size: 32),
                onPressed: () {
                  Share.share('$message\n\n$url',
                      subject: 'PiyangoX - Kazanma zamanı!');
                },
                tooltip: 'Facebook\'ta Paylaş',
              ),
              IconButton(
                icon: const Icon(Icons.chat, color: Colors.green, size: 32),
                onPressed: () {
                  Share.share('$message\n\n$url',
                      subject: 'PiyangoX - WhatsApp Paylaşımı');
                },
                tooltip: 'WhatsApp\'ta Paylaş',
              ),
              IconButton(
                icon: const Icon(Icons.send, color: Colors.lightBlue, size: 32),
                onPressed: () {
                  Share.share('$message\n\n$url',
                      subject: 'PiyangoX - Telegram Paylaşımı');
                },
                tooltip: 'Telegram\'da Paylaş',
              ),
              IconButton(
                icon: const Icon(Icons.share, color: Colors.orange, size: 32),
                onPressed: () {
                  Share.share('$message\n\n$url',
                      subject: 'PiyangoX - Genel Paylaşım');
                },
                tooltip: 'Genel Paylaşım',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
