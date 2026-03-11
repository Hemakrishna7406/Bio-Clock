import 'dart:convert';
import 'package:http/http.dart' as http;

class BioClockApiService {
  static const String _baseUrl = 'https://8f48te8i2m.execute-api.eu-north-1.amazonaws.com/predict';

  static Future<String?> getStorageTips(String foodType, double rulHours) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'food_type': foodType,
          'rul_hours': rulHours,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return data['tips'] as String?;
      } else {
        return 'Failed to get tips from AI. Server responded with status code: ${response.statusCode}';
      }
    } catch (e) {
      return 'Network error occurred while fetching AI tips: $e';
    }
  }
}
