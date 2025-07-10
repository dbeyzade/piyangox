import 'dart:convert';
import 'package:http/http.dart' as http;

class DrawService {
  static const _base = 'https://www.nosyapi.com/apiv2/service/lotto/getResult';
  final String apiKey;

  DrawService(this.apiKey);

  Future<Map<String, dynamic>?> fetchLatestDraw() async {
    final today = DateTime.now();
    final date =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final uri = Uri.parse('$_base?type=6&date=$date&apiKey=$apiKey');

    try {
      final resp = await http.get(uri);
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        return data['data']?['winning_number'] != null
            ? data['data'] as Map<String, dynamic>
            : null;
      }
    } catch (e) {
      print('API hatası: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> fetchDrawByDate(String date) async {
    final uri = Uri.parse('$_base?type=6&date=$date&apiKey=$apiKey');

    try {
      final resp = await http.get(uri);
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        return data['data']?['winning_number'] != null
            ? data['data'] as Map<String, dynamic>
            : null;
      }
    } catch (e) {
      print('API hatası: $e');
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> fetchDrawHistory(int days) async {
    final List<Map<String, dynamic>> results = [];
    final today = DateTime.now();

    for (int i = 0; i < days; i++) {
      final date = today.subtract(Duration(days: i));
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      final result = await fetchDrawByDate(dateStr);
      if (result != null) {
        results.add({
          'date': dateStr,
          'data': result,
        });
      }
    }

    return results;
  }
}
