import 'package:flutter/material.dart';

// Fade animasyonu ile sayfa geçişi
void navigateWithFade(BuildContext context, Widget page) {
  Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: Duration(milliseconds: 300),
      ));
}

// Slide animasyonu ile sayfa geçişi (sağdan)
void navigateWithSlide(BuildContext context, Widget page) {
  Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, animation, __, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          return SlideTransition(position: offsetAnimation, child: child);
        },
        transitionDuration: Duration(milliseconds: 300),
      ));
}

// Scale animasyonu ile sayfa geçişi
void navigateWithScale(BuildContext context, Widget page) {
  Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, animation, __, child) {
          return ScaleTransition(
            scale: Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeInOut),
            ),
            child: child,
          );
        },
        transitionDuration: Duration(milliseconds: 300),
      ));
}

// Responsive animasyon seçici
void navigateWithResponsiveAnimation(BuildContext context, Widget page) {
  final screenWidth = MediaQuery.of(context).size.width;

  if (screenWidth > 600) {
    // Tablet/Desktop için fade animasyonu
    navigateWithFade(context, page);
  } else {
    // Mobil için slide animasyonu
    navigateWithSlide(context, page);
  }
}
