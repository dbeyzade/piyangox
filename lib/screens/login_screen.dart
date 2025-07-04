import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import 'admin_dashboard.dart';
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

          // Kullanıcı adı
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
                return 'Kullanıcı adı gerekli';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Şifre
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

          // Giriş butonu
          ElevatedButton(
            onPressed: _isLoading ? null : _login,
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
        ],
      ),
    );
  }

  Widget _buildRegisterForm() {
    return Column(
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

        // Ad Soyad
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

        // Kullanıcı adı
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

        // Şifre
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: 'Şifre',
            prefixIcon:
                const Icon(Icons.lock_outline, color: Color(0xFF6A1B9A)),
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
            helperText: 'En az 6 karakter olmalı',
          ),
        ),

        const SizedBox(height: 16),

        // Şifre Tekrarı
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: 'Şifre Tekrarı',
            prefixIcon: const Icon(Icons.lock, color: Color(0xFF6A1B9A)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            helperText: 'Şifrenizi tekrar girin',
          ),
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

        // Kayıt butonu
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
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildModeButton('Giriş', 'login', Icons.login),
            _buildModeButton('Yeni Üye', 'register', Icons.person_add),
            _buildModeButton('Üyeliksiz', 'guest', Icons.person_outline),
          ],
        ),
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
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: _usernameController.text.trim(),
        password: _passwordController.text,
      );
      final user = response.user;
      if (user != null) {
        // Admin mi kontrolü için email'e bakıyoruz
        if (user.email == 'admin@piyangox.com') {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => AdminDashboard()),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const MemberDashboard()),
          );
        }
      } else {
        _showErrorMessage(
            '❌ Giriş başarısız! Kullanıcı adı veya şifre hatalı.');
      }
    } on AuthException catch (e) {
      _showErrorMessage('❌ Giriş başarısız! ${e.message}');
    } catch (e) {
      _showErrorMessage('❌ Bir hata oluştu: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _register() async {
    // Zorunlu alanları kontrol et
    if (_nameController.text.isEmpty ||
        _usernameController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      _showErrorMessage('❌ Lütfen gerekli alanları doldurun');
      return;
    }

    // Şifre uzunluğunu kontrol et
    if (_passwordController.text.length < 6) {
      _showErrorMessage('❌ Şifre en az 6 karakter olmalı');
      return;
    }

    // Şifre tekrarını kontrol et
    if (_passwordController.text != _confirmPasswordController.text) {
      _showErrorMessage('❌ Şifreler eşleşmiyor');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _authService.register(
        name: _nameController.text.trim(),
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
      );

      if (success) {
        _showSuccessMessage(
            '✅ Üyelik oluşturuldu! Şimdi giriş yapabilirsiniz.');
        setState(() {
          _currentMode = 'login';
          _usernameController.text = _usernameController.text;
          _passwordController.text = _passwordController.text;
          _clearOtherForms();
        });
      } else {
        _showErrorMessage('❌ Bu kullanıcı adı zaten kullanılıyor!');
      }
    } catch (e) {
      _showErrorMessage('❌ Kayıt sırasında hata oluştu: $e');
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
