import 'package:flutter/material.dart';
import '../models/ticket_model.dart';
import 'countdown_timer.dart';

class TicketCard extends StatelessWidget {
  final Ticket ticket;
  final VoidCallback? onBuyPressed;
  final VoidCallback? onStatusChanged;
  final bool isAdmin;

  const TicketCard(
      {required this.ticket,
      this.onBuyPressed,
      this.onStatusChanged,
      this.isAdmin = false,
      super.key});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    switch (ticket.status) {
      case 'satildi':
        bgColor = Colors.green;
        break;
      case 'ödenmedi':
        bgColor = Colors.red;
        break;
      case 'iptal':
        bgColor = Colors.black;
        break;
      default:
        bgColor = Colors.grey;
    }

    return Card(
      color: bgColor,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text('Bilet: ${ticket.number}',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text('Durum: ${ticket.status}',
            style: const TextStyle(color: Colors.white70)),
        leading: ticket.isWinner
            ? const Icon(Icons.star, color: Colors.amber)
            : null,
        trailing: ticket.status == 'ödenmedi'
            ? CountdownTimer(
                deadline: ticket.drawDate.subtract(const Duration(hours: 1)))
            : ticket.status == 'musaid' && onBuyPressed != null
                ? ElevatedButton(
                    onPressed: onBuyPressed,
                    child: const Text('Satın Al'),
                  )
                : isAdmin
                    ? PopupMenuButton<String>(
                        icon: const Icon(Icons.edit, color: Colors.white),
                        onSelected: (val) {
                          if (onStatusChanged != null) {
                            onStatusChanged!();
                          }
                        },
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(
                              child: Text('Müsait'), value: 'musaid'),
                          const PopupMenuItem(
                              child: Text('Satıldı'), value: 'satildi'),
                          const PopupMenuItem(
                              child: Text('Ödenmedi'), value: 'ödenmedi'),
                          const PopupMenuItem(
                              child: Text('İptal'), value: 'iptal'),
                        ],
                      )
                    : const SizedBox.shrink(),
      ),
    );
  }
}
