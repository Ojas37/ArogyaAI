import 'package:flutter/material.dart';
import '../models/symptom_report.dart';
import '../models/triage_result.dart';
import '../services/api_service.dart';
import '../services/offline_triage_service.dart';
import 'connectivity_provider.dart';

class TriageProvider with ChangeNotifier {
  TriageResult? _currentResult;
  SymptomReport? _currentReport;
  bool _isLoading = false;
  String? _error;

  final ApiService _apiService = ApiService();
  final OfflineTriageService _offlineService = OfflineTriageService();

  TriageResult? get currentResult => _currentResult;
  SymptomReport? get currentReport => _currentReport;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> analyzeSymptoms(SymptomReport report, {bool isOnline = true}) async {
    _isLoading = true;
    _error = null;
    _currentReport = report;
    notifyListeners();

    try {
      if (isOnline) {
        // Online: Use backend API
        print('📡 Calling backend API for: ${report.textInput}');
        _currentResult = await _apiService.analyzeSymptoms(report);
        print('✅ API Response received: ${_currentResult?.recommendation}');
      } else {
        // Offline: Use local triage
        print('📴 Using offline triage');
        _currentResult = _offlineService.analyzeOffline(report);
      }
    } catch (e) {
      _error = e.toString();
      print('❌ API ERROR: $e');
      print('🔄 Falling back to offline triage');
      // Fallback to offline if online fails
      _currentResult = _offlineService.analyzeOffline(report);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addVitals(double? spo2, double? temperature, double? heartRate) async {
    if (_currentReport == null) return;

    // Create vitals map
    final vitalsMap = <String, double>{};
    if (spo2 != null) vitalsMap['spo2'] = spo2;
    if (temperature != null) vitalsMap['temperature'] = temperature;
    if (heartRate != null) vitalsMap['heartRate'] = heartRate;

    // Update the report with vitals
    final updatedReport = SymptomReport(
      id: _currentReport!.id,
      userId: _currentReport!.userId,
      language: _currentReport!.language,
      textInput: _currentReport!.textInput,
      timestamp: _currentReport!.timestamp,
      vitals: vitalsMap,
    );

    // Re-analyze with vitals
    await analyzeSymptoms(updatedReport);
  }

  void clearResult() {
    _currentResult = null;
    _currentReport = null;
    _error = null;
    notifyListeners();
  }
}
