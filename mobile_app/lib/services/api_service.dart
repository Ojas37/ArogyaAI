import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/symptom_report.dart';
import '../models/triage_result.dart';

class ApiService {
  // Backend API URL - using local IP for physical device testing
  // Change back to 127.0.0.1 for emulator/browser testing
  // Find IP: ipconfig (Windows) or ifconfig (Mac/Linux)
  static const String baseUrl = 'http://192.168.42.242:8000/api/v1';
  
  Future<TriageResult> analyzeSymptoms(SymptomReport report) async {
    try {
      print('📤 Sending request to: $baseUrl/symptom/analyze');
      print('📦 Request body: userId=${report.userId}, text=${report.textInput}');
      
      final response = await http.post(
        Uri.parse('$baseUrl/symptom/analyze'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': report.userId,
          'language': report.language,
          'textInput': report.textInput,
          'symptoms': report.symptoms,
          'vitals': report.vitals,
          'timestamp': report.timestamp.toIso8601String(),
        }),
      ).timeout(const Duration(seconds: 45));  // Extended timeout for model loading

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Parsed data: urgencyLevel="${data['urgencyLevel']}"');
        print('✅ Parsed data: recommendation="${data['recommendation']}"');
        print('✅ Full response: $data');
        return TriageResult.fromJson(data);
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
        print('❌ Response body: ${response.body}');
        throw Exception('Failed to analyze symptoms: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ API Service error: $e');
      throw Exception('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> analyzeVitals(Map<String, double> vitals) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/vitals/analyze'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(vitals),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to analyze vitals');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> detectLanguage(String text) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/language/detect'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': text}),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to detect language: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> classifyIntent(String text, {int topK = 3}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/intent/classify'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'text': text,
          'top_k': topK,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to classify intent: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}
