import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:window_manager/window_manager.dart';

// Auth sayfaları
import 'screens/login_screen.dart';
import 'screens/auth/register_page.dart';
import 'screens/auth/forgot_password_page.dart';

// Dashboard sayfaları
import 'screens/dashboard/admin_dashboard.dart';
import 'screens/dashboard/user_dashboard.dart';
import 'screens/dashboard/admin_dashboard_tab.dart';
import 'screens/dashboard/draw_result_page.dart';
import 'screens/bayi_dashboard.dart';
import 'services/supabase_service.dart';
import 'core/theme.dart';

final themeNotifier = ValueNotifier(ThemeMode.light);

// Giriş Noktası
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();
    await windowManager.waitUntilReadyToShow(
      const WindowOptions(
        size: Size(1400, 900),
        minimumSize: Size(1200, 800),
        center: true,
        backgroundColor: Colors.transparent,
        titleBarStyle: TitleBarStyle.normal,
        title: 'PiyangoX - Piyango Yönetim Sistemi (Desktop)',
      ),
      () async {
        await windowManager.show();
        await windowManager.focus();
      },
    );
  }

  await Supabase.initialize(
    url: 'https://itlhxotugmnjgvaxdnay.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml0bGh4b3R1Z21uamd2YXhkbmF5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTE5OTA3NzIsImV4cCI6MjA2NzU2Njc3Mn0.WSzZ6JbAj1_q1_CEpIy31LQWPD81Ww-O3vt5rf-1xRg',
  );

  // Session kontrolü
  final currentSession = Supabase.instance.client.auth.currentSession;
  print(
      '🔄 Uygulama başlangıcında session: ${currentSession != null ? "Var" : "Yok"}');

  // Token yenileme sistemini başlat
  final supabaseService = SupabaseService();
  supabaseService.startTokenRefreshTimer();

  runApp(
    ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, mode, __) => MyApp(themeMode: mode),
    ),
  );
}

class MyApp extends StatelessWidget {
  final ThemeMode themeMode;
  const MyApp({super.key, this.themeMode = ThemeMode.light});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PiyangoX - Piyango Yönetim Sistemi',
      theme: appLightTheme,
      darkTheme: appDarkTheme,
      themeMode: themeMode,
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
      initialRoute: '/login',
      routes: {
        '/login': (context) => LoginScreen(),
        '/user': (context) => UserDashboard(),
        '/admin-tab': (context) => AdminDashboard(),
        '/admin': (context) => AdminDashboard(),
        '/draw': (context) => DrawResultPage(),
      },
      onUnknownRoute: (settings) => MaterialPageRoute(
        builder: (_) => Scaffold(
          body: Center(
              child: Text(
                  'Sayfa bulunamadı')), // NotFoundPage yoksa basit bir ekran
        ),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class EntryPoint extends StatefulWidget {
  const EntryPoint({super.key});

  @override
  State<EntryPoint> createState() => _EntryPointState();
}

class _EntryPointState extends State<EntryPoint> {
  @override
  void initState() {
    super.initState();
    // Auth state değişikliklerini dinle
    Supabase.instance.client.auth.onAuthStateChange.listen((event) {
      print('🔄 Auth state değişti: ${event.event}');
      print('  Session: ${event.session != null ? "Var" : "Yok"}');
      print('  User: ${event.session?.user?.email}');
      print('  Role: ${event.session?.user?.appMetadata['role']}');

      // Login sonrası yönlendirme
      if (event.event == AuthChangeEvent.signedIn && event.session != null) {
        final role = event.session!.user.appMetadata['role'] ?? 'member';
        print('🎯 Login sonrası yönlendirme - Role: $role');

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (role == 'admin') {
            Navigator.of(context).pushReplacementNamed('/admin');
          } else if (role == 'bayi') {
            Navigator.of(context).pushReplacementNamed('/bayi');
          } else {
            Navigator.of(context).pushReplacementNamed('/user');
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;

    print('🔍 EntryPoint - Session kontrolü:');
    print('  Session: ${session != null ? "Var" : "Yok"}');
    print('  User: ${session?.user?.email}');
    print('  AppMetadata: ${session?.user?.appMetadata}');

    if (session == null) {
      print('❌ Session yok - LoginScreen\'e yönlendiriliyor');
      return const LoginScreen(); // 👉 Giriş formu burası
    }

    final role = session.user?.appMetadata['role'] ?? 'member';
    print('🎭 Role: $role');

    if (role == 'admin') {
      print('✅ Admin panosuna yönlendiriliyor');
      return AdminDashboard();
    } else if (role == 'bayi') {
      print('✅ Bayi panosuna yönlendiriliyor');
      return BayiDashboard();
    } else {
      print('✅ Üye panosuna yönlendiriliyor');
      return UserDashboard();
    }
  }
}

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
    windowManager.addListener(this);
    windowManager.setPreventClose(false);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowClose() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kapat?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'close'),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );

    if (result == 'close') {
      await windowManager.destroy();
      exit(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
    );
  }
}
print(undefinedVariable)
