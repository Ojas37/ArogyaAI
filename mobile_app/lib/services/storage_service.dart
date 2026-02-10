import 'package:hive_flutter/hive_flutter.dart';

class StorageService {
  static const String _reportsBox = 'symptom_reports';
  static const String _settingsBox = 'settings';

  static Future<void> init() async {
    await Hive.openBox(_reportsBox);
    await Hive.openBox(_settingsBox);
  }

  // Save symptom report
  static Future<void> saveReport(Map<String, dynamic> report) async {
    final box = Hive.box(_reportsBox);
    await box.add(report);
  }

  // Get all reports
  static List<Map<String, dynamic>> getAllReports() {
    final box = Hive.box(_reportsBox);
    return box.values.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  // Save settings
  static Future<void> saveSetting(String key, dynamic value) async {
    final box = Hive.box(_settingsBox);
    await box.put(key, value);
  }

  // Get setting
  static dynamic getSetting(String key, {dynamic defaultValue}) {
    final box = Hive.box(_settingsBox);
    return box.get(key, defaultValue: defaultValue);
  }

  // Clear all data
  static Future<void> clearAll() async {
    await Hive.box(_reportsBox).clear();
  }
}
