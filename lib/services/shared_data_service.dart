import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:piyangox/models/campaign.dart';
import 'package:piyangox/models/ticket.dart';

class SharedDataService {
  static final SharedDataService _instance = SharedDataService._internal();
  factory SharedDataService() => _instance;
  SharedDataService._internal();

  // Paylaşılan veri dosyası
  Future<File> get _sharedDataFile async {
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/piyangox_shared_data.json';
    return File(path);
  }

  // Veriyi kaydet
  Future<void> saveSharedData({
    required bool isListPublished,
    required List<Campaign> campaigns,
    required List<Ticket> tickets,
  }) async {
    try {
      final file = await _sharedDataFile;
      
      final data = {
        'isListPublished': isListPublished,
        'lastUpdated': DateTime.now().toIso8601String(),
        'campaigns': campaigns.map((c) => c.toJson()).toList(),
        'tickets': tickets.map((t) => t.toJson()).toList(),
      };
      
      await file.writeAsString(jsonEncode(data));
      print('✅ Paylaşılan veri kaydedildi');
    } catch (e) {
      print('❌ Veri kaydetme hatası: $e');
    }
  }

  // Veriyi oku
  Future<Map<String, dynamic>> loadSharedData() async {
    try {
      final file = await _sharedDataFile;
      
      if (!await file.exists()) {
        print('⚠️ Paylaşılan veri dosyası bulunamadı');
        return {
          'isListPublished': false,
          'campaigns': [],
          'tickets': [],
        };
      }
      
      final content = await file.readAsString();
      final data = jsonDecode(content);
      
      print('✅ Paylaşılan veri okundu');
      return {
        'isListPublished': data['isListPublished'] ?? false,
        'campaigns': (data['campaigns'] as List?)
            ?.map((json) => Campaign.fromJson(json))
            .toList() ?? [],
        'tickets': (data['tickets'] as List?)
            ?.map((json) => Ticket.fromJson(json))
            .toList() ?? [],
      };
    } catch (e) {
      print('❌ Veri okuma hatası: $e');
      return {
        'isListPublished': false,
        'campaigns': [],
        'tickets': [],
      };
    }
  }

  // Liste yayınlama durumunu güncelle
  Future<void> updatePublishStatus(bool isPublished) async {
    try {
      final currentData = await loadSharedData();
      currentData['isListPublished'] = isPublished;
      
      await saveSharedData(
        isListPublished: isPublished,
        campaigns: currentData['campaigns'] ?? [],
        tickets: currentData['tickets'] ?? [],
      );
      
      print('✅ Yayınlama durumu güncellendi: $isPublished');
    } catch (e) {
      print('❌ Yayınlama durumu güncelleme hatası: $e');
    }
  }

  // Veriyi temizle
  Future<void> clearSharedData() async {
    try {
      final file = await _sharedDataFile;
      if (await file.exists()) {
        await file.delete();
        print('✅ Paylaşılan veri temizlendi');
      }
    } catch (e) {
      print('❌ Veri temizleme hatası: $e');
    }
  }
} 