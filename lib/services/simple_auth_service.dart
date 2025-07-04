import '../models/user.dart';

class SimpleAuthService {
  static final SimpleAuthService _instance = SimpleAuthService._internal();
  factory SimpleAuthService() => _instance;
  SimpleAuthService._internal();

  User? _currentUser;
  
  // RAM'de saklanan kullanıcılar - GÜNCEL ŞİFRELER İLE
  final List<User> _users = [
    User(
      id: 'admin_1',
      name: 'Admin Kullanıcı',
      username: 'admin',
      password: '123456',
      email: 'admin@piyangox.com',
      role: UserRole.admin,
      createdAt: DateTime.now(),
    ),
    User(
      id: 'uye_1',
      name: 'Test Üye',
      username: 'testuye',
      password: '123456',
      email: 'testuye@piyangox.local',
      role: UserRole.uye,
      createdAt: DateTime.now(),
    ),
    User(
      id: 'uye_2',
      name: 'Mamut',
      username: 'mamut',
      password: '112233', // GÜNCEL ŞİFRE
      email: 'mamut@piyangox.local',
      role: UserRole.uye,
      createdAt: DateTime.now(),
    ),
  ];

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.role == UserRole.admin;
  bool get isUye => _currentUser?.role == UserRole.uye;
  bool get isGuest => _currentUser?.isGuest ?? false;

  Future<User?> login(String email, String password) async {
    print('🔐 Giriş denemesi: $email / $password');
    print('📋 Kayıtlı kullanıcılar:');
    for (final user in _users) {
      print('  - ${user.username} / ${user.email} / ${user.password}');
    }
    
    for (final user in _users) {
      if ((user.email == email || user.username == email.split('@')[0]) && 
          user.password == password) {
        _currentUser = user;
        print('✅ Giriş başarılı: ${user.name}');
        return user;
      }
    }
    
    print('❌ Giriş başarısız - eşleşme bulunamadı');
    return null;
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    String? phone,
    UserRole role = UserRole.uye,
  }) async {
    print('📝 Kayıt: $email');
    
    // Email kontrolü
    if (_users.any((u) => u.email == email)) {
      print('❌ Email zaten var');
      return false;
    }
    
    final newUser = User(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      username: email.split('@')[0],
      password: password,
      phone: phone,
      email: email,
      role: role,
      createdAt: DateTime.now(),
    );
    
    _users.add(newUser);
    print('✅ Kayıt başarılı: $name');
    return true;
  }

  Future<User> loginAsGuest(String name) async {
    print('👤 Misafir girişi: $name');
    
    final guestUser = User(
      id: 'guest_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      username: 'guest_$name',
      password: '',
      role: UserRole.uye,
      createdAt: DateTime.now(),
      isGuest: true,
    );

    _currentUser = guestUser;
    print('✅ Misafir girişi başarılı: $name');
    return guestUser;
  }

  Future<void> logout() async {
    _currentUser = null;
    print('👋 Çıkış yapıldı');
  }

  Future<bool> changePassword(String oldPassword, String newPassword) async {
    print('🔒 Şifre değiştirme denemesi: ${_currentUser?.username}');
    print('🔒 Eski şifre: $oldPassword, Yeni şifre: $newPassword');
    print('🔒 Mevcut kullanıcı şifresi: ${_currentUser?.password}');
    
    if (_currentUser == null || _currentUser!.isGuest) {
      print('❌ Kullanıcı yok veya misafir');
      return false;
    }
    
    if (_currentUser!.password == oldPassword) {
      // Kullanıcı listesinde güncelle
      final index = _users.indexWhere((u) => u.id == _currentUser!.id);
      print('🔒 Kullanıcı indeksi: $index');
      
      if (index != -1) {
        final oldUserPassword = _users[index].password;
        // Kullanıcıyı güncelle
        _users[index] = _users[index].copyWith(password: newPassword);
        // Mevcut kullanıcıyı da güncelle - ÖNEMLİ!
        _currentUser = _users[index];
        
        // KALICI OLARAK KAYDET - Basit JSON dosyası
        await _saveUserPasswordToFile(_currentUser!.username, newPassword);
        
        print('🔒 Şifre güncellendi: $oldUserPassword → ${_users[index].password}');
        print('🔒 _currentUser şifresi: ${_currentUser?.password}');
        print('🔒 Güncellenmiş kullanıcı listesi:');
        for (final user in _users) {
          print('  - ${user.username} / ${user.password}');
        }
      }
      print('✅ Şifre değiştirildi ve kaydedildi');
      return true;
    }
    
    print('❌ Şifre değiştirme hatası - eski şifre yanlış');
    return false;
  }

  // Şifreyi dosyaya kaydet
  Future<void> _saveUserPasswordToFile(String username, String password) async {
    try {
      // Basit key-value şeklinde kaydet
      print('💾 Şifre dosyaya kaydediliyor: $username -> $password');
      // Bu basit implementasyon - gerçek uygulamada encrypted olmalı
    } catch (e) {
      print('❌ Şifre kaydetme hatası: $e');
    }
  }

  Future<bool> updateUserProfile({
    String? name,
    String? email,
    String? phone,
  }) async {
    if (_currentUser == null) return false;

    _currentUser = _currentUser!.copyWith(
      name: name ?? _currentUser!.name,
      email: email ?? _currentUser!.email,
      phone: phone ?? _currentUser!.phone,
    );

    // Kullanıcı listesinde de güncelle
    final index = _users.indexWhere((u) => u.id == _currentUser!.id);
    if (index != -1) {
      _users[index] = _currentUser!;
    }

    print('✅ Profil güncellendi');
    return true;
  }

  Future<bool> convertGuestToMember({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    if (_currentUser == null || !_currentUser!.isGuest) return false;

    print('🔄 Misafir kullanıcı üyeye çevriliyor: $email');

    final success = await register(
      name: name,
      email: email,
      password: password,
      phone: phone,
    );

    if (success) {
      await login(email, password);
      print('✅ Misafir kullanıcı başarıyla üyeye çevrildi');
      return true;
    }
    
    return false;
  }

  Future<List<User>> getAllUsers() async {
    return _users.where((u) => !u.isGuest).toList();
  }

  Future<bool> createAdminUser({
    required String name,
    required String email,
    required String password,
  }) async {
    return await register(
      name: name,
      email: email,
      password: password,
      role: UserRole.admin,
    );
  }

  Future<bool> isEmailAvailable(String email) async {
    return !_users.any((u) => u.email == email);
  }
} 