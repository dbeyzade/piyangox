import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/complaint.dart';

class ComplaintService {
  static final ComplaintService _instance = ComplaintService._internal();
  factory ComplaintService() => _instance;
  ComplaintService._internal() {
    _loadData(); // Uygulama başlarken verileri yükle
  }

  final List<Complaint> _complaints = [];

  List<Complaint> get allComplaints => List.unmodifiable(_complaints);
  List<Complaint> get newComplaints => 
      _complaints.where((c) => c.status == ComplaintStatus.pending).toList();
  List<Complaint> get readComplaints => 
      _complaints.where((c) => c.status == ComplaintStatus.read).toList();
  List<Complaint> get resolvedComplaints => 
      _complaints.where((c) => c.status == ComplaintStatus.resolved).toList();

  int get newComplaintCount => newComplaints.length;

  // Şikayet/Dilek ekle
  Future<bool> addComplaint({
    required String message,
    required String senderName,
    String? senderPhone,
  }) async {
    try {
      final complaint = Complaint(
        id: 'complaint_${DateTime.now().millisecondsSinceEpoch}',
        message: message,
        senderName: senderName,
        senderPhone: senderPhone,
        createdAt: DateTime.now(),
      );

      _complaints.add(complaint);
      await _saveData(); // Kalıcı olarak kaydet
      return true;
    } catch (e) {
      return false;
    }
  }

  // Şikayeti okundu işaretle
  Future<bool> markAsRead(String complaintId) async {
    try {
      final index = _complaints.indexWhere((c) => c.id == complaintId);
      if (index != -1) {
        _complaints[index] = _complaints[index].copyWith(
          status: ComplaintStatus.read,
          readAt: DateTime.now(),
        );
        await _saveData(); // Kalıcı olarak kaydet
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Şikayeti çözüldü işaretle
  Future<bool> markAsResolved({
    required String complaintId,
    String? adminResponse,
  }) async {
    try {
      final index = _complaints.indexWhere((c) => c.id == complaintId);
      if (index != -1) {
        _complaints[index] = _complaints[index].copyWith(
          status: ComplaintStatus.resolved,
          resolvedAt: DateTime.now(),
          adminResponse: adminResponse,
        );
        await _saveData(); // Kalıcı olarak kaydet
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Şikayet sil
  Future<bool> deleteComplaint(String complaintId) async {
    try {
      _complaints.removeWhere((c) => c.id == complaintId);
      await _saveData(); // Kalıcı olarak kaydet
      return true;
    } catch (e) {
      return false;
    }
  }

  // Şikayet bul
  Complaint? getComplaint(String id) {
    try {
      return _complaints.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  // Şikayet ara
  List<Complaint> searchComplaints(String searchTerm) {
    if (searchTerm.isEmpty) return allComplaints;

    final lowerSearch = searchTerm.toLowerCase();
    return _complaints.where((c) =>
        c.message.toLowerCase().contains(lowerSearch) ||
        c.senderName.toLowerCase().contains(lowerSearch) ||
        (c.senderPhone?.contains(searchTerm) ?? false) ||
        (c.adminResponse?.toLowerCase().contains(lowerSearch) ?? false)
    ).toList();
  }

  // Duruma göre şikayetler
  List<Complaint> getComplaintsByStatus(ComplaintStatus status) {
    return _complaints.where((c) => c.status == status).toList();
  }

  // Tarih aralığına göre şikayetler
  List<Complaint> getComplaintsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) {
    return _complaints.where((c) => 
        c.createdAt.isAfter(startDate.subtract(const Duration(days: 1))) &&
        c.createdAt.isBefore(endDate.add(const Duration(days: 1)))
    ).toList();
  }

  // Son şikayetler
  List<Complaint> getRecentComplaints([int limit = 10]) {
    final sortedComplaints = List<Complaint>.from(_complaints)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    return sortedComplaints.take(limit).toList();
  }

  // İstatistikler
  Map<String, dynamic> getStats() {
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month, 1);
    final thisWeek = now.subtract(const Duration(days: 7));

    return {
      'total': _complaints.length,
      'pending': newComplaints.length,
      'read': readComplaints.length,
      'resolved': resolvedComplaints.length,
      'thisMonth': _complaints.where((c) => c.createdAt.isAfter(thisMonth)).length,
      'thisWeek': _complaints.where((c) => c.createdAt.isAfter(thisWeek)).length,
    };
  }

  // Tüm yeni şikayetleri okundu işaretle
  Future<void> markAllAsRead() async {
    for (int i = 0; i < _complaints.length; i++) {
      if (_complaints[i].status == ComplaintStatus.pending) {
        _complaints[i] = _complaints[i].copyWith(
          status: ComplaintStatus.read,
          readAt: DateTime.now(),
        );
      }
    }
    await _saveData(); // Kalıcı olarak kaydet
  }

  // 💾 ŞİKAYETLERİ KALICI OLARAK SAKLA
  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final complaintsJson = _complaints.map((c) => c.toJson()).toList();
      await prefs.setString('complaints', jsonEncode(complaintsJson));
      print('💾 ŞİKAYETLER KAYDEDİLDİ: ${_complaints.length} şikayet');
    } catch (e) {
      print('❌ Şikayet kaydetme hatası: $e');
    }
  }

  // 📂 ŞİKAYETLERİ GERİ YÜKLE
  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final complaintsStr = prefs.getString('complaints');
      if (complaintsStr != null) {
        final complaintsJson = jsonDecode(complaintsStr) as List;
        _complaints.clear();
        _complaints.addAll(complaintsJson.map((json) => Complaint.fromJson(json)));
      }
      print('📂 ŞİKAYETLER YÜKLENDİ: ${_complaints.length} şikayet');
    } catch (e) {
      print('❌ Şikayet yükleme hatası: $e');
    }
  }

  // Demo veriler ekle
  Future<void> addSampleComplaints() async {
    final samples = [
      {
        'message': 'Çekiliş sonuçları çok geç açıklanıyor. Daha hızlı olmalı.',
        'senderName': 'Ayşe Yılmaz',
        'senderPhone': '05551234567',
      },
      {
        'message': 'Bilet fiyatları çok yüksek. İndirim yapılabilir mi?',
        'senderName': 'Mehmet Kaya',
        'senderPhone': '05559876543',
      },
      {
        'message': 'Uygulama çok güzel, tebrikler! Daha fazla kampanya olursa sevinirim.',
        'senderName': 'Fatma Demir',
        'senderPhone': null,
      },
    ];

    for (final sample in samples) {
      await addComplaint(
        message: sample['message'] as String,
        senderName: sample['senderName'] as String,
        senderPhone: sample['senderPhone'],
      );
    }
  }
}
