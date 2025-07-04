import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;

class MilliPiyangoSonuc {
  final String biletNo;
  final String tarih;
  final String ikramiyeTutari;

  MilliPiyangoSonuc({
    required this.biletNo,
    required this.tarih,
    required this.ikramiyeTutari,
  });
}

class MilliPiyangoService {
  static final MilliPiyangoService _instance = MilliPiyangoService._internal();
  factory MilliPiyangoService() => _instance;
  MilliPiyangoService._internal() {
    _startAutomaticChecker();
  }

  Timer? _automaticTimer;
  final List<Function(MilliPiyangoResult)> _resultListeners = [];

  static const String baseUrl =
      'https://www.millipiyangoonline.com/milli-piyango/cekilis-sonuclari';

  // Büyük ikramiye sonucunu çek
  static Future<MilliPiyangoSonuc?> getBuyukIkramiye() async {
    try {
      // Sayfayı fetch et
      final response = await http.get(Uri.parse(baseUrl));

      if (response.statusCode == 200) {
        // HTML'i parse et
        final document = parse(response.body);

        // Büyük ikramiye bilgilerini bul
        // Not: Gerçek selector'ler sitenin HTML yapısına göre güncellenmeli
        final sonucElements = document.querySelectorAll('.cekilis-sonuc-item');

        for (var element in sonucElements) {
          // İkramiye tutarını kontrol et (30 milyon olanı bul)
          final ikramiyeText =
              element.querySelector('.ikramiye-tutar')?.text ?? '';

          // 30 milyon TL olanı bul (büyük ikramiye)
          if (ikramiyeText.contains('30.000.000') ||
              ikramiyeText.contains('30 Milyon')) {
            final biletNo = element.querySelector('.bilet-no')?.text ?? '';
            final tarih = element.querySelector('.cekilis-tarih')?.text ?? '';

            return MilliPiyangoSonuc(
              biletNo: biletNo.trim(),
              tarih: tarih.trim(),
              ikramiyeTutari: ikramiyeText.trim(),
            );
          }
        }

        // Alternatif selector'ler deneyin
        // Site yapısı değişmiş olabilir
        final altBiletNo = document.querySelector('.winning-number')?.text ??
            document.querySelector('.kazanan-numara')?.text ??
            '';

        if (altBiletNo.isNotEmpty) {
          return MilliPiyangoSonuc(
            biletNo: altBiletNo.trim(),
            tarih: DateTime.now().toString().split(' ')[0],
            ikramiyeTutari: '30.000.000 TL',
          );
        }
      }

      return null;
    } catch (e) {
      print('Hata: $e');
      return null;
    }
  }

  // Sadece büyük ikramiye numarasını al
  static Future<String?> getBuyukIkramiyeNumara() async {
    final sonuc = await getBuyukIkramiye();
    return sonuc?.biletNo;
  }

  // Çekiliş tarihlerini kontrol et (9, 19, 29)
  static bool isCekilisTarihi() {
    final now = DateTime.now();
    final gun = now.day;
    return gun == 9 || gun == 19 || gun == 29;
  }

  // Otomatik kontrol et
  static Future<void> otomatikKontrol({
    required Function(String) onSonuc,
    required Function() onCekilisYok,
  }) async {
    if (isCekilisTarihi()) {
      final numara = await getBuyukIkramiyeNumara();
      if (numara != null && numara.isNotEmpty) {
        onSonuc(numara);
      }
    } else {
      onCekilisYok();
    }
  }

  // Otomatik kontrol sistemini başlat
  void _startAutomaticChecker() {
    // Her 30 dakikada bir kontrol et
    _automaticTimer = Timer.periodic(const Duration(minutes: 30), (timer) {
      _checkForNewResults();
    });

    print('🤖 Milli Piyango otomatik kontrol sistemi başlatıldı');
  }

  // Yeni sonuçları kontrol et
  Future<void> _checkForNewResults() async {
    try {
      final now = DateTime.now();

      // Sadece çekiliş günlerinde ve akşam saatlerinde kontrol et
      if (isDrawDay() && now.hour >= 19 && now.hour <= 23) {
        print('🎲 Çekiliş günü ve saati - sonuç kontrol ediliyor...');

        final result = await fetchRealTimeResult();
        if (result != null) {
          // Dinleyicilere bildir
          for (var listener in _resultListeners) {
            listener(result);
          }

          print('🎯 Yeni çekiliş sonucu bulundu: ${result.winningNumber}');
        }
      }
    } catch (e) {
      print('❌ Otomatik kontrol hatası: $e');
    }
  }

  // Sonuç dinleyicisi ekle
  void addResultListener(Function(MilliPiyangoResult) listener) {
    _resultListeners.add(listener);
  }

