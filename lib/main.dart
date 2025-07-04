import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:window_manager/window_manager.dart';
import 'package:piyangox/screens/login_screen.dart';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Desktop için window manager kurulumu
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    try {
      await windowManager.ensureInitialized();

      const windowOptions = WindowOptions(
        size: Size(1400, 900),
        minimumSize: Size(1200, 800),
        center: true,
        backgroundColor: Colors.transparent,
        skipTaskbar: false,
        titleBarStyle: TitleBarStyle.normal,
        title: 'PiyangoX - Piyango Yönetim Sistemi (Desktop)',
      );

      await windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.show();
        await windowManager.focus();
      });

      print('🖥️  Masaüstü modu aktif - ${Platform.operatingSystem}');
    } catch (e) {
      print('⚠️  Window manager hatası: $e');
    }
  }

  // Supabase başlatma
  try {
    await Supabase.initialize(
      url: 'https://botfwqkpqtcwsoghzdad.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJvdGZ3cWtwcXRjd3NvZ2h6ZGFkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTEwMzU5NDcsImV4cCI6MjA2NjYxMTk0N30.0r7XulXxuuFGaCpgBSpzujC_37t16S1NJZR8-vEW4y4',
    );
    print('✅ Supabase başlatıldı');
  } catch (e) {
    print('❌ Supabase hatası: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop =
        Platform.isWindows || Platform.isLinux || Platform.isMacOS;

    return MaterialApp(
      title: 'PiyangoX - Piyango Yönetim Sistemi',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: isDesktop
            ? VisualDensity.standard // Desktop için daha geniş spacing
            : VisualDensity.adaptivePlatformDensity,

        // Desktop için daha büyük font boyutları
        textTheme: isDesktop
            ? const TextTheme(
                displayLarge: TextStyle(fontSize: 28),
                displayMedium: TextStyle(fontSize: 24),
                displaySmall: TextStyle(fontSize: 20),
                headlineLarge: TextStyle(fontSize: 18),
                headlineMedium: TextStyle(fontSize: 16),
                titleLarge: TextStyle(fontSize: 16),
                bodyLarge: TextStyle(fontSize: 14),
                bodyMedium: TextStyle(fontSize: 13),
              )
            : null,

        // Desktop için daha büyük butonlar
        elevatedButtonTheme: isDesktop
            ? ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  minimumSize: const Size(120, 48),
                ),
              )
            : null,
      ),
      locale: const Locale('tr', 'TR'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('tr', 'TR'),
        Locale('en', 'US'),
      ],
      home: isDesktop
          ? const DesktopWrapper(child: LoginScreen())
          : const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// Desktop wrapper widget
class DesktopWrapper extends StatefulWidget {
  final Widget child;

  const DesktopWrapper({super.key, required this.child});

  @override
  State<DesktopWrapper> createState() => _DesktopWrapperState();
}

class _DesktopWrapperState extends State<DesktopWrapper> with WindowListener {
  @override
  void initState() {
    super.initState();
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      windowManager.addListener(this);
      windowManager
          .setPreventClose(false); // X butonuyla direkt kapanmasını sağla
    }
  }

  @override
  void dispose() {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      windowManager.removeListener(this);
    }
    super.dispose();
  }

  @override
  void onWindowClose() async {
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.exit_to_app, color: Colors.red),
            SizedBox(width: 8),
            Text('Uygulamayı Kapat'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('PiyangoX uygulamasını nasıl kapatmak istiyorsunuz?'),
            SizedBox(height: 16),
            Text(
              '💡 İpucu: Arka plana gönderirsaniz sistem tepsisinden tekrar açabilirsiniz.',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop('cancel'),
            child: const Text('İptal'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            onPressed: () => Navigator.of(context).pop('minimize'),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.minimize, size: 16),
                SizedBox(width: 4),
                Text('Arka Plana'),
              ],
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop('close'),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.close, size: 16),
                SizedBox(width: 4),
                Text('Kapat'),
              ],
            ),
          ),
        ],
      ),
    );

    switch (result) {
      case 'minimize':
        await windowManager.hide();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ PiyangoX arka planda çalışmaya devam ediyor'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        break;
      case 'close':
        await windowManager.destroy();
        exit(0); // Uygulamayı tamamen sonlandır
      case 'cancel':
      default:
        // Do nothing, keep the window open
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Desktop üst bar
          Container(
            height: 60,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.casino,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PiyangoX Desktop',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Milli Piyango Yönetim Sistemi',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // Desktop bilgisi
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.desktop_windows,
                          color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        Platform.operatingSystem.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
              ],
            ),
          ),

          // Ana içerik
          Expanded(
            child: widget.child,
          ),
        ],
      ),
    );
  }
}
