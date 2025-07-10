import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import 'dashboard/admin_dashboard.dart';
import 'dashboard/user_dashboard.dart';
import 'member_dashboard.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _guestNameController = TextEditingController();

  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String _currentMode = 'login'; // 'login', 'register', 'guest'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF6A1B9A), // Mor
              Color(0xFF8E24AA), // Açık mor
              Color(0xFFAB47BC), // Pembe mor
              Color(0xFFBA68C8), // Açık pembe mor
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/yonca.png',
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Başlık
                  Text(
                    'piyangox',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.3),
                          offset: const Offset(2, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Profesyonel Piyango Yönetim Sistemi',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w300,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 48),

                  // Giriş/Kayıt formu
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: _buildCurrentForm(),
                  ),

                  const SizedBox(height: 32),

                  // Geçiş butonları
                  _buildModeButtons(),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentForm() {
    switch (_currentMode) {
      case 'login':
        return _buildLoginForm();
      case 'register':
        return _buildRegisterForm();
      case 'guest':
        return _buildGuestForm();
      default:
        return _buildLoginForm();
    }
  }

  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '🔐 Giriş Yap',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          // Kullanıcı Adı (zorunlu)
          TextFormField(
            controller: _usernameController,
            decoration: InputDecoration(
              labelText: 'Kullanıcı Adı',
              prefixIcon: const Icon(Icons.person, color: Color(0xFF6A1B9A)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Color(0xFF6A1B9A), width: 2),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Kullanıcı Adı gerekli';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          // Şifre (zorunlu)
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Şifre',
              prefixIcon: const Icon(Icons.lock, color: Color(0xFF6A1B9A)),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  color: const Color(0xFF6A1B9A),
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Color(0xFF6A1B9A), width: 2),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Şifre gerekli';
              }
              return null;
            },
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _isLoading ? null : _loginWithUsername,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6A1B9A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 8,
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Giriş Yap',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _loginWithTestUser,
            icon: const Icon(Icons.bug_report, color: Colors.white),
            label: const Text('Test Kullanıcısı ile Giriş',
                style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange,
              foregroundColor: Colors.white,
              elevation: 4,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _currentMode = 'register';
                  });
                },
                child: const Text('Hesap Oluştur'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _currentMode = 'forgot';
                  });
                },
                child: const Text('Şifremi Unuttum'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: Icon(Icons.admin_panel_settings, color: Colors.white),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  onPressed: _isLoading ? null : _loginAsAdmin,
                  label: Text('Admin ile Giriş'),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  icon: Icon(Icons.person, color: Colors.white),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  onPressed: _isLoading ? null : _loginAsUye,
                  label: Text('Üye ile Giriş'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '📝 Yeni Üye Ol',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          // Email (zorunlu)
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'Email *',
              prefixIcon: const Icon(Icons.email, color: Color(0xFF6A1B9A)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (s) {
              if (s == null || !s.contains('@'))
                return 'Geçerli bir email girin';
              return null;
            },
          ),
          const SizedBox(height: 16),
          // Ad Soyad (opsiyonel)
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Ad Soyad',
              prefixIcon:
                  const Icon(Icons.person_outline, color: Color(0xFF6A1B9A)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Kullanıcı Adı (opsiyonel)
          TextFormField(
            controller: _usernameController,
            decoration: InputDecoration(
              labelText: 'Kullanıcı Adı',
              prefixIcon:
                  const Icon(Icons.account_circle, color: Color(0xFF6A1B9A)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Şifre (zorunlu)
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Şifre *',
              prefixIcon:
                  const Icon(Icons.lock_outline, color: Color(0xFF6A1B9A)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (s) {
              if (s == null || s.length < 6) return 'En az 6 karakter olmalı';
              return null;
            },
          ),
          const SizedBox(height: 16),
          // Şifre Tekrar (zorunlu)
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Şifre Tekrar *',
              prefixIcon: const Icon(Icons.lock, color: Color(0xFF6A1B9A)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (s) {
              if (s != _passwordController.text) return 'Şifreler eşleşmiyor';
              return null;
            },
          ),
          const SizedBox(height: 16),
          // Telefon (opsiyonel)
          TextFormField(
            controller: _phoneController,
            decoration: InputDecoration(
              labelText: 'Telefon (opsiyonel)',
              prefixIcon: const Icon(Icons.phone, color: Color(0xFF6A1B9A)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _isLoading ? null : _register,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 8,
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Üye Ol',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '👤 Üyeliksiz Giriş',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 16),

        Text(
          'Sadece adınızı girin ve hemen başlayın!',
          style: TextStyle(
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 32),

        // İsim
        TextFormField(
          controller: _guestNameController,
          decoration: InputDecoration(
            labelText: 'Adınız',
            prefixIcon:
                const Icon(Icons.person_outline, color: Color(0xFF6A1B9A)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF6A1B9A), width: 2),
            ),
          ),
        ),

        const SizedBox(height: 32),

        // Üyeliksiz giriş butonu
        ElevatedButton(
          onPressed: _isLoading ? null : _guestLogin,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 8,
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  'Devam Et',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildModeButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildModeButton('Giriş', 'login', Icons.login),
        _buildModeButton('Yeni Üye', 'register', Icons.person_add),
        _buildModeButton('Üyeliksiz', 'guest', Icons.person_outline),
      ],
    );
  }

  Widget _buildModeButton(String title, String mode, IconData icon) {
    final isSelected = _currentMode == mode;
    return ElevatedButton.icon(
      onPressed: () {
        setState(() {
          _currentMode = mode;
          _clearForms();
        });
      },
      icon: Icon(icon),
      label: Text(title),
      style: ElevatedButton.styleFrom(
        backgroundColor:
            isSelected ? Colors.white : Colors.white.withOpacity(0.3),
        foregroundColor: isSelected ? const Color(0xFF6A1B9A) : Colors.white,
        elevation: isSelected ? 8 : 2,
      ),
    );
  }

  void _clearForms() {
    _usernameController.clear();
    _passwordController.clear();
    _confirmPasswordController.clear();
    _nameController.clear();
    _phoneController.clear();
    _emailController.clear();
    _guestNameController.clear();
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('🔑 Giriş denemesi başlıyor...');
      print('📧 Email: ${_usernameController.text.trim()}');
      print('🔒 Şifre: ${_passwordController.text.trim()}');

      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: _usernameController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (response.session != null) {
        // session kaydını elle yükle
        await Supabase.instance.client.auth
            .setSession(response.session!.accessToken);

        // Ardından yönlendirme
        final role = response.user!.appMetadata['role'];
        if (role == 'admin') {
          Navigator.pushReplacementNamed(context, '/admin-tab');
        } else {
          Navigator.pushReplacementNamed(context, '/user');
        }
        return;
      }

      print('📊 Supabase Response:');
      print('  Session: ${response.session != null ? "✅ Var" : "❌ Yok"}');
      print('  User: ${response.user != null ? "✅ Var" : "❌ Yok"}');
      print('  Response toString: ${response.toString()}');

      if (response.session == null) {
        print("❌ Giriş başarısız");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Giriş başarısız: Session null'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      } else {
        print("✅ Giriş başarılı: ${response.session!.accessToken}");
        print('👤 User ID: ${response.user?.id}');
        print('📧 User Email: ${response.user?.email}');
        print('🎭 User Role: ${response.user?.appMetadata['role']}');
        print('📋 AppMetadata: ${response.user?.appMetadata}');

        final role = response.user!.appMetadata['role'];
        print('🎯 Yönlendirme kararı - Role: $role');

        if (role == 'admin') {
          print('🚀 Admin panosuna yönlendiriliyor...');
          Navigator.pushReplacementNamed(context, '/admin-tab');
        } else {
          print('🚀 Üye panosuna yönlendiriliyor...');
          Navigator.pushReplacementNamed(context, '/user');
        }
      }
    } catch (e) {
      print('🔥 HATA: $e');
      print('🔥 Hata tipi: ${e.runtimeType}');
      print('🔥 Hata stack trace: ${StackTrace.current}');

      // Supabase'den gelen hata mesajını yakala
      String errorMessage = 'Bilinmeyen hata';
      if (e.toString().contains('Invalid login credentials')) {
        errorMessage = 'Geçersiz kullanıcı adı veya şifre';
      } else if (e.toString().contains('Email not confirmed')) {
        errorMessage = 'E-posta doğrulanmamış';
      } else if (e.toString().contains('Too many requests')) {
        errorMessage = 'Çok fazla deneme, lütfen bekleyin';
      } else if (e.toString().contains('User not found')) {
        errorMessage = 'Kullanıcı bulunamadı';
      } else {
        errorMessage = e.toString();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Giriş hatası: $errorMessage'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final supabase = Supabase.instance.client;
      final res = await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        data: {
          'full_name': _nameController.text.trim(),
          'username': _usernameController.text.trim(),
          'phone': _phoneController.text.trim(),
        },
      );
      if (res.user != null) {
        await supabase.from('users').insert({
          'id': res.user!.id,
          'email': _emailController.text.trim(),
          'full_name': _nameController.text.trim(),
          'username': _usernameController.text.trim(),
          'phone': _phoneController.text.trim(),
        });
      }
      _showSuccessMessage('Kayıt başarılı! Lütfen e-postanı onayla.');
      setState(() {
        _currentMode = 'login';
        _clearOtherForms();
      });
    } catch (e) {
      _showErrorMessage('Kayıt sırasında hata oluştu: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _guestLogin() async {
    if (_guestNameController.text.isEmpty) {
      _showErrorMessage('❌ Lütfen adınızı girin');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user =
          await _authService.loginAsGuest(_guestNameController.text.trim());
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => AdminDashboard()),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loginWithTestUser() async {
    if ('test@piyangox.com'.isEmpty || 'test1234'.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Test kullanıcı email ve şifre boş olamaz.')),
      );
      return;
    }
    setState(() {
      _isLoading = true;
    });
    final supabase = Supabase.instance.client;
    try {
      await supabase.auth.signOut();
      final response = await supabase.auth.signInWithPassword(
        email: 'test@piyangox.com',
        password: 'test1234',
      );
      if (response.session != null && response.user != null) {
        final role = response.user!.appMetadata['role'];
        if (role == 'admin') {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (ctx) => AdminDashboard()),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (ctx) => UserDashboard()),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Test kullanıcı ile giriş başarısız!')),
        );
      }
    } catch (error, stack) {
      debugPrint('Test kullanıcı login hata: $error\n$stack');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Giriş hatası: $error')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createTestUserAndLogin() async {
    final supabase = Supabase.instance.client;
    try {
      final signUpResult = await supabase.auth.signUp(
        email: 'test@piyangox.com',
        password: 'test1234',
        data: {'role': 'admin'},
      );
      print('✅ Kullanıcı oluşturuldu: ${signUpResult.user?.email}');
      if (signUpResult.user != null) {
        await supabase.auth.signInWithPassword(
          email: 'test@piyangox.com',
          password: 'test1234',
        );
        print('✅ Oturum açıldı.');
      }
    } catch (e) {
      if (e.toString().contains('User already registered')) {
        print('⚠️ Zaten kayıtlı, giriş yapılıyor...');
        await supabase.auth.signInWithPassword(
          email: 'test@piyangox.com',
          password: 'test1234',
        );
      } else {
        print('❌ Hata: $e');
      }
    }
  }

  Future<void> _loginWithUsername() async {
    if (_usernameController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kullanıcı adı ve şifre zorunlu')),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
    });
    final supabase = Supabase.instance.client;
    await supabase.auth.signOut();
    try {
      // 1) users tablosundan email sorgula
      final userRes = await supabase
          .from('users')
          .select('email')
          .eq('username', _usernameController.text.trim())
          .maybeSingle();
      if (userRes == null || userRes['email'] == null) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Böyle bir kullanıcı bulunamadı')),
        );
        return;
      }
      final email = userRes['email'] as String;
      // 2) şimdi email ile giriş yap
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: _passwordController.text,
      );
      if (response.session != null && response.user != null) {
        await supabase.auth.setSession(response.session!.accessToken);
        final role = response.user!.appMetadata['role'];
        if (role == 'admin') {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (ctx) => AdminDashboard()),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (ctx) => UserDashboard()),
          );
        }
        return;
      }
      if (response.session == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Giriş başarısız: Session null'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    } catch (error, stack) {
      debugPrint('Kullanıcı adı ile login hata: $error\n$stack');
      String errorMessage = 'Bilinmeyen hata';
      if (error.toString().contains('Invalid login credentials')) {
        errorMessage = 'Geçersiz kullanıcı adı veya şifre';
      } else if (error.toString().contains('Email not confirmed')) {
        errorMessage = 'E-posta doğrulanmamış';
      } else if (error.toString().contains('Too many requests')) {
        errorMessage = 'Çok fazla deneme, lütfen bekleyin';
      } else if (error.toString().contains('User not found')) {
        errorMessage = 'Kullanıcı bulunamadı';
      } else {
        errorMessage = error.toString();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Giriş hatası: $errorMessage'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _clearOtherForms() {
    _nameController.clear();
    _confirmPasswordController.clear();
    _phoneController.clear();
    _emailController.clear();
    _guestNameController.clear();
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _loginAsAdmin() async {
    setState(() {
      _isLoading = true;
    });
    final supabase = Supabase.instance.client;
    try {
      await supabase.auth.signOut();
      final response = await supabase.auth.signInWithPassword(
        email: 'admin@piyangox.com',
        password: '123456',
      );
      if (response.session != null && response.user != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (ctx) => AdminDashboard()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Admin ile giriş başarısız!')),
        );
      }
    } catch (e, stack) {
      debugPrint('Admin ile giriş hata: $e\n$stack');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Giriş hatası: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loginAsUye() async {
    setState(() {
      _isLoading = true;
    });
    final supabase = Supabase.instance.client;
    try {
      await supabase.auth.signOut();
      final response = await supabase.auth.signInWithPassword(
        email: 'uye@piyangox.com',
        password: '123456',
      );
      if (response.session != null && response.user != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (ctx) => UserDashboard()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Üye ile giriş başarısız!')),
        );
      }
    } catch (e, stack) {
      debugPrint('Üye ile giriş hata: $e\n$stack');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Giriş hatası: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _guestNameController.dispose();
    super.dispose();
  }
}
