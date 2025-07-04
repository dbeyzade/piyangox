import '../models/user.dart';
import 'simple_auth_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final SimpleAuthService _authService = SimpleAuthService();

  User? get currentUser => _authService.currentUser;
  bool get isLoggedIn => _authService.isLoggedIn;
  bool get isAdmin => _authService.isAdmin;
  bool get isUye => _authService.isUye;
  bool get isGuest => _authService.isGuest;

  // Kullanıcı adı ile giriş (Email/Username destekli)
  Future<User?> login(String username, String password) async {
    try {
      print('🔑 AuthService login: $username → email çeviriliyor...');
      // Username'i email formatına çevir
      String email = username;
      if (!username.contains('@')) {
        // Admin özel durumu
        if (username.toLowerCase() == 'admin') {
          email = 'admin@piyangox.com';
        } else {
          // Diğer kullanıcılar için email formatı oluştur
          email = '$username@piyangox.local';
        }
      }
      print('📧 Çevrilmiş email: $email');

      final result = await _authService.login(email, password);
      print('🎯 Login sonucu: ${result != null ? "Başarılı" : "Başarısız"}');
      return result;
    } catch (e) {
      print('❌ Giriş hatası: $e');
      return null;
    }
  }

  // Üyeliksiz giriş
  Future<User> loginAsGuest(String name) async {
    return await _authService.loginAsGuest(name);
  }

  Future<void> logout() async {
    await _authService.logout();
  }

  // Yeni üye kaydı
  Future<bool> register({
    required String name,
    required String username,
    required String password,
    String? phone,
    String? email,
  }) async {
    try {
      // Email yoksa username'den oluştur
      String userEmail = email ?? '$username@piyangox.local';
      
      // Email müsaitlik kontrolü
      final isAvailable = await _authService.isEmailAvailable(userEmail);
      if (!isAvailable) {
        return false; // Email/username zaten var
      }

      return await _authService.register(
        name: name,
        email: userEmail,
        password: password,
        phone: phone,
      );
    } catch (e) {
      print('❌ Kayıt hatası: $e');
      return false;
    }
  }

  Future<bool> updateProfile({
    required String name,
    String? phone,
    String? email,
    String? profileImage,
  }) async {
    return await _authService.updateUserProfile(
      name: name,
      phone: phone,
      email: email,
    );
  }

  Future<bool> changePassword(String oldPassword, String newPassword) async {
    return await _authService.changePassword(oldPassword, newPassword);
  }

  Future<List<User>> getAllUsers() async {
    return await _authService.getAllUsers();
  }

  Future<List<User>> getUyeUsers() async {
    final allUsers = await _authService.getAllUsers();
    return allUsers.where((u) => u.role == UserRole.uye && !u.isGuest).toList();
  }

  // Kullanıcı adı varlık kontrolü
  Future<bool> isUsernameAvailable(String username) async {
    String email = username.contains('@') ? username : '$username@piyangox.local';
    return await _authService.isEmailAvailable(email);
  }

  // Profil resmi güncelle
  Future<bool> updateUserProfileImage(String? imagePath) async {
    // Basit implementasyon
    return await _authService.updateUserProfile();
  }

  // Misafir kullanıcıyı kayıtlı üyeye çevir
  Future<bool> convertGuestToMember({
    required String name,
    required String username,
    required String password,
    String? email,
    String? phone,
  }) async {
    String userEmail = email ?? '$username@piyangox.local';
    
    return await _authService.convertGuestToMember(
      name: name,
      email: userEmail,
      password: password,
      phone: phone,
    );
  }

  // Kullanıcı profili güncelle
  Future<bool> updateUserProfile({
    String? name,
    String? email,
    String? phone,
  }) async {
    return await _authService.updateUserProfile(
      name: name,
      email: email,
      phone: phone,
    );
  }
}
