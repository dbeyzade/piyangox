import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/ticket.dart';

class TicketDesignWidget extends StatefulWidget {
  final Ticket ticket;
  final VoidCallback? onTap;
  final bool showDetails;
  final bool isInteractive;

  const TicketDesignWidget({
    super.key,
    required this.ticket,
    this.onTap,
    this.showDetails = true,
    this.isInteractive = true,
  });

  @override
  State<TicketDesignWidget> createState() => _TicketDesignWidgetState();
}

class _TicketDesignWidgetState extends State<TicketDesignWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _rotateAnimation = Tween<double>(
      begin: 0.0,
      end: 0.02,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        if (widget.isInteractive) {
          setState(() => _isHovered = true);
          _animationController.forward();
        }
      },
      onExit: (_) {
        if (widget.isInteractive) {
          setState(() => _isHovered = false);
          _animationController.reverse();
        }
      },
      child: GestureDetector(
        onTap: widget.isInteractive ? () {
          HapticFeedback.lightImpact();
          widget.onTap?.call();
        } : null,
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.rotate(
              angle: _rotateAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  margin: const EdgeInsets.all(8),
                  child: Stack(
                    children: [
                      // Ana bilet gövdesi
                      _buildTicketBody(),
                      // Kazandı bandı (eğer kazanmışsa)
                      if (widget.ticket.isWinner) _buildWinnerBanner(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTicketBody() {
    return Container(
      width: 350,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_isHovered ? 0.3 : 0.2),
            blurRadius: _isHovered ? 20 : 10,
            offset: Offset(0, _isHovered ? 10 : 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Arka plan gradyanı
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _getGradientColors(),
                ),
              ),
            ),
            // Desenli arka plan
            CustomPaint(
              painter: TicketPatternPainter(
                color: Colors.white.withOpacity(0.1),
              ),
              size: const Size(350, 200),
            ),
            // İçerik
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Üst kısım - Logo ve başlık
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.star_rounded,
                            color: Colors.white,
                            size: 30,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'MİLLİ PİYANGO',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                      // Durum göstergesi
                      _buildStatusIndicator(),
                    ],
                  ),
                  const Spacer(),
                  // Şans numaraları
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: widget.ticket.numbers.map((number) {
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 45,
                          height: 45,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 5,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              number,
                              style: TextStyle(
                                color: _getNumberColor(),
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const Spacer(),
                  // Alt kısım - Bilet detayları
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bilet No: ${widget.ticket.id}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 10,
                            ),
                          ),
                          if (widget.ticket.drawDate != null)
                            Text(
                              'Çekiliş: ${widget.ticket.drawDateFormatted}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 10,
                              ),
                            ),
                        ],
                      ),
                      Text(
                        '₺${widget.ticket.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Perforasyon efekti
            Positioned(
              left: -10,
              top: 0,
              bottom: 0,
              child: _buildPerforation(),
            ),
            Positioned(
              right: -10,
              top: 0,
              bottom: 0,
              child: _buildPerforation(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator() {
    IconData icon;
    Color color;
    
    switch (widget.ticket.status) {
      case 'available':
        icon = Icons.confirmation_number;
        color = Colors.grey.shade300;
        break;
      case 'sold':
        icon = Icons.shopping_cart;
        color = Colors.yellow;
        break;
      case 'unpaid':
        icon = Icons.access_time;
        color = Colors.orange;
        break;
      case 'paid':
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case 'cancelled':
        icon = Icons.cancel;
        color = Colors.red;
        break;
      case 'winner':
        icon = Icons.emoji_events;
        color = Colors.amber;
        break;
      default:
        icon = Icons.help;
        color = Colors.grey.shade300;
        break;
    }
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 2),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _buildWinnerBanner() {
    return Positioned(
      top: 20,
      right: -30,
      child: Transform.rotate(
        angle: 0.785398, // 45 derece
        child: Container(
          width: 120,
          padding: const EdgeInsets.symmetric(vertical: 6),
          color: Colors.amber,
          child: const Center(
            child: Text(
              'KAZANDI!',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPerforation() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(
        10,
        (index) => Container(
          width: 20,
          height: 20,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  List<Color> _getGradientColors() {
    switch (widget.ticket.status) {
      case 'available':
        return [Colors.grey.shade600, Colors.grey.shade800];
      case 'sold':
        return [Colors.orange.shade600, Colors.orange.shade800];
      case 'unpaid':
        return [Colors.deepOrange.shade600, Colors.deepOrange.shade800];
      case 'paid':
        return [Colors.green.shade600, Colors.green.shade800];
      case 'cancelled':
        return [Colors.red.shade600, Colors.red.shade800];
      case 'winner':
        return [Colors.amber.shade600, Colors.amber.shade800];
      default:
        return [Colors.grey.shade600, Colors.grey.shade800];
    }
  }

  Color _getNumberColor() {
    switch (widget.ticket.status) {
      case 'available':
        return Colors.grey.shade700;
      case 'sold':
        return Colors.orange.shade700;
      case 'unpaid':
        return Colors.deepOrange.shade700;
      case 'paid':
        return Colors.green.shade700;
      case 'cancelled':
        return Colors.red.shade700;
      case 'winner':
        return Colors.amber.shade700;
      default:
        return Colors.grey.shade700;
    }
  }
}

// Bilet üzerindeki desen için özel painter
class TicketPatternPainter extends CustomPainter {
  final Color color;

  TicketPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Yatay çizgiler
    for (double y = 0; y < size.height; y += 20) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }

    // Dikey çizgiler
    for (double x = 0; x < size.width; x += 20) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // Köşegen desenler
    final diagonalPaint = Paint()
      ..color = color.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    for (double i = 0; i < size.width + size.height; i += 40) {
      canvas.drawCircle(
        Offset(i, 0),
        3,
        diagonalPaint,
      );
      canvas.drawCircle(
        Offset(0, i),
        3,
        diagonalPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
print(undefinedVariable);
