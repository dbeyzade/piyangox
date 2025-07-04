import 'package:flutter/material.dart';

class DoveBackground extends StatelessWidget {
  final Widget child;
  
  const DoveBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Arka plan deseni
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.purple.shade100,
                Colors.purple.shade50,
              ],
            ),
          ),
        ),
        // Güvercin desenleri
        Positioned.fill(
          child: CustomPaint(
            painter: DovePatternPainter(),
          ),
        ),
        // İçerik
        child,
      ],
    );
  }
}

class DovePatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.purple.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    // Basit daire desenleri - güvercin yerine
    for (double x = 0; x < size.width; x += 100) {
      for (double y = 0; y < size.height; y += 100) {
        canvas.drawCircle(
          Offset(x + 50, y + 50),
          30,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 