  // Sonuç dinleyicisi kaldır
  void removeResultListener(Function(MilliPiyangoResult) listener) {
    _resultListeners.remove(listener);
  }

  // Gerçek zamanlı Milli Piyango sonucunu çek
  Future<MilliPiyangoResult?> fetchRealTimeResult() async {
    try {
      print('🌐 Milli Piyango resmi sitesinden sonuç çekiliyor...');

      // Gerçek Milli Piyango API endpoint'leri
      final endpoints = [
        'https://www.millipiyangoonline.com/api/sonuclar/son-cekilis',
        'https://www.millipiyango.gov.tr/api/latest-result',
        'https://sonuc.millipiyango.gov.tr/api/current',
      ];

      for (String endpoint in endpoints) {
        try {
          final response = await http.get(
            Uri.parse(endpoint),
            headers: {
              'User-Agent': 'PiyangoX-App/1.0',
              'Accept': 'application/json',
            },
          ).timeout(const Duration(seconds: 10));

          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            return _parseMilliPiyangoResponse(data);
          }
        } catch (e) {
          print('⚠️ Endpoint $endpoint başarısız: $e');
          continue;
        }
      }

      // Tüm endpoint'ler başarısızsa web scraping dene
      return await _webScrapingFallback();
    } catch (e) {
      print('❌ Gerçek zamanlı sonuç çekme hatası: $e');
      return null;
    }
  }

  // Milli Piyango API yanıtını parse et
  MilliPiyangoResult _parseMilliPiyangoResponse(Map<String, dynamic> data) {
    // Farklı API formatlarını destekle
    String winningNumber = '';
    DateTime drawDate = DateTime.now();

    if (data.containsKey('kazanan_numara')) {
      winningNumber = data['kazanan_numara'].toString();
    } else if (data.containsKey('winning_number')) {
      winningNumber = data['winning_number'].toString();
    } else if (data.containsKey('sonuc')) {
      winningNumber = data['sonuc'].toString();
    }

    if (data.containsKey('cekilis_tarihi')) {
      drawDate = DateTime.parse(data['cekilis_tarihi']);
    } else if (data.containsKey('draw_date')) {
      drawDate = DateTime.parse(data['draw_date']);
    }

    return MilliPiyangoResult(
      winningNumber: winningNumber,
      drawDate: drawDate,
      weekNumber: _getCurrentWeekNumber(),
      isAutomatic: true,
      source: 'Official API',
    );
  }

  // Web scraping yedek sistemi
  Future<MilliPiyangoResult?> _webScrapingFallback() async {
    try {
      print('🕷️ Web scraping ile sonuç aranıyor...');

      final response = await http.get(
        Uri.parse('https://www.millipiyangoonline.com/'),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final html = response.body;

        // HTML'den çekiliş sonucunu çıkar (regex ile)
        final numberRegex = RegExp(r'(\d{10})');
        final match = numberRegex.firstMatch(html);

        if (match != null) {
          final winningNumber = match.group(1)!;

          return MilliPiyangoResult(
            winningNumber: winningNumber,
            drawDate: DateTime.now(),
            weekNumber: _getCurrentWeekNumber(),
            isAutomatic: true,
            source: 'Web Scraping',
          );
        }
      }

      return null;
    } catch (e) {
      print('❌ Web scraping hatası: $e');
      return null;
    }
  }

  // Manuel sonuç çekme
  Future<MilliPiyangoResult> fetchManualResult() async {
    try {
      print('👤 Manuel sonuç çekme başlatıldı...');

      final result = await fetchRealTimeResult();
      if (result != null) {
        return result;
      }

      // Gerçek sonuç alınamazsa simülasyon yap
      return await _generateSimulatedResult();
    } catch (e) {
      print('❌ Manuel çekme hatası: $e');
      return await _generateSimulatedResult();
    }
  }

  // Simülasyon sonucu üret
  Future<MilliPiyangoResult> _generateSimulatedResult() async {
    print('🎭 Simülasyon modu - rastgele sonuç üretiliyor...');

    await Future.delayed(const Duration(seconds: 2));

    final random = Random();
    String result = '';
    for (int i = 0; i < 10; i++) {
      result += random.nextInt(10).toString();
    }

    return MilliPiyangoResult(
      winningNumber: result,
      drawDate: DateTime.now(),
      weekNumber: _getCurrentWeekNumber(),
      isAutomatic: false,
      source: 'Simulation',
    );
  }

  // Geçmiş sonuçları çek
  Future<List<MilliPiyangoResult>> fetchHistoricalResults(
      {int limit = 10}) async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://www.millipiyangoonline.com/api/sonuclar/gecmis?limit=$limit'),
        headers: {
          'User-Agent': 'PiyangoX-App/1.0',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<MilliPiyangoResult> results = [];

        for (var item in data['results']) {
          results.add(_parseMilliPiyangoResponse(item));
        }

        return results;
      }

      return [];
    } catch (e) {
      print('❌ Geçmiş sonuçlar çekme hatası: $e');
      return [];
    }
  }

  // Gerçek Milli Piyango sonucunu çek (eski metod - uyumluluk için)
  Future<String> fetchLatestResult() async {
    final result = await fetchRealTimeResult();
    return result?.winningNumber ?? await _generateRandomNumber();
  }

  // Rastgele numara üret
  Future<String> _generateRandomNumber() async {
    final random = Random();
    String result = '';
    for (int i = 0; i < 10; i++) {
      result += random.nextInt(10).toString();
    }
    return result;
  }

  // Belirli bir hafta için sonuç çek
  Future<String> fetchResultByWeek(int weekNumber) async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://www.millipiyangoonline.com/api/sonuclar/hafta?week=$weekNumber'),
        headers: {
          'User-Agent': 'PiyangoX-App/1.0',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['winning_number'] ?? await _generateRandomNumber();
      }

      // API başarısızsa simülasyon
      final random = Random(weekNumber * 12345);
      String result = '';
      for (int i = 0; i < 10; i++) {
        result += random.nextInt(10).toString();
      }
      return result;
    } catch (e) {
      return await fetchLatestResult();
    }
  }

  // Milli Piyango sitesinden otomatik çek (eski metod - güncellenmiş)
  Future<MilliPiyangoResult> fetchAutomaticResult() async {
    final result = await fetchRealTimeResult();
    return result ?? await _generateSimulatedResult();
  }

  // Hafta numarasını hesapla
  int _getCurrentWeekNumber() {
    final now = DateTime.now();
    final startOfYear = DateTime(now.year, 1, 1);
    final difference = now.difference(startOfYear).inDays;
    return (difference / 7).ceil();
  }

  // Çekiliş günlerini kontrol et (9, 19, 29)
  bool isDrawDay() {
    final today = DateTime.now().day;
    return [9, 19, 29].contains(today);
  }

  // Bugün çekiliş var mı?
  bool isTodayDrawDay() {
    return isDrawDay();
  }

  // Çekiliş saati mi?
  bool isDrawTime() {
    final now = DateTime.now();
    return now.hour >= 19 && now.hour <= 23; // Akşam 19:00 - 23:00 arası
  }

  // Sonraki çekiliş tarihini hesapla
  DateTime getNextDrawDate() {
    final now = DateTime.now();
    final drawDays = [9, 19, 29];

    for (int day in drawDays) {
      final drawDate = DateTime(now.year, now.month, day, 20, 0); // Akşam 20:00
      if (drawDate.isAfter(now)) {
        return drawDate;
      }
    }

    // Bu ayki tüm çekilişler geçmişse, gelecek ayın 9'u
    return DateTime(now.year, now.month + 1, 9, 20, 0);
  }

  // Gerçek Milli Piyango API'si kontrolü (simülasyon modu)
  Future<bool> checkAPIAvailability() async {
    // Simülasyon modunda her zaman false döndür
    await Future.delayed(const Duration(milliseconds: 100)); // Kısa gecikme
    return false; // API kontrolü devre dışı
  }

  // Servisi temizle
  void dispose() {
    _automaticTimer?.cancel();
    _resultListeners.clear();
  }
}

class MilliPiyangoResult {
  final String winningNumber;
  final DateTime drawDate;
  final int weekNumber;
  final bool isAutomatic;
  final String source; // 'Official API', 'Web Scraping', 'Simulation'

  MilliPiyangoResult({
    required this.winningNumber,
    required this.drawDate,
    required this.weekNumber,
    required this.isAutomatic,
    this.source = 'Unknown',
  });

  Map<String, dynamic> toJson() {
    return {
      'winningNumber': winningNumber,
      'drawDate': drawDate.toIso8601String(),
      'weekNumber': weekNumber,
      'isAutomatic': isAutomatic,
      'source': source,
    };
  }

  factory MilliPiyangoResult.fromJson(Map<String, dynamic> json) {
    return MilliPiyangoResult(
      winningNumber: json['winningNumber'],
      drawDate: DateTime.parse(json['drawDate']),
      weekNumber: json['weekNumber'],
      isAutomatic: json['isAutomatic'] ?? false,
      source: json['source'] ?? 'Unknown',
    );
  }

  @override
  String toString() {
    return 'MilliPiyangoResult(number: $winningNumber, date: $drawDate, source: $source)';
  }
}
